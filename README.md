<div align="center">

<pre>
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║   ██╗  ██╗ ██████╗ ██████╗ ██╗███████╗ ██████╗ ███╗   ██╗          ║
║   ██║  ██║██╔═══██╗██╔══██╗██║╚══███╔╝██╔═══██╗████╗  ██║          ║
║   ███████║██║   ██║██████╔╝██║  ███╔╝ ██║   ██║██╔██╗ ██║          ║
║   ██╔══██║██║   ██║██╔══██╗██║ ███╔╝  ██║   ██║██║╚██╗██║          ║
║   ██║  ██║╚██████╔╝██║  ██║██║███████╗╚██████╔╝██║ ╚████║          ║
║   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝          ║
║                                                                      ║
║                      P E R S A L O N E                               ║
║                                                                      ║
║                 &lt; SEE · UNDERSTAND · ACT /&gt;                         ║
║                                                                      ║
║        ┌──────────────┐                    ┌──────────────┐            ║
║        │  &lt; AGENT /&gt;  │────────────────────│  &lt; AGENT /&gt;  │            ║
║        └──────┬───────┘                    └──────┬───────┘            ║
║               │                                   │                    ║
║          ┌────▼───────────────────────────────────▼────┐               ║
║          │                                             │               ║
║          │      ◉      CONTEXTUAL INTELLIGENCE    ◉    │               ║
║          │                                             │               ║
║          └───────────────┬─────────────────────────────┘               ║
║                          │                                             ║
║                 YOUR DEVICE · YOUR AGENTS                             ║
║                    YOUR DATA · YOUR RULES                             ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
</pre>

# PersalOne HORIZON

### See. Understand. Act.

**The open, privacy-first agent layer for contextual computing.**

</div>

PersalOne HORIZON is an open-source platform for connecting wearable devices, AI agents, tools and human context without surrendering control of the user's data.

**Brilliant Labs Halo is the first hardware target. Real-time bidirectional ES ↔ EN conversation is the first production agent — not the limit of the platform.**

> **Your device. Your agents. Your data.**

## Why HORIZON

HORIZON is not another AI assistant and it is not just a translation app.

It is the layer between:

```text
human context
      ↓
wearable device
      ↓
secure permissions
      ↓
agent runtime
      ↓
tools · models · memory
      ↓
action
```

The goal is a modular agent ecosystem for wearables: translation, vision, accessibility, meetings, contextual assistance, security and future community-built agents.

## Platform architecture

```text
Brilliant Labs Halo / future wearable
                ↕
         Secure Device Bridge
                ↕
        PersalOne HORIZON Core
        ├─ Permissions & policy
        ├─ Privacy controls
        ├─ Agent runtime
        ├─ Provider abstraction
        ├─ Memory boundaries
        ├─ Evidence & observability
        └─ Mobile companion UI
                ↕
        Installable HORIZON Agents
        ├─ Translate
        ├─ Vision
        ├─ Assist
        ├─ Accessibility
        ├─ Meetings
        ├─ Security
        └─ Community agents
```

## First production agent — HORIZON Translate

Target flow:

```text
Halo microphone
      ↓ BLE
Mobile companion
      ↓
Streaming STT
      ↓
Incremental translation
      ↓
Streaming TTS
      ↓ BLE
Halo speaker + display
```

Initial validation pair:

- English → Spanish
- Spanish → English
- partial transcripts
- incremental translation
- barge-in / interruption
- push-to-talk fallback
- source + translated text
- latency measurements per stage
- AEC / voice processing where verified on Halo

## Agent-first by design

Every agent should declare what it wants to access.

```yaml
name: translate
display_name: HORIZON Translate
version: 0.1.0

permissions:
  microphone: required
  speaker: required
  display: optional
  camera: denied
  location: denied
  memory: session

processing:
  local_preferred: true

providers:
  stt: configurable
  translation: configurable
  tts: configurable
```

The user should be able to inspect, grant and revoke permissions before an agent touches sensitive context.

## Security & privacy principles

- **Agent-first.** Translation is one agent running on the platform.
- **Privacy-first.** Data minimization and explicit permissions are architectural requirements.
- **Security-by-design.** Microphone, camera, memory and tools are privileged capabilities.
- **Local-first where useful.** Prefer on-device/local execution when it materially improves privacy, resilience or latency.
- **No mandatory AI provider.** STT, translation, TTS, realtime and reasoning providers are replaceable adapters.
- **No secrets in source.** API keys and production credentials must never be committed.
- **Evidence over claims.** Physical-device capabilities remain truth-labelled until reproduced.

## Upstream boundaries

HORIZON does **not** absorb or modify upstream Brilliant Labs repositories as product source.

```text
UPSTREAM / READ-ONLY REFERENCE
├── brilliantlabsAR/halo-firmware
└── brilliantlabsAR/brilliant_sdk

OUR PRODUCT
└── persalone-halo   ← current repository; HORIZON product code lives here
```

The upstream repositories must remain independently updateable and replaceable. HORIZON integrates them through documented adapters and contracts.

## Evidence-first status

This repository already contains prior architecture and validation work. Rebranding it as HORIZON does **not** convert prepared or simulated capabilities into verified physical facts.

| Gate | Verified progress |
|---|---:|
| Dedicated repository | 1/5 — 20% after baseline publication |
| Local Companion | 5/8 — 62.5% in the audited source tree |
| Audible ES ↔ EN on PC | 4/7 — 57% in the audited source tree |
| Physical Halo | 0/8 — 0% |
| Consented voice identity | 0/5 — 0% |

Truth labels:

- `SIMULATED` — deterministic fixture or emulator.
- `PREPARED` — implementation/contract exists but lacks physical validation.
- `MEASURED` — reproducible physical evidence exists.
- `BLOCKED` / `FAILED` — capability cannot currently be used.

The emulator and physical device must use the same Companion, runtime, policy and evidence contracts. Simulation is an adapter state, not a separate product path.

## Repository direction

```text
persalone-halo/
├── apps/
│   └── mobile/
├── core/
├── agents/
│   ├── translate/
│   ├── vision/
│   └── examples/
├── packages/
│   ├── halo-bridge/
│   ├── agent-runtime/
│   ├── permissions/
│   └── provider-sdk/
├── docs/
├── examples/
├── SECURITY.md
├── CONTRIBUTING.md
└── README.md
```

Before contributing, read the existing [master architecture](docs/PERSALONE_RUNTIME_MASTER_ARCHITECTURE.md) and [current gate status](docs/STATUS.md).

## Independence

PersalOne HORIZON is an independent open-source project. References to Brilliant Labs Halo describe hardware compatibility and technical integration targets only; they do not imply affiliation with or endorsement by Brilliant Labs.

## License

PersalOne-owned source code in this repository is licensed under Apache-2.0. Third-party SDKs, model weights, voices, datasets and assets retain their own licenses and are never automatically relicensed.

**Author:** Juan Ma Perals
