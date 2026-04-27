# Cross-Platform CI/CD Regression/QA Plan

> **For:** image-comprehension-ollama-cloud

**Goal:** Add Windows to the CI matrix alongside macOS and Linux, and expand the regression/QA test coverage so the skill is verified on all three platforms on every push/PR.

**Architecture:** Single `ci.yml` workflow with a matrix strategy across `ubuntu-latest`, `macos-latest`, and `windows-latest`. All jobs use `shell: bash` to run the same shell script on every OS. A `timeout-minutes: 10` cap at the job level enforces the 10-minute pipeline constraint. The smoke-test job remains conditional on the API key secret being set.

**Tech Stack:** GitHub Actions, `actions/checkout@v6`, bash (Git Bash on Windows), `curl`, `jq`, `base64`

---

### Task 1: Update `actions/checkout` to v6

**Objective:** Use the latest checkout action per the CI/CD instructions mandating current GitHub Actions versions.

**Files:**
- Modify: `.github/workflows/ci.yml:17,52`

**Step 1: Replace `actions/checkout@v4` with `actions/checkout@v6`**

In `.github/workflows/ci.yml`, replace both occurrences:

```yaml
# Old:
- uses: actions/checkout@v4
# New:
- uses: actions/checkout@v6
```

**Step 2: Verify YAML syntax**

Run: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"`
Expected: no error

**Step 3: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "chore: update actions/checkout from v4 to v6"
```

---

### Task 2: Add `windows-latest` to the validate matrix

**Objective:** Run the validate job on Windows in addition to macOS and Linux.

**Files:**
- Modify: `.github/workflows/ci.yml:15`

**Step 1: Add `windows-latest` to the matrix**

```yaml
# Old:
        os: [ubuntu-latest, macos-latest]
# New:
        os: [ubuntu-latest, macos-latest, windows-latest]
```

**Step 2: Add `defaults.run.shell: bash` at the job level**

Windows defaults to PowerShell. Our script requires bash. Add this to the `validate` job:

```yaml
  validate:
    runs-on: ${{ matrix.os }}
    defaults:
      run:
        shell: bash
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
```

**Step 3: Add Windows-specific `jq` install step**

On Windows runners, `jq` is pre-installed (v1.8.1), but to be safe add a verification/install step. `curl` and `base64` (via Git for Windows) are already on PATH.

Add after the macOS jq install step:

```yaml
      - name: Install jq (Windows)
        if: runner.os == 'Windows'
        run: choco install jq -y --skip-if-not-installed || true
```

**Step 4: Update the "Make scripts executable" step for Windows**

`chmod +x` is a no-op or unnecessary on Windows when using bash. Make it conditional:

```yaml
      - name: Make scripts executable
        if: runner.os != 'Windows'
        run: chmod +x skills/image-comprehension-ollama-cloud/scripts/comprehend_image_ollama_cloud.sh
```

**Step 5: Verify YAML syntax**

Run: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"`
Expected: no error

**Step 6: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "feat: add windows-latest to CI validate matrix"
```

---

### Task 3: Add `timeout-minutes: 10` to both jobs

**Objective:** Enforce the 10-minute total pipeline duration cap as a non-overridable parameter on each job.

**Files:**
- Modify: `.github/workflows/ci.yml`

**Step 1: Add `timeout-minutes` to the validate job**

```yaml
  validate:
    runs-on: ${{ matrix.os }}
    timeout-minutes: 10
    defaults:
      run:
        shell: bash
```

**Step 2: Add `timeout-minutes` to the smoke-test job**

```yaml
  smoke-test:
    needs: validate
    runs-on: ubuntu-latest
    timeout-minutes: 10
```

**Step 3: Verify YAML syntax**

Run: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"`
Expected: no error

**Step 4: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "feat: enforce 10-minute timeout on all CI jobs"
```

---

### Task 4: Add regression test — dependency validation failure

**Objective:** Verify the script exits with code 2 when a dependency is missing. This catches regressions in `validate_deps()`.

**Files:**
- Modify: `.github/workflows/ci.yml`

**Step 1: Add step after "Verify dependencies" in the validate job**

```yaml
      - name: Verify script fails when a dependency is missing
        shell: bash
        run: |
          PATH_BACKUP="$PATH"
          export PATH="$(echo "$PATH" | tr ':' '\n' | grep -v jq | tr '\n' ':')"
          if ./skills/image-comprehension-ollama-cloud/scripts/comprehend_image_ollama_cloud.sh --help 2>/dev/null; then
            echo "ERROR: Script should fail when jq is missing from PATH"
            export PATH="$PATH_BACKUP"
            exit 1
          else
            echo "PASS: Script correctly fails when a dependency is missing"
          fi
          export PATH="$PATH_BACKUP"
```

**Step 2: Verify YAML syntax**

Run: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"`
Expected: no error

**Step 3: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "test: add regression test for missing dependency detection"
```

---

### Task 5: Add regression test — unsupported image format

**Objective:** Verify the script rejects unsupported image formats (e.g., `.txt` files) with the correct error message.

**Files:**
- Modify: `.github/workflows/ci.yml`

**Step 1: Add step after the "fails without API key" step in the validate job**

```yaml
      - name: Verify script rejects unsupported image format
        shell: bash
        run: |
          export OLLAMA_CLOUD_API_KEY="fake-key-for-test"
          echo "not an image" > /tmp/test_unsupported.txt
          if ./skills/image-comprehension-ollama-cloud/scripts/comprehend_image_ollama_cloud.sh --image /tmp/test_unsupported.txt 2>/dev/null; then
            echo "ERROR: Script should reject .txt files"
            exit 1
          else
            echo "PASS: Script correctly rejects unsupported image formats"
          fi
