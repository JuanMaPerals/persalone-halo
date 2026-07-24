# Verified gate status

**Baseline date:** 2026-07-24  
**Rule:** percentages count passed acceptance gates, not code volume.

| Workstream | Passed / total | Status |
|---|---:|---|
| Repository baseline | 1/5 | Governance and architecture prepared; CI/source/release still pending |
| Companion | 5/8 | Loopback, token and tests exist; canonical contract/runtime/E2E pending |
| ES↔EN on PC | 4/7 | Existing audio/realtime code and tests; reproducible audible acceptance pending |
| Halo physical | 0/8 | No physical microphone, speaker, BLE audio, duplex or endurance evidence |
| Voice identity | 0/5 | Consent, license, similarity, latency and revocation gates pending |
| Runtime n8n operations | 0/8 | Architecture only; no deployment authorised |
| Hetzner API/CLI access | 1/4 | Official CLI installed and verified; read-only token/context/inventory pending |

## Verified test results in the audited source tree

- Companion: 18/18.
- Halo contracts/emulation: 106/106.
- Wearable contracts: 32/32.
- Realtime translation protocol: 13/13.
- Bidirectional CLI: 13/13.
- Regulatory Watch offline: 31/31, but it is a separate project and not Runtime Ops.

These results do not prove physical Halo audio or a finished product.

## Immediate gate

Create one canonical, versioned contract for Python and TypeScript; then move the real PC audio/translation runtime behind the local Companion. The deterministic fixture and the future physical Halo adapter must implement that same contract.
