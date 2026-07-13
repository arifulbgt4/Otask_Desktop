# Supabase Edge Functions

Bounded functions are implemented in `P02`. They validate identity, device
trust, grants, approvals, evidence, and signed release metadata; they never
execute user shell commands.

Current endpoints:

- `register-device`: authenticated registration, public-key storage, and a
  ten-minute hashed pairing challenge.
- `pairing-challenge`: same-user Ed25519 proof, expiry/attempt checks, one-time
  consumption, and promotion from `pairing` to `trusted`.
