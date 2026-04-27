# image-comprehension-ollama-cloud Versions

Current versions of the skill. Agents can compare against local versions to check for updates.

| Skill | Version | Last Updated |
|-------|---------|--------------|
| image-comprehension-ollama-cloud | 1.0.0 | 2026-04-26 |

## Recent Changes

### 2026-04-26
- Initial release
- Cloud-powered image comprehension via Ollama's `/api/generate` endpoint
- Pure shell implementation (curl, jq, base64 only — no Python or Node.js required)
- Configurable vision model via `--model` flag and `OLLAMA_CLOUD_MODEL` env var (default: `gemma4:31b-cloud`)
- Authentication via `OLLAMA_CLOUD_API_KEY` environment variable
- Configurable timeout via `COMPREHEND_IMAGE_CLOUD_TIMEOUT_SECONDS` (default: 180)
- Unicode path normalization for macOS screenshot filenames
- Progress logs to stderr, description to stdout
- Built-in smoke test (`--test`)
- HTTP error handling with actionable messages (401, 429, 5xx)
- Privacy notice: images are sent to Ollama's cloud service