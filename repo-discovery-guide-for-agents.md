# Repo Discovery Guide — image-comprehension-ollama-cloud

> Cached map of non-obvious truths for coding agents. Read this before exploring the codebase.

## Maintenance Mandate

1. **Before every commit**, ask: did I change anything this guide documents? If yes, update the guide in the same commit. No exceptions.
2. **At session start**, spot-check 2-3 key facts against the actual codebase (paths, script flags, env vars). If anything drifted, update immediately.
3. **Quarterly minimum**, re-verify if the repo hasn't been touched. Stale guidance is worse than no guidance.

- Last verified: 2026-04-26
- Changes since last verify: added Windows to CI matrix, enforced 10-minute timeout, added regression tests, jobs now run in parallel

## Project Overview

This is an **Agent Skill** (per the [Agent Skills spec](https://agentskills.io/specification.md)) that gives AI coding agents cloud-powered image vision via Ollama's cloud API. It is the **cloud counterpart** to [image-comprehension-ollama](https://github.com/aosama/image-comprehension-ollama) — that skill uses local Ollama + Python; this one uses pure shell + Ollama Cloud. The entire runtime is a single Bash script with no Python, no Node.js, no local model downloads, and no GPU requirement. Only `curl`, `jq`, and `base64` are needed.

## Known Gotchas

- **This skill is cloud-only.** It does NOT use a local Ollama server. Do NOT try to run `ollama serve` or `ollama pull` before using this skill — it will never help and may confuse troubleshooting.
- **`OLLAMA_CLOUD_API_KEY` is required and only read from the environment.** The script never accepts the API key as a CLI argument. It must be exported as an env var. Missing this produces a specific error message with the setup URL.
- **`--test` makes a real API call and consumes quota.** It is not a unit test — it sends a tiny PNG to Ollama Cloud and checks that the response parses correctly. CI runs it only when the secret is configured; otherwise it skips.
- **`docs/` is empty.** It exists as a placeholder for a hero image that was never added. Do not add documentation files there without checking the local counterpart repo first.
- **`skills-lock.json` is not a lockfile for a package manager.** It is the Agent Skills spec's install manifest that maps the skill name to its GitHub source. It is not consumed by npm, pip, or any other tool.
- **The `base64` command differs between macOS and Linux.** The script detects this at runtime: macOS `base64` needs `-b 0` to avoid line wrapping; GNU `base64` needs `-w 0`. The `encode_base64` function handles both.
- **Unicode path normalization uses `python3` as a fallback.** The `normalize_image_path` function uses `python3` for macOS Unicode normalization (narrow no-break space U+202F → regular space). If `python3` is not available, the function falls back to the raw path. This is intentional — the skill's primary dependencies (`curl`, `jq`, `base64`) do NOT include Python, but the unicode normalization is a best-effort enhancement.
- **The CI `smoke-test` job skips gracefully when no API key secret is set.** It intentionally exits 0 with a skip message. Do not change this to a hard failure — it is by design so forks and PRs from external contributors don't fail CI.
- **CI runs on `ubuntu-latest`, `macos-latest`, and `windows-latest`.** The validate job uses `shell: bash` (Git Bash on Windows) so the same script runs on all three. If adding a step that requires PowerShell on Windows, gate it with `if: runner.os == 'Windows'` and use `shell: pwsh`.
- **The E2E smoke test runs on every OS in the matrix** (conditional on `OLLAMA_CLOUD_API_KEY` being configured). When the secret is not set, it skips gracefully. When set, each OS makes a real API call. This verifies the full end-to-end pipeline works cross-platform.
- **CI validation and smoke-test jobs run in parallel** (no `needs:` dependency). This keeps total pipeline wall-clock time under 10 minutes.
- **The default model is `gemma4:31b-cloud`, NOT a local model name.** This model only exists on Ollama's cloud API. Passing a local-only model name (like `moondream:1.8b`) to this skill will likely fail or return unexpected results.
- **The `.gitignore` excludes `/.agents/skills/` but NOT `.agents/` entirely.** The `.agents/` directory (used by `npx skills add` for local symlinks) is partially excluded — only the skills subdirectory is ignored, so `.agents/skills/image-comprehension-ollama-cloud/` itself may exist locally but should not be committed.
- **CI/CD has a hard 10-minute total pipeline duration cap.** Per `.github/instructions/cicd.instructions.md`, all build jobs, steps, and flows combined must not exceed 10 minutes. This is a financial constraint. The current CI (validate on 2 OSes + conditional smoke-test) runs well under this. If adding jobs, account for this cap.
- **GitHub Actions config must be researched fresh before changes.** The CI/CD instructions mandate verifying the latest GitHub Actions capabilities, runtimes, and action versions — never assume pre-training knowledge of GitHub Actions is current.

## Conventions

- **Skill directory name MUST match the `name` field in SKILL.md frontmatter exactly.** Both are `image-comprehension-ollama-cloud`. Lowercase letters, numbers, and hyphens only. No double hyphens.
- **SKILL.md frontmatter `name` field must match the directory name under `skills/`.** This is validated by `npx skills-ref validate`.
- **SKILL.md must stay under 500 lines.** The spec enforces this.
- **The shell script uses `set -euo pipefail`.** All new shell code must follow this. Use `fail()` for error exit, `log()` for progress messages to stderr.
- **All output follows the stdout/stderr split convention.** Image descriptions go to stdout; progress and error messages go to stderr. This is critical for programmatic capture via `2>/dev/null`.
- **Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/):** `feat:`, `fix:`, `docs:`, etc.
- **Branch naming**: `feature/description`, `fix/description`, `docs/description`.
- **`VERSIONS.md` tracks skill version and changelog.** Update it on every release. Current version is 1.0.0.
- **The `description` field in SKILL.md frontmatter is a trigger phrase directory.** It must be 1-1024 characters and include phrases agents would search for ("analyze image files", "screenshot", "vision model", etc.).
- **CI/CD total pipeline time must not exceed 10 minutes.** This is codified in `.github/instructions/cicd.instructions.md`. When modifying `ci.yml`, keep all jobs and steps under this cap.

## Structure Map

```
image-comprehension-ollama-cloud/
├── .github/
│   ├── instructions/           # Agent/AI coding instructions (CONTRIBUTING-style rules)
│   │   ├── cicd.instructions.md
│   │   ├── congruency.instructions.md
│   │   ├── context7.instructions.md
│   │   ├── markdown.instructions.md
│   │   ├── shell.instructions.md
│   │   └── variable-naming.instructions.md
│   └── workflows/
│       └── ci.yml              # CI: validate (3 OS, parallel) + conditional smoke test
├── docs/                       # Empty — placeholder for assets (no hero image yet)
├── skills/
│   └── image-comprehension-ollama-cloud/
│       ├── SKILL.md            # Skill instructions + frontmatter (the "contract" with agents)
│       └── scripts/
│           └── comprehend_image_ollama_cloud.sh  # The entire runtime — single Bash script
├── .gitignore                  # Excludes .agents/skills/, .env, __pycache__, .DS_Store
├── AGENTS.md                   # Agent guidelines for working in this repo
├── CONTRIBUTING.md              # How to contribute
├── LICENSE                     # MIT
├── README.md                   # User-facing documentation
├── VERSIONS.md                 # Version tracking + changelog
└── skills-lock.json            # Agent Skills spec install manifest (NOT a package lockfile)
```

Key paths:
- **The only executable**: `skills/image-comprehension-ollama-cloud/scripts/comprehend_image_ollama_cloud.sh`
- **The skill contract**: `skills/image-comprehension-ollama-cloud/SKILL.md`
- **CI config**: `.github/workflows/ci.yml`

## Entry Points

### Validate (no API key needed)
```bash
shellcheck skills/image-comprehension-ollama-cloud/scripts/comprehend_image_ollama_cloud.sh
```

### Smoke test (requires `OLLAMA_CLOUD_API_KEY`, makes a real API call)
```bash
export OLLAMA_CLOUD_API_KEY=<your-key>
./skills/image-comprehension-ollama-cloud/scripts/comprehend_image_ollama_cloud.sh --test
```

### Test with a real image
```bash
export OLLAMA_CLOUD_API_KEY=<your-key>
./skills/image-comprehension-ollama-cloud/scripts/comprehend_image_ollama_cloud.sh --image /path/to/image.png
```

### Validate skill spec
```bash
npx skills-ref validate ./skills/image-comprehension-ollama-cloud
```

### CI
CI runs on push/PR to `main`. It has two jobs:
1. **validate** (always runs): checks dependencies + `--help` + graceful failure without API key, on ubuntu-latest and macos-latest
2. **smoke-test** (conditional): only runs when `OLLAMA_CLOUD_API_KEY` secret is set in the repo

There are no unit tests other than the built-in `--test` flag in the shell script.

## What to Verify

1. **Versions** — Check `VERSIONS.md` for current skill version. Check SKILL.md frontmatter `metadata.version` matches.
2. **Paths** — Does the skill directory name still match the frontmatter `name` field? Both must be `image-comprehension-ollama-cloud`.
3. **Scripts** — Does `comprehend_image_ollama_cloud.sh` still accept `--image`, `--prompt`, `--model`, `--test`, `--help`? Are the env vars still `OLLAMA_CLOUD_API_KEY`, `OLLAMA_CLOUD_MODEL`, `COMPREHEND_IMAGE_CLOUD_TIMEOUT_SECONDS`?
4. **Config values** — Is the default model still `gemma4:31b-cloud`? Is the API URL still `https://ollama.com/api/generate`? Is the default timeout still 180?
5. **Known exceptions** — Are the gotchas above still true? Any new ones?
6. **Content structure** — Does `skills/` still contain exactly one directory named exactly `image-comprehension-ollama-cloud`?
7. **Dead ends** — Is `docs/` still empty? Is it still a placeholder?
8. **CI/CD duration** — Does the total pipeline (all jobs) still run under 10 minutes? Does `ci.yml` use current GitHub Actions versions?
9. **CI OS matrix** — Are all three platforms (ubuntu-latest, macos-latest, windows-latest) still in the matrix?

## Maintenance Snapshot

- Last verified: 2026-04-26
- Changes since last verify: initial creation