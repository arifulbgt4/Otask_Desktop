# Signed run grants

P02-009 issues a short-lived `run` grant only through the authenticated
`issue-run-grant` Edge Function. The service-only database function verifies the
immutable workflow version hash, the run hash, the owner of the target device,
the trusted/offline device state, and a non-revoked `run` or `plan_version`
approval before inserting the grant.

The grant envelope binds `grant_id`, user, device, run, plan hash, scope, issue
and expiry timestamps, and a nonce. The Edge Function signs that canonical
envelope with the env-backed `OTASK_GRANT_SIGNING_SECRET`; this secret is never
stored in the repository. A grant is valid for at most ten minutes, and the
request validator limits callers to 30–600 seconds.

The `consume-run-grant` Edge Function verifies the HMAC and calls the
service-only `consume_run_grant` function. Consumption checks the stored
signature, nonce, target device, expiry, revocation, and one-time `used_at`
marker. A tampered, expired, revoked, or replayed grant is rejected.

Required local environment:

```dotenv
OTASK_GRANT_SIGNING_SECRET=use-a-local-secret-at-least-32-characters-long
```

The signing secret is an application/service boundary, not a device private
key. Device private keys remain local and are never sent to Supabase.
