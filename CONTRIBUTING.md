# Contributing to image-comprehension-ollama-cloud

Thank you for your interest in contributing! This project aims to stay simple and focused, so here are some guidelines.

## Development setup

1. **Fork and clone** the repository
2. Ensure `curl`, `jq`, and `base64` are on your PATH (all standard on macOS/Linux)
3. Set your Ollama Cloud API key: `export OLLAMA_CLOUD_API_KEY=<your-key>`
4. Get a key at [ollama.com/settings/keys](https://ollama.com/settings/keys) if you don't have one

## Making changes

1. Create a branch for your change: `git checkout -b my-feature`
2. Make your changes
3. Test them (see below)
4. Commit with a clear message
5. Push and open a pull request

## Testing

The skill includes a built-in smoke test:

```bash
export OLLAMA_CLOUD_API_KEY=<your-key>
./skills/image-comprehension-ollama-cloud/scripts/comprehend_image_ollama_cloud.sh --test
```

**Warning:** `--test` makes a real API call and consumes your quota.

For manual testing, use any image:

```bash
export OLLAMA_CLOUD_API_KEY=<your-key>
./skills/image-comprehension-ollama-cloud/scripts/comprehend_image_ollama_cloud.sh --image /path/to/image.png
./skills/image-comprehension-ollama-cloud/scripts/comprehend_image_ollama_cloud.sh --image /path/to/image.png --model qwen3-vl:235b
./skills/image-comprehension-ollama-cloud/scripts/comprehend_image_ollama_cloud.sh --image /path/to/image.png --prompt "What text is visible?"
```

### What to test

- Default model works (`--image` only)
- Custom model via `--model` flag
- Custom model via `OLLAMA_CLOUD_MODEL` env var
- `--prompt` customization
- `--test` smoke test
- `--help` output
- Error cases (missing file, unsupported format, missing API key, invalid API key)

## Code style

- **Shell** (`comprehend_image_ollama_cloud.sh`): Use `set -euo pipefail`. Keep it minimal and functional.
- **Markdown**: Keep documentation concise and practical.
- No Python, no Node.js — this skill is pure shell with standard CLI tools.

## Reporting issues

Open an issue on GitHub with:

- What you expected
- What actually happened
- Steps to reproduce
- Your OS, `curl --version`, `jq --version`, and the model name