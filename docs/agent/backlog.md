# OTask atomic backlog

The authoritative detailed backlog is the supplied OTask Master Research and
Codex Implementation Specification. Tasks below are executed in exact ID
order. Each task requires implementation, tests, evidence, state update,
commit, and green required CI before it is marked `DONE`.

## Status legend

- `READY`: dependencies complete and tooling available
- `IN_PROGRESS`: actively being implemented
- `DONE`: acceptance and required CI green
- `BLOCKED`: precise external/tooling blocker recorded

## P00 — Governance and repository bootstrap

- `[DONE] P00-001` Create monorepo root, licenses, editor config, lockfiles, and tool-version files. Done when a fresh bootstrap is reproducible without application logic.
- `[DONE] P00-002` Add `AGENTS.md` with binding decisions and continuation algorithm. Done when an agent can identify selected and prohibited technology.
- `[DONE] P00-003` Add `MASTER_SPEC.md` and ADR-001 through ADR-010. Done when decisions are version-controlled and linked from README.
- `[DONE] P00-004` Create backlog, state, blocker, continuation-log, evidence templates and state schema. Done when machine-readable state validates.
- `[DONE] P00-005` Configure pnpm workspace/Turborepo for web, desktop frontend, contracts, and VS Code extension. Done when frozen install and empty builds succeed.
- `[DONE] P00-006` Create Rust workspace and baseline crates. Local Cargo is unavailable, but the Rust GitHub Actions formatter, clippy, and test job passed.
- `[DONE] P00-007` Create Flutter mobile shell and analysis options. Local Flutter is unavailable, but the macOS Flutter analyze and widget-test job passed.
- `[DONE] P00-008` Create Supabase local project, migrations/tests, and environment templates. Local CLI is unavailable, but the Supabase start/reset job passed.
- `[DONE] P00-009` Add conventional commits, PR template, CODEOWNERS, and issue templates. Done when PRs capture task, checks, evidence, and risks.
- `[DONE] P00-010` Add baseline GitHub Actions for contracts, web, Rust, Flutter, Supabase, and security. All six checks passed for commit `9265c2f`.

## P01 — Contracts, domain model, and design system

- `[DONE] P01-001` Define IDs, timestamps, revisions, error envelope, and event envelope. Local fixtures and all six required CI jobs pass for `58770ba`.
- `[DONE] P01-002` Define `TaskPlan` and every v1 step schema with strict additional-property rules. Local schema/graph fixtures and all six required CI jobs pass for `4385afb`.
- `[DONE] P01-003` Define execution state/event schemas and legal transitions. Local transition fixtures and all six required CI jobs pass for `1d5b8fa`.
- `[IN_PROGRESS] P01-004` Define schedule, approval, device, grant, evidence, artifact, and clipboard schemas. Local versioned fixtures pass; remote CI is pending.
- `P01-005` Generate or test-map TypeScript, Rust, and Dart models.
- `P01-006` Create accessible GUI design tokens and risk/status semantics.
- `P01-007` Create route/navigation maps and wireframe-level screen states.
- `P01-008` Add compatibility and fixture tests.

## P02 — Supabase backend and identity

- `P02-001` Create profile/device/key/capability migrations and RLS.
- `P02-002` Create workflow/version/schedule migrations with immutable-version constraints.
- `P02-003` Create run/event/log/artifact/approval/grant migrations.
- `P02-004` Create clipboard/model/release/learning/audit tables.
- `P02-005` Implement and test RLS for every exposed table.
- `P02-006` Configure Google OAuth for local/dev and callback handling.
- `P02-007` Implement device registration and pairing challenge functions.
- `P02-008` Implement key rotation and device revocation.
- `P02-009` Implement signed plan/approval/target-bound run grants.
- `P02-010` Implement terminal-session initialization/signaling records.
- `P02-011` Implement release metadata and signed-download URL function.
- `P02-012` Add local reset/seed/RLS/Edge Function CI suite.

## P03 — Desktop GUI and trusted service foundation

- `P03-001` Create Tauri 2 React/Vite shell and navigation.
- `P03-002` Implement secure settings and platform credential storage.
- `P03-003` Implement native OAuth system-browser callback flow.
- `P03-004` Implement device key generation, registration, and capabilities.
- `P03-005` Create Rust service lifecycle and authenticated local IPC.
- `P03-006` Create SQLite schema/migrations/repositories.
- `P03-007` Implement Dashboard, Devices, Settings, and Sync Health screens.
- `P03-008` Implement startup/login behavior per platform.
- `P03-009` Implement signed updater plumbing in test mode.
- `P03-010` Add desktop matrix and clean-install smoke harness.

## P04 — Deterministic executor and policy engine

