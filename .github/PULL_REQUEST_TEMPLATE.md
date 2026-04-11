<!-- Pull Request template for DattoRMM.Core

Use this when opening a PR. Keep the Title concise and fill the sections below.
-->

## Summary

Provide a short, one-line summary of the change.

## Related issues

List any related issue numbers (use `Fixes #<number>` to automatically close on merge).

Example:

- Fixes #27
- Fixes #28

## Changes

Describe the key changes in this PR. Group by issue if this PR resolves multiple issues.

- Issue #27: Short description of the fix
- Issue #28: Short description of the fix

## How to test

Provide step-by-step instructions to verify the change locally.

Examples:

```powershell
# Import the module (from repo root)
Import-Module .\DattoRMM.Core\DattoRMM.Core.psm1 -Force

# Run documentation coverage check
.\Build\Get-ClassDocStatus.ps1

# (If repo uses Pester tests)
Invoke-Pester -Verbose
```

Manual checks:

- Call the affected functions (e.g., `Get-RMMAlert -AlertUid <uid>`) and verify expected behaviour.

## Checklist (required before requesting review)

- [ ] Commits are scoped and named per repository conventions (one logical change per commit)
- [ ] Linter/formatter run (e.g. `Invoke-ScriptAnalyzer`) and no new findings introduced
- [ ] `Build\Get-ClassDocStatus.ps1` reports 0 gaps for class documentation (if classes changed)
- [ ] Tests pass (Pester) or manual test steps verified
- [ ] Relevant docs/help files updated (if public API or behaviour changed)
- [ ] PR description references related issue(s) with `Fixes #<num>` where applicable

## Notes / Breaking changes

List any backwards-incompatible changes or migration steps for users.

## Reviewers / Labels / Milestone (optional)

- Request reviewer(s): @maintainer-handle
- Suggested labels: `bug`, `enhancement`, `documentation`
- Milestone: `v0.6.0-beta.1` (if applicable)
