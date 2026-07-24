# PersalOne Halo

Open, evidence-first wearable translation runtime. Halo is the first physical target; ES↔EN is the first validation pair.

## Current status

This repository starts with governance and the approved architecture. It does **not** yet claim physical Halo audio, full duplex, echo cancellation, latency, battery life or voice preservation.

| Gate | Verified progress |
|---|---:|
| Dedicated repository | 1/5 — 20% after this baseline is published |
| Local Companion | 5/8 — 62.5% in the audited source tree |
| Audible ES↔EN on PC | 4/7 — 57% in the audited source tree |
| Physical Halo | 0/8 — 0% |
| Consented voice identity | 0/5 — 0% |

The source modules will move here only after the canonical wearable contract is approved and the full release gate is green.

## Architecture

```text
Halo / future wearable
  ↕ verified DeviceAdapter
Local Companion
  ├─ Audio and conversation runtime
  ├─ Translation provider router
  ├─ Voice identity gate
  ├─ Policy and evidence engine
  └─ 3D Lab UI / accessible 2D fallback
       ↕ censored aggregate events only
Private services (optional, asynchronous)
```

The emulator and physical device must use the same Companion, runtime, policy and evidence contracts. Simulation is an adapter state, not a separate product path.

## Truth labels

- `SIMULATED`: deterministic fixture or emulator.
- `PREPARED`: implementation/contract exists but lacks physical validation.
- `MEASURED`: reproducible physical evidence exists.
- `BLOCKED` / `FAILED`: the capability cannot be used.

Read [the master architecture](docs/PERSALONE_RUNTIME_MASTER_ARCHITECTURE.md) and [the current gate status](docs/STATUS.md) before contributing.

## License

PersalOne-owned source code in this repository is licensed under Apache-2.0. SDKs, model weights, voices, datasets and assets keep their own licenses and are never automatically relicensed.

Author: Juan Ma Perals.
