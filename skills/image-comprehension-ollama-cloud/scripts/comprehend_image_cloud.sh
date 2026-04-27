#!/usr/bin/env bash
# ============================================================================
# Image Comprehension — Ollama Cloud
# Analyzes an image using an Ollama Cloud vision model and outputs the
# description to stdout. No local Ollama installation is required.
# ============================================================================

set -euo pipefail

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly API_URL="https://ollama.com/api/generate"
readonly DEFAULT_MODEL="gemma4:31b-cloud"
readonly DEFAULT_PROMPT="Describe this image in detail"
readonly SUPPORTED_EXTENSIONS="png jpg jpeg gif webp bmp"
readonly TIMEOUT_SECONDS="${COMPREHEND_IMAGE_CLOUD_TIMEOUT_SECONDS:-180}"

IMAGE_PATH=""
PROMPT="${DEFAULT_PROMPT}"
MODEL="${DEFAULT_MODEL}"
TEST_MODE=false

usage() {
    cat >&2 <<EOF
Usage: ${SCRIPT_NAME} --image <path> [options]
       ${SCRIPT_NAME} --test

Analyze an image with an Ollama Cloud vision model and output the description
to stdout. Uses Ollama's cloud API — no local Ollama installation needed.

Options:
  --image <path>     Path to the image file to analyze (required, unless --test)
  --prompt <text>    Custom prompt/question for the image (default: '${DEFAULT_PROMPT}')
  --model <name>     Ollama Cloud model to use (default: '${DEFAULT_MODEL}',
                     override with OLLAMA_CLOUD_MODEL env var)
  --test             Run a smoke test (makes a real API call, consumes quota)
  --help             Show this help

Environment:
  OLLAMA_CLOUD_API_KEY   Required. Your Ollama Cloud API key.
                         Get a key at https://ollama.com/settings/keys
  OLLAMA_CLOUD_MODEL     Default vision model (overrides built-in default).
  COMPREHEND_IMAGE_CLOUD_TIMEOUT_SECONDS
                         Request timeout in seconds (default: 180).

Output:
  The image description is printed to stdout. Progress logs and errors go to stderr.
EOF
}

log() {
    echo "[${SCRIPT_NAME}] $*" >&2
}

fail() {
    echo "[${SCRIPT_NAME}] ERROR: $*" >&2
    exit 1
}

validate_deps() {
    local missing=false

    if ! command -v curl >/dev/null 2>&1; then
        log "Missing dependency: curl"
        missing=true
    fi

    if ! command -v base64 >/dev/null 2>&1; then
        log "Missing dependency: base64"
        missing=true
    fi

    if [ "${missing}" = true ]; then
        log "Install missing dependencies and try again."
        exit 2
    fi
}

validate_api_key() {
    if [ -z "${OLLAMA_CLOUD_API_KEY:-}" ]; then
        fail "OLLAMA_CLOUD_API_KEY environment variable is not set.\n\
       Get a key at https://ollama.com/settings/keys\n\
       Add to your shell profile: export OLLAMA_CLOUD_API_KEY=<your-api-key>"
    fi
}

# macOS base64 requires -b 0 to avoid line wrapping; GNU base64 wraps by default
# but doesn't support -b. Detect and use the correct incantation.
encode_base64() {
    local input_file="$1"
    if echo "test" | base64 -b 0 >/dev/null 2>&1; then
        base64 -b 0 < "${input_file}"
    else
        base64 -w 0 < "${input_file}"
    fi
}

normalize_image_path() {
    local raw_path="$1"

    # Tilde expansion
    raw_path="${raw_path/#\~/$HOME}"

    # macOS Unicode normalization: narrow no-break space (U+202F) -> regular space
    # This handles macOS screenshot filenames like "Screenshot 2024-01-15 at 10.30.00.png"
    if command -v python3 >/dev/null 2>&1; then
        raw_path="$(python3 -c "
import unicodedata, os, sys
p = unicodedata.normalize('NFC', os.path.expanduser(sys.argv[1]))
parent = os.path.dirname(p)
name = os.path.basename(p)
candidate = os.path.join(parent, name) if parent else name
if os.path.isfile(candidate):
    print(candidate)
else:
    norm = unicodedata.normalize('NFKC', name)
    alt = os.path.join(parent, norm) if parent else norm
    if os.path.isfile(alt):
        print(alt)
    else:
        # Fuzzy: match against actual directory entries
        if os.path.isdir(parent):
            norm_cf = unicodedata.normalize('NFKC', name).casefold()
            for entry in os.listdir(parent):
                if unicodedata.normalize('NFKC', entry).casefold() == norm_cf:
                    print(os.path.join(parent, entry))
                    break
            else:
                print(candidate)
        else:
            print(candidate)
" "$raw_path" 2>/dev/null || echo "$raw_path")"
    fi

    echo "${raw_path}"
}

