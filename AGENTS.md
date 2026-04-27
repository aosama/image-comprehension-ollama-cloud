# AGENTS.md

Agent Skill giving AI coding agents cloud-powered image vision via Ollama's cloud API. Cloud-only counterpart to [image-comprehension-ollama](https://github.com/aosama/image-comprehension-ollama) — no local Ollama, no Python, just `curl`, `jq`, `base64`, and an `OLLAMA_CLOUD_API_KEY`.

## Quick Reference

- **Skill name**: `image-comprehension-ollama-cloud` (must match directory name under `skills/`)
- **License**: MIT
- **Spec**: [Agent Skills spec](https://agentskills.io/specification.md)
- **Frontmatter `name`**: lowercase, hyphens, no `--`, matches directory exactly

## Test

```bash
shellcheck skills/image-comprehension-ollama-cloud/scripts/comprehend_image_ollama_cloud.sh
export OLLAMA_CLOUD_API_KEY=<key>
./skills/image-comprehension-ollama-cloud/scripts/comprehend_image_ollama_cloud.sh --test
```

## Privacy

Images are sent to `ollama.com` over HTTPS. Inform users before processing. For local-only, suggest the local skill.

## Git Conventions

- **Commits**: [Conventional Commits](https://www.conventionalcommits.org/) — `feat:`, `fix:`, `docs:`
- **Branches**: `feature/`, `fix/`, `docs/`

## PR Checklist

- [ ] `name` field matches directory name
- [ ] `description` 1-1024 chars with trigger phrases
- [ ] `SKILL.md` under 500 lines
- [ ] No sensitive data or credentials
- [ ] `shellcheck` passes