```

**Step 2: Verify YAML syntax**

Run: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"`
Expected: no error

**Step 3: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "test: add regression test for unsupported image format rejection"
```

---

### Task 6: Add regression test — missing image file

**Objective:** Verify the script reports a clear error when the image file does not exist.

**Files:**
- Modify: `.github/workflows/ci.yml`

**Step 1: Add step after the unsupported format test**

```yaml
      - name: Verify script reports missing image file
        shell: bash
        run: |
          export OLLAMA_CLOUD_API_KEY="fake-key-for-test"
          if ./skills/image-comprehension-ollama-cloud/scripts/comprehend_image_ollama_cloud.sh --image /nonexistent/path/fake_image.png 2>/dev/null; then
            echo "ERROR: Script should fail for nonexistent image file"
            exit 1
          else
            echo "PASS: Script correctly reports missing image file"
          fi
```

**Step 2: Verify YAML syntax**

Run: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"`
Expected: no error

**Step 3: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "test: add regression test for missing image file error"
```

---

### Task 7: Add regression test — `--help` returns exit code 0

**Objective:** Verify `--help` exits successfully, not with an error code.

**Files:**
- Modify: `.github/workflows/ci.yml`

**Step 1: The existing "Verify script help works" step already does this implicitly, but make the exit code check explicit.**

Replace the existing step:

```yaml
      # Old:
      - name: Verify script help works
        run: ./skills/image-comprehension-ollama-cloud/scripts/comprehend_image_ollama_cloud.sh --help
      # New:
      - name: Verify script help works and exits 0
        shell: bash
        run: |
          if ! ./skills/image-comprehension-ollama-cloud/scripts/comprehend_image_ollama_cloud.sh --help >/dev/null 2>&1; then
            echo "ERROR: --help should exit with code 0"
            exit 1
          else
            echo "PASS: --help exits 0"
          fi
```

**Step 2: Verify YAML syntax**

Run: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"`
Expected: no error

**Step 3: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "test: add explicit exit-code check for --help"
```

---

### Task 8: Verify the final workflow file is syntactically valid and passes shellcheck

**Objective:** Ensure the complete `ci.yml` is valid YAML and the script still passes shellcheck.

**Files:**
- Verify: `.github/workflows/ci.yml`
- Verify: `skills/image-comprehension-ollama-cloud/scripts/comprehend_image_ollama_cloud.sh`

**Step 1: Validate YAML**

Run: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"`
Expected: no error

**Step 2: Run shellcheck**

Run: `shellcheck skills/image-comprehension-ollama-cloud/scripts/comprehend_image_ollama_cloud.sh`
Expected: no output (all clean)

**Step 3: Review the complete final `ci.yml`**

Read the full file and verify:
- `actions/checkout@v6` in both jobs
- Matrix includes `ubuntu-latest`, `macos-latest`, `windows-latest`
- `defaults.run.shell: bash` on the validate job
- `timeout-minutes: 10` on both jobs
- All OS-specific jq install steps present
- Regression tests for: missing API key, missing dependency, unsupported format, missing file, --help exit code
- Conditional `chmod +x` step (not on Windows)
- Smoke-test job remains conditional on the API key secret

---

### Task 9: Update the repo-discovery-guide-for-agents.md

**Objective:** Reflect that CI now runs on Windows, macOS, and Linux with the 10-minute cap.

**Files:**
- Modify: `repo-discovery-guide-for-agents.md`

**Step 1: Update the CI gotcha entry**

Replace:

```
- **The CI `smoke-test` job skips gracefully when no API key secret is set.**
```

With:

```
- **The CI `smoke-test` job skips gracefully when no API key secret is set.** It intentionally exits 0 with a skip message. Do not change this to a hard failure — it is by design so forks and PRs from external contributors don't fail CI.
- **CI runs on `ubuntu-latest`, `macos-latest`, and `windows-latest`.** The validate job uses `shell: bash` (Git Bash on Windows) so the same script runs on all three. If adding a step that requires PowerShell on Windows, gate it with `if: runner.os == 'Windows'` and use `shell: pwsh`.
```

**Step 2: Update the "What to verify" section**

Add after the CI/CD duration check:

```
9. **CI OS matrix** — Are all three platforms (ubuntu-latest, macos-latest, windows-latest) still in the matrix?
```

**Step 3: Update the last verified date**

```
- Last verified: 2026-04-26
- Changes since last verify: added Windows to CI matrix, enforced 10-minute timeout, added regression tests
```

**Step 4: Commit**

```bash
git add repo-discovery-guide-for-agents.md
git commit -m "docs: update repo discovery guide for cross-platform CI"
```

---

### Task 10: Push all commits and trigger CI

**Objective:** Push the branch and verify the CI pipeline runs successfully on all three platforms.

**Step 1: Push**

```bash
git push
```

**Step 2: Wait for CI and verify**

Wait for the GitHub Actions run. Check that:
- The validate job runs on all 3 OSes
- All regression tests pass
- Total pipeline is under 10 minutes
- Smoke-test skips if no API key is set (or passes if it is)

Use 30-second sleep intervals as mandated.