validate_image_path() {
    local path="$1"
    local basename="${path##*/}"
    local ext="${basename##*.}"
    ext="$(echo "${ext}" | tr '[:upper:]' '[:lower:]')"

    if [ ! -f "${path}" ]; then
        local parent="$(dirname "${path}")"
        local extra=""
        if [ -d "${parent}" ]; then
            local matches="$(ls -1 "${parent}"/"${basename%%.*}"* 2>/dev/null | head -5)"
            if [ -n "${matches}" ]; then
                extra=" Similar files in ${parent}: $(echo "${matches}" | tr '\n' ', ')"
            fi
        fi
        fail "Image file not found: ${path}.${extra}"
    fi

    local found=false
    for supported in ${SUPPORTED_EXTENSIONS}; do
        if [ "${ext}" = "${supported}" ]; then
            found=true
            break
        fi
    done

    if [ "${found}" = false ]; then
        fail "Unsupported image format: .${ext}. Supported: ${SUPPORTED_EXTENSIONS}"
    fi
}

create_test_image() {
    local temp_dir="$(mktemp -d comprehend-image-cloud-test-XXXXXX)"
    local test_image="${temp_dir}/test_image.png"
    # Minimal valid 1x1 PNG (2x2 red square)
    echo "iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAIAAAACUFjqAAAAEklEQVR42mP4n2KEBzGMSmNDACBmnjUIeg0MAAAAAElFTkSuQmCC" \
        | base64 --decode > "${test_image}" 2>/dev/null || \
        echo "iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAIAAAACUFjqAAAAEklEQVR42mP4n2KEBzGMSmNDACBmnjUIeg0MAAAAAElFTkSuQmCC" \
        | base64 -d > "${test_image}" 2>/dev/null
    echo "${test_image}"
}

do_comprehend() {
    local image_path="$1"
    local prompt="$2"
    local model="$3"

    log "Analyzing image: ${image_path}"
    log "Prompt: ${prompt}"
    log "Model: ${model}"

    local image_base64
    image_base64="$(encode_base64 "${image_path}")" || fail "Failed to base64-encode image: ${image_path}"

    log "Image encoded ($(echo "${image_base64}" | wc -c | tr -d ' ') chars). Sending to Ollama Cloud API..."

    local response
    local http_code

    response="$(curl -s -w '\n%{http_code}' \
        --max-time "${TIMEOUT_SECONDS}" \
        -X POST \
        -H "Authorization: Bearer ${OLLAMA_CLOUD_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$(jq -n \
            --arg model "${model}" \
            --arg prompt "${prompt}" \
            --arg image "${image_base64}" \
            '{model: $model, prompt: $prompt, images: [$image], stream: false}')" \
        "${API_URL}")"

    http_code="$(printf '%s' "${response}" | tail -1)"
    local body
    body="$(printf '%s' "${response}" | sed '$d')"

    if [ "${http_code}" -ne 200 ]; then
        log "ERROR: API returned HTTP ${http_code}"
        if [ -n "${body}" ]; then
            local error_message
            error_message="$(printf '%s' "${body}" | jq -r '.error // .message // "Unknown error"' 2>/dev/null || echo "${body}" | head -c 500)"
            log "Response: ${error_message}"

            case "${http_code}" in
                401) log "Your API key may be invalid or expired. Get a key at https://ollama.com/settings/keys" ;;
                429) log "Rate limited. Wait a moment and try again." ;;
                5*) log "Ollama Cloud is experiencing issues. Try again later." ;;
            esac
        fi
        exit 1
    fi

    local description
    description="$(printf '%s' "${body}" | jq -r '.response // empty')" || {
        fail "Failed to parse API response. Raw body: $(printf '%s' "${body}" | head -c 500)"
    }

    if [ -z "${description}" ]; then
        local error_msg
        error_msg="$(printf '%s' "${body}" | jq -r '.error // "No response from model"' 2>/dev/null)"
        fail "Image comprehension returned no output. ${error_msg}"
    fi

    printf '%s\n' "${description}"
}

# --- Argument parsing ---

while [ "$#" -gt 0 ]; do
    case "$1" in
        --image)
            if [ "$#" -lt 2 ]; then
                fail "--image requires a path argument"
            fi
            IMAGE_PATH="$2"
            shift 2
            ;;
        --prompt)
            if [ "$#" -lt 2 ]; then
                fail "--prompt requires a text argument"
            fi
            PROMPT="$2"
            shift 2
            ;;
        --model)
            if [ "$#" -lt 2 ]; then
                fail "--model requires a model name argument"
            fi
            MODEL="$2"
            shift 2
            ;;
        --test)
            TEST_MODE=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        -*)
            log "Unknown option: $1"
            usage
            exit 2
            ;;
        *)
            log "Unexpected argument: $1"
            usage
            exit 2
            ;;
    esac
done

# --- Resolve model from env ---

if [ -n "${OLLAMA_CLOUD_MODEL:-}" ]; then
    MODEL="${OLLAMA_CLOUD_MODEL}"
fi

# --- Main ---

validate_deps

if [ "${TEST_MODE}" = true ]; then
    validate_api_key
    log "Running smoke test with model '${MODEL}'..."
    test_image="$(create_test_image)"
    trap "rm -f \"${test_image}\" && rmdir \"$(dirname "${test_image}")\"" EXIT
    do_comprehend "${test_image}" "What do you see in this image?" "${MODEL}"
    exit $?
fi

if [ -z "${IMAGE_PATH}" ]; then
    fail "No image path given. Use --image /path/to/image or --help."
fi

validate_api_key

IMAGE_PATH="$(normalize_image_path "${IMAGE_PATH}")"
validate_image_path "${IMAGE_PATH}"

do_comprehend "${IMAGE_PATH}" "${PROMPT}" "${MODEL}"