- `P04-001` Implement plan parser, schema-version gate, and content hashing.
- `P04-002` Implement dependency validation and deterministic topological execution.
- `P04-003` Implement capability and permission policy engine.
- `P04-004` Implement workspace-root canonicalization and symlink policy.
- `P04-005` Implement command-template registry and typed argument validation.
- `P04-006` Implement PTY/ConPTY process supervision.
- `P04-007` Implement workspace/application/URL adapters.
- `P04-008` Implement package-script and command-template steps.
- `P04-009` Implement port/process/file wait and delay steps.
- `P04-010` Implement notification, clipboard, and artifact steps.
- `P04-011` Implement run state machine, lease, idempotency, and retry.
- `P04-012` Implement immutable approval binding and risk evaluation.
- `P04-013` Implement cancellation and crash recovery.
- `P04-014` Add executor security/integration fixture suite.

## P05 — Sync, schedules, and evidence

- `P05-001` Implement local outbox/inbox and revision cursor.
- `P05-002` Implement reconciliation and explicit conflict objects.
- `P05-003` Implement durable scheduler and timezone/recurrence calculation.
- `P05-004` Implement offline schedule mirror and exactly-once reconnect upload.
- `P05-005` Implement dispatch listener, grant validation, and device lease.
- `P05-006` Implement evidence event writer and sequenced log chunks.
- `P05-007` Implement redaction and sensitive-content policy.
- `P05-008` Implement artifact collection, hashing, encryption metadata, and upload.
- `P05-009` Implement evidence manifest and finalization flow.
- `P05-010` Implement desktop Run Monitor and Run Report.

## P06 — Mobile GUI

- `P06-001` Flutter architecture, routing, themes, and localization-ready strings.
- `P06-002` System-browser auth and secure token storage.
- `P06-003` Device list/detail/pair/revoke screens.
- `P06-004` Workflow library and typed builder.
- `P06-005` Schedule list/editor/calendar.
- `P06-006` Approval UI with exact step summary and biometrics.
- `P06-007` Run monitor/report and push/deep-link navigation.
- `P06-008` Explicit clipboard history/apply UI.
- `P06-009` Offline cache/outbox and conflict UI.
- `P06-010` Maestro/native permission smoke flows and CI artifacts.

## P07 — Web learning, downloads, and control portal

- `P07-001` Next.js shell, navigation, auth, and responsive design.
- `P07-002` Public product, architecture, and security pages.
- `P07-003` Learning Center content model, search, tutorials, and FAQs.
- `P07-004` Downloads page backed by signed release artifacts.
- `P07-005` Authenticated device/workflow/schedule/report pages.
- `P07-006` Verified release webhook/ingestion and cache invalidation.
- `P07-007` Documentation/version compatibility notices.
- `P07-008` Playwright, accessibility, SEO, and build checks.

## P08 — Interactive terminal and VS Code

- `P08-001` Realtime signaling state machine.
- `P08-002` WebRTC DataChannel desktop endpoint.
- `P08-003` Authenticated STUN/TURN relay and forced-relay test.
- `P08-004` Desktop graphical terminal.
- `P08-005` Flutter graphical terminal.
- `P08-006` Web terminal monitor/control within policy.
- `P08-007` VS Code extension and authenticated local bridge.
- `P08-008` Approved template/shell integration events.
- `P08-009` Native PTY fallback when extension is absent.
- `P08-010` Session abuse, replay, relay, and cancellation tests.

## P09 — Gemma 4 E4B local AI

- `P09-001` Model manifest schema and trusted signing key process.
- `P09-002` Pinned llama.cpp runtime build.
- `P09-003` Resumable signed model download and atomic installation.
- `P09-004` Model Manager GUI.
- `P09-005` Constrained inference service and quotas.
- `P09-006` TaskPlanDraft prompt, schema correction, and benchmark set.
- `P09-007` Redacted terminal explanation and run summary.
- `P09-008` Bundled documentation retrieval with local resource citations.
- `P09-009` Prompt-injection and excessive-agency tests.
- `P09-010` Startup/memory/latency benchmarks on reference devices.

## P10 — Security and privacy hardening

- `P10-001` Formal threat model and data-flow diagrams.
- `P10-002` Device/session/key rotation and emergency revoke UX.
- `P10-003` Application-layer encryption for selected synced payloads.
- `P10-004` Harden IPC, file permissions, startup, and update paths.
- `P10-005` Rate limits, quotas, and anomaly events.
- `P10-006` SBOM, dependency/license policy, secret scan, and provenance.
- `P10-007` Privacy settings, export, and deletion flows.
- `P10-008` Security review and fuzzing of parsers, schemas, executor, and signaling.

## P11 — Release engineering and production beta

- `P11-001` Signed Windows packaging and update channel.
- `P11-002` macOS signing, hardened runtime, notarization, and updater.
- `P11-003` Ubuntu AppImage/DEB and user-service packaging.
- `P11-004` Android signing and internal/closed-track workflow.
- `P11-005` iOS signing/TestFlight workflow and store requirements.
- `P11-006` Supabase production deployment with least privilege.
- `P11-007` Web portal deployment and verified release ingestion.
- `P11-008` Full cross-device beta acceptance suite.
- `P11-009` Security/privacy docs, support runbook, troubleshooting, and known limits.
- `P11-010` Staged stable rollout with rollback available.
