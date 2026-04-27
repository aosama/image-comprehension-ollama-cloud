---
name: image-comprehension-ollama-cloud
description: "Use this skill to analyze image files via an Ollama Cloud vision model. Unlike the local image-comprehension-ollama skill, this requires NO local Ollama installation — no ollama serve, no ollama pull, no GPU needed. Invoke it whenever you encounter an image provided as a file path — such as a screenshot, photo, diagram, chart, or scan — and need a text description of its contents. Your images are sent to Ollama's cloud service for processing. Supports PNG, JPEG, GIF, WebP, BMP."
license: MIT
compatibility: Requires curl, jq, base64, and an Ollama Cloud API key
metadata:
  author: aosama
  version: "1.0.0"
---

# Image Comprehension — Ollama Cloud

**Give your coding agent cloud-powered vision.** This skill analyzes image files using Ollama's cloud vision models — no local Ollama installation, no GPU, no model downloads required. Just an API key.

**This is a cloud skill. You do NOT need a local Ollama installation. You do NOT need to run `ollama serve`. You do NOT need to `ollama pull` any model.** This skill sends images to `https://ollama.com/api/` over the internet.

## When to use this skill

- A user shares a screenshot and asks you to debug, review, or explain it
- You take a browser screenshot for QA and need to understand what rendered on screen
- You encounter image files in the repo (diagrams, charts, photos, scans)
- You need to extract text from an image (OCR-like use case)
- You need to verify visual output (e.g., does the UI look correct?)
- Any situation where a human would look at an image and you need the same information

## When NOT to use this skill

- If you have a local Ollama installation with a vision model and prefer local processing, use the `image-comprehension-ollama` skill instead
- If you cannot send images to a cloud service for privacy or compliance reasons

## DO NOT (common mistakes)

- **DO NOT** try to start, install, or run local Ollama for this skill. This skill uses Ollama's cloud API, not a local model.
- **DO NOT** run `ollama pull` or `ollama serve` before using this skill. They are not needed.
- **DO NOT** pass the API key as a command-line argument. The key is read from the `OLLAMA_CLOUD_API_KEY` environment variable automatically.

## Prerequisites

- `curl` available on your PATH
- `jq` available on your PATH
- `base64` available on your PATH
- The `OLLAMA_CLOUD_API_KEY` environment variable set to your Ollama Cloud API key
  - Get a key at <https://ollama.com/settings/keys> (free Ollama account required)
  - Add to your shell profile: `export OLLAMA_CLOUD_API_KEY=<your-api-key>`
  - **No local Ollama installation is needed.** This key authenticates with Ollama's cloud service.

### Supported cloud vision models

| Model | Quality | Notes |
|-------|---------|-------|
| `gemma4:31b-cloud` | Excellent | **Default.** Best quality via Ollama Cloud |
| `gemma4:e2b` | Excellent | High quality, local or cloud |
| `llava:7b` | Strong | Good balance of quality and speed |
| `qwen3-vl:235b` | Excellent | Larger model, best accuracy |

Use `--model` or `OLLAMA_CLOUD_MODEL` to switch.

## Resolve the skill path first

Always call the script by absolute path. On this machine, and as a default convention, use:

```bash
$HOME/.agents/skills/image-comprehension-ollama-cloud/scripts/comprehend_image_ollama_cloud.sh
```

## Agent workflow

1. Obtain or confirm the image path from the user, or from a screenshot you took.
2. Decide what question to ask about the image:
   - For general descriptions: use the default prompt.
   - For specific information: provide a focused question via `--prompt`.
   - For text extraction: ask about text content explicitly.
   - For a verbose, structured visual reproduction: ask for a **facsimile in markdown format** (see below).
3. Run the comprehension command.
4. The description is printed to stdout (progress logs go to stderr).
5. Use the returned description to complete your task — debug, verify, analyze, answer the user's question.

### Facsimile in markdown format

When you need a **maximally detailed, structured depiction** of an image — not just a prose description but a visual reproduction that preserves spatial layout, positions, and relationships — ask the model for a facsimile in markdown format. This produces:

- ASCII art layout diagrams showing spatial composition
- Markdown tables cataloging figures, objects, and their positions
- Structured component breakdowns of setting, characters, and details
- Precise annotations of text, labels, and signatures visible in the image

