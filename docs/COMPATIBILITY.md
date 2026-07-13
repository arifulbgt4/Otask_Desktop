# Contract compatibility policy

OTask contracts are versioned with `major.minor` schema versions. The current
release supports `1.0` only and uses strict validation for executable plans,
events, grants, and evidence. A contract change must add a fixture and update
the compatibility manifest before it can be used by desktop, mobile, or web.

- An unknown major or minor version is rejected before deserialization.
- Additive fields require an explicit schema version decision; executable
  objects continue to use `additionalProperties: false`.
- A plan edit creates a new immutable version and invalidates incompatible
  approvals; no client silently upgrades a signed plan.
- Compatibility checks run with the contracts workspace and are required in
  CI before the next ordered backlog task is selected.
