# OTask Master Specification (Repository Summary)

This file is the repository-facing summary of the authoritative
`OTask_Master_Research_and_Codex_Implementation_Specification.docx` supplied by
the project owner. The DOCX remains the full research record; this Markdown
file contains the binding implementation decisions needed by agents.

## Product

OTask is a GUI-first, local-first task orchestration and cross-device control
platform. A trusted desktop executes deterministic workflows. Android, iOS and
web clients create, schedule, approve, cancel, monitor, learn, and review
those workflows. The first complete scenario is: open a workspace, run an
approved package script, wait for a local port, open a URL, and produce a
verified evidence report.

## Binding architecture

- Desktop GUI: Tauri 2 + React + TypeScript + Vite.
- Desktop execution core: Rust service with policy, scheduler, PTY/process
  supervision, SQLite, sync, evidence, OS adapters, and model bridge.
- Mobile GUI: Flutter/Dart for Android and iOS.
- Web portal: Next.js App Router + TypeScript for learning, downloads,
  documentation, releases, and authenticated control pages.
- Cloud control plane: Supabase Auth, Postgres, RLS, Realtime, Edge Functions,
  and Storage. Cloud never executes user shell commands.
- Interactive sessions: WebRTC DataChannel with STUN/TURN; Realtime carries
  signaling and state only.
- Local model: Gemma 4 E4B, quantized GGUF, installed and verified locally
  through an embedded llama.cpp-compatible runtime. No Ollama or cloud model.
- Editor bridge: first-party VS Code extension using official terminal and
  workspace APIs.

## Safety boundary

Gemma output, filenames, clipboard data, terminal output, imports, Realtime
messages, and web content are untrusted. The model can create a non-executable
`TaskPlanDraft`, explain redacted output, summarize evidence, classify approved
templates, and answer from bundled documentation. It cannot spawn processes,
mutate files, approve actions, browse the network, or change its runtime.

Only an immutable, schema-valid, policy-approved `TaskPlan` reaches the
executor. Typed steps, workspace roots, command templates, separated
arguments, timeouts, cancellation, leases, idempotency keys, approval scope,
and evidence finalization are mandatory.

## Authoritative run lifecycle

`draft -> validated -> awaiting_approval|queued -> running ->
success|failed|cancelled|timeout -> evidence_finalized -> synced`.

Every run stores the plan hash/version, target device, timestamps, step events,
exit code or signal, redacted log chunks, success checks, artifacts, approval
scope, manifest hash/signature, and sync status.

## V1 exclusions

No CLI product surface, unrestricted shell autonomy, silent privilege
escalation, full generic screen control, public SDK/plugin runtime, multiple
models, model marketplace, cloud fallback, team RBAC/billing, silent mobile
clipboard monitoring, binary clipboard, or third-party executable plugins.

## Delivery rule

The ordered `P00`–`P11` backlog is the execution contract. A task is not done
until local acceptance, required platform checks, evidence, commit, and all
required remote CI checks are green. Production channels are `internal`,
`beta`, and `stable` with signed artifacts and rollback.
