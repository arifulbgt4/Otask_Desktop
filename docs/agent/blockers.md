# Blockers

## Active

- **P00 toolchain** — Rust/Cargo, Flutter, and Supabase CLI are unavailable in
  the current environment. Their scaffolds can be prepared, but their build,
  analysis, and local-service checks cannot be truthfully marked green until
  the tools are installed.

## Resolution rule

When a blocker is resolved, record the tool version and validation command in
the task evidence and remove the item from this file in the same change.
