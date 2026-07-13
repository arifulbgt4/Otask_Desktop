# OTask

OTask is a GUI-first, local-first task orchestration and cross-device control
platform. Registered desktop devices are the trusted execution nodes; mobile
and web surfaces create, schedule, approve, monitor, and review work.

## Current state

This repository is being bootstrapped from the authoritative OTask Master
Research and Codex Implementation Specification. The implementation backlog is
ordered from `P00-001` through `P11-010`.

## Binding boundaries

- The product interface is GUI-only. A graphical terminal may exist, but OTask
  is not a CLI administration product.
- Version 1 uses only Gemma 4 E4B locally through a pinned embedded
  llama.cpp-compatible runtime. There is no Ollama, cloud model fallback,
  Agents SDK, multi-agent runtime, or public OTask SDK.
- Gemma output is untrusted `TaskPlanDraft` data. Only deterministic,
  schema-valid, policy-approved `TaskPlan` objects may reach the desktop
  executor.
- Desktop executes; mobile and web control, schedule, approve, learn, download,
  and monitor.

See [`AGENTS.md`](AGENTS.md), [`docs/MASTER_SPEC.md`](docs/MASTER_SPEC.md), and
[`docs/agent/backlog.md`](docs/agent/backlog.md) before making changes.

## License

OTask source is MIT licensed. See [`LICENSE`](LICENSE) and
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).
