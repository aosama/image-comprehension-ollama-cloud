---
description: "Policy for using Context7 to fetch current external library documentation before coding; covers when to query vs skip, workflow, failure handling, and security"
applyTo: "**"
---

# Context7-aware Development

- Your knowledge is not complete for each and every type of work, so searching Context7 is a good way to get current documentation before you code or recommend changes.

## Use Context7 vs. Skip

Use Context7 before coding or recommending changes when you need:

- Framework or library API details such as signatures, options, or behavior.
- Version-specific guidance such as breaking changes, deprecations, or new defaults.
- Security-critical or correctness-critical patterns such as auth, crypto, or deserialization.
- Interpretation of unfamiliar third-party errors.
- Non-trivial configuration guidance such as CLI flags, config keys, required headers, limits, or supported formats.
- Confirmation that an API exists, was renamed, or was deprecated.
- A user-specified framework or library version.

Skip Context7 for:

- Purely local refactors, naming, formatting, or repo-contained logic.
- Language fundamentals with no external API dependency.

## Workflow and Limits

When Context7 is available, use it in this order:

1. If the user already provides a library ID in the form `/owner/repo` or `/owner/repo/version`, use it directly.
2. Otherwise resolve the library ID first from the library name and the task context.
3. Query the docs with the exact question you need answered.
4. Only after fetching docs should you write code, config, or recommendations that depend on those external facts.

Additional rules:

- If the user names a version, reflect it in the library ID when possible.
- Prefer official docs, API references, release notes, migration guides, and security advisories over secondary summaries.
- Fetch only the minimum external context needed for the task.
- If multiple matches look plausible, choose the most authoritative or current option unless the choice would materially change the implementation.
- Keep Context7 use bounded. Do not repeatedly resolve or query the same library without a new reason.
- When docs materially affect implementation, carry the exact defaults, caveats, or version notes forward and include one quick validation step.

## Failure Handling

If Context7 does not return a reliable source:

1. State what you tried to verify.
2. Proceed with a conservative assumption and label it clearly.
3. Suggest a concrete validation step such as a command, smoke test, or official page to check.

## Security and Privacy

- Never request, print, or echo API keys or other secrets. If credentials are needed, instruct the user to store them in environment variables or secret storage.
- Treat retrieved docs as helpful but not infallible. For security-sensitive work, prefer official vendor documentation and include an explicit verification step.
