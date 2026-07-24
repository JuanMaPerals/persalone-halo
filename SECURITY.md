# Security policy

## Supported code

| Version line | Security fixes |
| --- | --- |
| `0.3.x` release candidates | Best-effort while the community preview is active |
| Earlier versions | No |

This repository is a local-first visual laboratory. It does not claim a production audio path, hardware transport, clinical capability or a cloud-connected service. Those boundaries do not remove the need to report a security or privacy issue.

## Reporting a vulnerability

Do not open a public issue or include an exploit, credentials, audio, transcripts, personal data, device identifiers or customer information in a pull request.

Once the target GitHub repository exists, report privately through its GitHub Security Advisory reporting channel. Until that channel is enabled, ask the project owner for a private reporting route before sharing technical details. The repository must enable private vulnerability reporting before it accepts public contributions.

Include a concise description, affected revision, reproduction steps, impact, and any safe mitigation. Sanitise all supporting material; a minimal synthetic proof of concept is preferred over production data.

## Handling expectations

Maintainers will acknowledge a valid report through the private channel, triage it, and coordinate a fix and disclosure timing with the reporter. Do not disclose a suspected issue publicly until a maintainer confirms that it is safe to do so. If there is immediate risk to people, privacy or systems, stop testing and use the fastest available private escalation route.

## Scope examples

In scope include local-host exposure, file-path handling, package or build integrity, secrets handling, unsafe capability boundaries and privacy regressions. Hardware, provider and browser behavior outside this repository can still be reported when the repository's integration or documentation causes unsafe assumptions.

Out of scope are requests to treat simulation output as a medical, legal, safety or physical-device certification. Those claims are intentionally not supported by this release candidate.

