# PersalOne Halo

Open, evidence-first wearable translation runtime. Halo is the first physical target; ES↔EN is the first validation pair.

## Current status

This repository contains the **G0/G1 foundation**: governance documentation, a minimal Flutter Android/iOS shell, versioned Dart contracts, local checks and CI definitions. These assets are `PREPARED`, not physical evidence. The repository does **not** claim Halo BLE, microphone capture, speaker playback, audio translation, full-duplex, echo cancellation, latency, battery life, voice preservation, providers, agents or OTA.

| Gate | Estado verificable |
|---|---|
| G0 — gobernanza automatizable | `PREPARED`: preflight, CI, secret scan and SBOM workflows are defined; branch protection and private reporting still require owner action. |
| G1 — Flutter y contratos | `PREPARED`: Android/iOS project skeleton, canonical Dart contracts and local tests exist; no device adapter or physical capability is enabled. |
| G2 — conectividad Halo | `BLOCKED`: no BLE integration in this repository. |
| G3–G6 — audio y conversación | `BLOCKED`: no microphone, speaker, provider, full-duplex or AEC path is enabled. |
| G7 — agentes | `BLOCKED`: no agent runtime is enabled. |
| G8 — release móvil | `BLOCKED`: no store or release workflow is enabled. |

See [the G0/G1 architecture audit](docs/ARCHITECTURE_AUDIT_2026-08-19.md), [the current gate status](docs/STATUS.md), and [the manual GitHub settings](docs/GITHUB_MANUAL_SETTINGS.md) before contributing.

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