Use this when you need a "you are there" level of visual fidelity, such as comparing a scanned document's layout, understanding a complex diagram's structure, or preserving the spatial arrangement of elements in an illustration.

Example prompt:

```bash
"$HOME/.agents/skills/image-comprehension-ollama-cloud/scripts/comprehend_image_ollama_cloud.sh" --image /path/to/image.png --prompt "Reproduce the content and layout of this image as a facsimile in GitHub-flavored Markdown format. Use ASCII art, markdown tables, blockquotes, and any other markdown features that best represent the visual structure, text, and composition of the image. Include every detail you can see: figures, objects, positions, text, and spatial relationships."
```

**Use the default prompt for a concise description. Use the facsimile prompt when you need maximum visual detail and spatial fidelity.**

## Default prompt

If you do not provide `--prompt`, the skill uses:

```
Describe this image in detail
```

Override with `--prompt` for specific questions about the image. Better prompts produce better descriptions — be specific about what you need to know.

## Quick start

```bash
# Basic usage with default prompt and model
"$HOME/.agents/skills/image-comprehension-ollama-cloud/scripts/comprehend_image_ollama_cloud.sh" --image /path/to/image.png

# Custom question about the image
"$HOME/.agents/skills/image-comprehension-ollama-cloud/scripts/comprehend_image_ollama_cloud.sh" --image /path/to/screenshot.png --prompt "What text is visible in this screenshot?"

# Use a different cloud model
"$HOME/.agents/skills/image-comprehension-ollama-cloud/scripts/comprehend_image_ollama_cloud.sh" --image /path/to/image.png --model qwen3-vl:235b

# Use a different model via environment variable
OLLAMA_CLOUD_MODEL=llava:7b "$HOME/.agents/skills/image-comprehension-ollama-cloud/scripts/comprehend_image_ollama_cloud.sh" --image /path/to/image.png

# Analyze a chart or diagram
"$HOME/.agents/skills/image-comprehension-ollama-cloud/scripts/comprehend_image_ollama_cloud.sh" --image /path/to/diagram.png --prompt "Explain the flow and relationships in this diagram."

# Run the built-in smoke test (makes a real API call, consumes quota)
"$HOME/.agents/skills/image-comprehension-ollama-cloud/scripts/comprehend_image_ollama_cloud.sh" --test

# Show help
"$HOME/.agents/skills/image-comprehension-ollama-cloud/scripts/comprehend_image_ollama_cloud.sh" --help
```

## Supported image formats

- PNG (`.png`)
- JPEG (`.jpg`, `.jpeg`)
- GIF (`.gif`)
- WebP (`.webp`)
- BMP (`.bmp`)

## Configuration

| Setting | CLI flag | Environment variable | Default |
|---------|----------|---------------------|---------|
| API key | — | `OLLAMA_CLOUD_API_KEY` | *(required)* |
| Vision model | `--model` | `OLLAMA_CLOUD_MODEL` | `gemma4:31b-cloud` |
| Timeout | — | `COMPREHEND_IMAGE_CLOUD_TIMEOUT_SECONDS` | `180` |

- **API key**: Set `OLLAMA_CLOUD_API_KEY` in your environment. This is required. Get a key at <https://ollama.com/settings/keys>.
- **Model**: Pass `--model <name>` on the command line, or set `OLLAMA_CLOUD_MODEL` in your environment. The CLI flag takes precedence. If neither is set, `gemma4:31b-cloud` is used.
- **Timeout**: Set `COMPREHEND_IMAGE_CLOUD_TIMEOUT_SECONDS` to change the curl timeout (default 180 seconds).

## Options

- `--image <path>` — Path to the image file to analyze (required, unless using `--test`).
- `--prompt <text>` — Custom prompt/question for the image (default: "Describe this image in detail").
- `--model <name>` — Ollama Cloud model to use (default: `gemma4:31b-cloud`, override with `OLLAMA_CLOUD_MODEL` env var).
- `--test` — Run the built-in smoke test. **Warning: makes a real API call and consumes quota.**
- `--help` — Show the help text.

## Output

The image description is printed to **stdout**. Progress logs and error messages go to **stderr**.

To capture only the description:

