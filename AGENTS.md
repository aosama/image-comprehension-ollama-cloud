# AGENTS.md

Guidelines for AI agents working in this repository.

## Repository Overview

This repository contains the **image-comprehension-ollama-cloud** skill — an Agent Skill that gives AI coding agents the ability to understand images by running an Ollama Cloud vision model. This is the cloud counterpart to [image-comprehension-ollama](https://github.com/aosama/image-comprehension-ollama).

- **Name**: image-comprehension-ollama-cloud
- **GitHub**: [aosama/image-comprehension-ollama-cloud](https://github.com/aosama/image-comprehension-ollama-cloud)
- **License**: MIT

## Key Difference from Local Skill

This skill uses **Ollama's cloud API** at `https://ollama.com/api/generate`. It requires:

- An `OLLAMA_CLOUD_API_KEY` environment variable (not a local Ollama installation)
- No local Ollama, no `ollama serve`, no `ollama pull`
- Only `curl`, `jq`, and `base64` (no Python)

The local skill ([image-comprehension-ollama](https://github.com/aosama/image-comprehension-ollama)) uses Python and a local Ollama server. This skill is pure shell and cloud-only.

## Repository Structure

```
image-comprehension-ollama-cloud/
├── AGENTS.md
├── CONTRIBUTING.md
├── LICENSE
├── README.md
├── VERSIONS.md
└── skills/
    └── image-comprehension-ollama-cloud/
        ├── SKILL.md
        └── scripts/
            └── comprehend_image_cloud.sh
```

## Agent Skills Specification

This skill follows the [Agent Skills spec](https://agentskills.io/specification.md).

### Required Frontmatter

```yaml
---
name: image-comprehension-ollama-cloud
description: "Use this skill to analyze image files via an Ollama Cloud vision model..."
license: MIT
compatibility: Requires curl, jq, base64, and an Ollama Cloud API key
metadata:
  author: aosama
  version: "1.0.0"
---
```

### Name Field Rules

- Lowercase letters, numbers, and hyphens only
- Must match the parent directory name exactly (`image-comprehension-ollama-cloud`)
- The skill directory lives under `skills/image-comprehension-ollama-cloud/`

## Build / Test Commands

**Shell script syntax check (if shellcheck is available):**
```bash
shellcheck skills/image-comprehension-ollama-cloud/scripts/comprehend_image_cloud.sh
```

**Smoke test (requires OLLAMA_CLOUD_API_KEY, makes a real API call):**
```bash
./skills/image-comprehension-ollama-cloud/scripts/comprehend_image_cloud.sh --test
```

**Test with a real image:**
```bash
export OLLAMA_CLOUD_API_KEY=<your-key>
./skills/image-comprehension-ollama-cloud/scripts/comprehend_image_cloud.sh --image /path/to/image.png
```

## Validation

Validate the skill against the Agent Skills spec:

```bash
npx skills-ref validate ./skills/image-comprehension-ollama-cloud
```

Checks that `SKILL.md` frontmatter is valid and naming conventions are followed.

## Privacy Considerations

This skill sends images to Ollama's cloud service. Agents should inform users that their images will be transmitted over HTTPS to `ollama.com` for processing. If the user needs local-only processing, suggest the local skill instead.

## Git Workflow

### Branch Naming

- Features: `feature/description`
- Fixes: `fix/description`
- Documentation: `docs/description`

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat: add new feature`
- `fix: resolve issue`
- `docs: update documentation`

### Pull Request Checklist

- [ ] `name` field matches directory name exactly
- [ ] `name` follows naming rules (lowercase, hyphens, no `--`)
- [ ] `description` is 1-1024 chars with trigger phrases
- [ ] `SKILL.md` is under 500 lines
- [ ] No sensitive data or credentials
- [ ] Shell script passes `shellcheck`