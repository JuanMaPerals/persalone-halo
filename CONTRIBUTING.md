# Contributing to PersalOne Digital Twin Lab

Thank you for helping test, document and improve the laboratory. This project must distinguish a visual simulation from a physically evidenced result at all times. Contributions that make that boundary clearer are especially valuable.

## Before opening a contribution

1. Read [the community-testing guide](docs/community-testing.md), [SECURITY.md](SECURITY.md) and [the code of conduct](CODE_OF_CONDUCT.md).
2. Do not include credentials, API keys, private media, personal data, audio, transcripts, device identifiers or proprietary manufacturer material.
3. Keep claims evidence-backed. A scenario is not a hardware validation; label unsupported work as `Preview data` or `Unavailable`.
4. Do not alter the package privacy setting or add publishing automation.

The repository currently has no public software licence. The project owner must select and commit one before accepting external code contributions or making the repository public. Until then, these instructions support internal review and community-test preparation only; no permission is implied by this file.

## Local workflow

Use the pinned Node and npm versions from `.node-version` and `package.json`. Run these commands from the project root:

```powershell
npm ci
npm run community:check
npm run community:sync
```

`community:check` runs documentation policy checks, the local test suite and a production build. `community:sync` is only a dry-run: it does not invoke git, contact a remote, create a release or publish a package.

## Change expectations

- Keep UI language and truth-boundary labels consistent with the current product contract.
- Add or update tests for behavioral changes. Avoid tests that require a microphone, hardware, credentials or network access.
- Explain privacy, safety and evidence implications in the pull request.
- Keep generated artifacts, build outputs and local logs out of changes.
- Make commits focused and write a clear pull-request description with the test commands you ran and their results.

## Review and release boundary

Every external repository needs branch protection, reviewed maintainers and GitHub private vulnerability reporting enabled before it accepts public work. Only an authorized maintainer may deliberately use the separately guarded `community:sync:publish` command. It is a normal non-force `git push`; it does not make a GitHub release or publish to npm.

When in doubt about a possible vulnerability or sensitive material, stop and follow [SECURITY.md](SECURITY.md) instead of opening a public issue.

