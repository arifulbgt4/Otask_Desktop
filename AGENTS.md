# OTask Agent Instructions

## Authority and scope

`docs/MASTER_SPEC.md` and the approved OTask Master Research and Codex
Implementation Specification are the product and engineering authority. When
older notes conflict with them, the current master specification wins.

- The shipped product interface is GUI-only. A graphical terminal is allowed,
  but do not build a CLI administration surface.
- V1 uses only Gemma 4 E4B locally through a pinned embedded llama.cpp runtime.
  Do not add Ollama, cloud LLM fallback, Agents SDK, LangChain, LangGraph,
  AutoGen, multi-agent orchestration, or a public SDK/plugin runtime.
- Model output is untrusted `TaskPlanDraft` data. Only deterministic,
  schema-valid, policy-approved immutable `TaskPlan` objects may execute.
- Desktop devices execute. Mobile and web surfaces control, schedule, approve,
  learn, download, and monitor.
- Do not silently replace selected technologies. Record any required change as
  an ADR and obtain project-owner approval before implementation.

## Continuation protocol

Work one atomic backlog task at a time, in ID order. Before changes:

1. Read this file, `docs/MASTER_SPEC.md`, `docs/agent/project-state.json`,
   `docs/agent/backlog.md`, `docs/agent/blockers.md`, and the latest
   continuation-log entry.
2. Inspect git status, branch, uncommitted work, last commit, and required CI.
3. If the current task has failing checks or incomplete acceptance criteria,
   fix that task before selecting another.
4. Mark the selected task `IN_PROGRESS`, implement only that task, and run its
   required checks.
5. Write `docs/evidence/<task-id>.md` with commands, results, changed files,
   acceptance mapping, security review, blockers, and next task.
6. Update docs, schemas, tests, changelog, and machine-readable state in the
   same change.
7. Commit with the task ID, push when a remote exists, inspect all required
   GitHub Actions checks, and mark `DONE` only after they are green.

Never hide failing checks or claim verification that did not run. Missing
credentials, signing identities, or unavailable toolchains are precise
blockers; finish independent local work and record the blocker.

## Security and privacy rules

- Never commit secrets, model weights, signing certificates/private keys, local
  databases, user artifacts, or unredacted logs.
- Every executable feature requires validation, policy, cancellation, timeout,
  evidence, and negative security tests.
- Run as the user; never silently elevate privileges.
- Keep terminal/clipboard content local by default and redact before sync.
- Device grants must be short-lived, scoped to user/device/plan/target, and
  rejected after expiry, revocation, tampering, or replay.

## Repository workflow

Use protected `main` with short-lived `task/Pxx-yyy-slug` branches and one
atomic task per pull request. Keep generated artifacts and credentials out of
git. The project license is MIT; preserve third-party license notices.