```bash
description=$("$HOME/.agents/skills/image-comprehension-ollama-cloud/scripts/comprehend_image_ollama_cloud.sh" --image /path/to/image.png 2>/dev/null)
```

## Concurrency guidance

**Do not parallelize image comprehension requests.** The Ollama Cloud API is rate-limited. Run comprehension one at a time and wait for each to complete before starting the next.

## How it works

1. The script validates that `curl`, `jq`, and `base64` are available.
2. It validates the `OLLAMA_CLOUD_API_KEY` environment variable is set.
3. It validates and base64-encodes the image file.
4. It sends a POST request to `https://ollama.com/api/generate` with:
   - The specified model
   - The prompt
   - The base64-encoded image
   - `stream: false` for a complete response
   - `Authorization: Bearer` header with the API key
5. The model describes the image and the description is printed to stdout.
6. HTTP errors (401, 429, 5xx) produce clear error messages with actionable guidance.

## Privacy notice

**This skill sends your images to Ollama's cloud service for processing.** If you need fully local image analysis without data leaving your machine, use the `image-comprehension-ollama` skill instead, which runs a local Ollama vision model.

## Error handling

| Error | What to do |
|-------|-----------|
| `OLLAMA_CLOUD_API_KEY environment variable is not set` | Set it: `export OLLAMA_CLOUD_API_KEY=<api-key>` in your shell profile. Get a key at https://ollama.com/settings/keys |
| `Missing dependency: curl` / `jq` / `base64` | Install the missing tool via your package manager |
| `HTTP 401` | The API key is invalid or expired. Check your key at https://ollama.com/settings/keys |
| `HTTP 429` | Rate limited. Wait a moment and try again |
| `HTTP 5xx` | Ollama's cloud service is having issues. Try again later |
| `Image file not found` | Check the path is correct and the file exists |
| `Unsupported image format` | Use PNG, JPEG, GIF, WebP, or BMP |

## Example prompts

| Use case | Prompt example |
|----------|----------------|
| General description | `"Describe this image in detail"` (default) |
| Object detection | `"What objects are present in this image?"` |
| Text extraction | `"Extract and transcribe all visible text in this image."` |
| Chart analysis | `"What does this chart show? Describe the trends and key data points."` |
| UI/UX review | `"Describe the user interface elements and their layout."` |
| Document reading | `"What is the content of this document? Summarize the key points."` |
| Error diagnosis | `"What error or issue is shown in this screenshot?"` |
| Browser QA | `"Does this webpage render correctly? Describe the layout, any visual errors, and whether the content matches what you'd expect."` |
| Facsimile reproduction | `"Reproduce the content and layout of this image as a facsimile in GitHub-flavored Markdown format. Use ASCII art, markdown tables, blockquotes, and any other markdown features that best represent the visual structure, text, and composition of the image. Include every detail you can see: figures, objects, positions, text, and spatial relationships."` |

## How to test the skill

```bash
# Run the built-in smoke test (makes a real API call, consumes quota)
"$HOME/.agents/skills/image-comprehension-ollama-cloud/scripts/comprehend_image_ollama_cloud.sh" --test

# Test with a real image
"$HOME/.agents/skills/image-comprehension-ollama-cloud/scripts/comprehend_image_ollama_cloud.sh" --image ~/Downloads/some-image.png
```

## Relationship to image-comprehension-ollama

This skill is the **cloud counterpart** to [image-comprehension-ollama](https://github.com/aosama/image-comprehension-ollama), which uses a local Ollama installation. Both skills share the same CLI interface (`--image`, `--prompt`, `--model`, `--test`, `--help`) but differ in:

| | image-comprehension-ollama | image-comprehension-ollama-cloud |
|---|---|---|
| Ollama | Local install required | No install needed |
| Model storage | Local disk (`ollama pull`) | Cloud (always available) |
| GPU required | Yes (for speed) | No |
| Privacy | Images stay local | Images sent to cloud |
| Cost | Free | Billed per usage |
| Default model | `moondream:1.8b` | `gemma4:31b-cloud` |
| Dependencies | Python 3, local Ollama | `curl`, `jq`, `base64` |

Choose the local skill when privacy matters or when you have a GPU. Choose this cloud skill when you want zero setup, no GPU, or access to larger models.