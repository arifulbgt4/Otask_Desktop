# Changelog

## Unreleased

- P01-001: added versioned common, error-envelope, and event-envelope JSON
  Schemas with tested TypeScript vocabulary and negative fixtures.
- P01-002: added strict executable `TaskPlan` and all twelve typed v1 step
  schemas with dependency-cycle and unknown-property fixtures.
- P01-003: added execution state/event schemas, legal transition table, and
  terminal/retry transition fixtures.
- P01-004: added schedule, approval, device, run-grant, evidence, artifact,
  and text-clipboard schemas with versioned examples.
- P01-005: added checked TypeScript, Rust, and Dart internal contract mappings
  with a schema-manifest compatibility guard.
- P01-006: added an accessible design-system token package with WCAG contrast,
  interaction-target, motion, and risk-semantics guards.
- P01-007: added GUI route/navigation maps and machine-readable wireframe
  screen-state contracts for desktop, mobile, and web surfaces.
- P01-008: added strict contract compatibility policy, version fixtures, and
  cross-language manifest drift checks.
- P02-001: added Supabase profiles/devices/device-keys/capabilities migration,
  owner-scoped RLS, and pgTAP policy tests.
- P02-002: added workflow/version/schedule migrations with immutable plan
  versions, target binding, owner/device RLS, and pgTAP tests.
- P02-003: added execution run/event/log/artifact/approval/grant migrations,
  sequence/hash/expiry constraints, owner RLS, and pgTAP tests.

## Unreleased

- Bootstrapped the OTask monorepo governance, contract/workspace boundaries,
  Rust crate layout, Flutter shell placeholder, Supabase local structure, and
  baseline CI workflows.
