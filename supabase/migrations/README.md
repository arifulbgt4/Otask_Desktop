# Supabase migrations

`202607130001_profiles_devices.sql` creates the user/device identity boundary,
versioned public keys, capabilities, indexes, timestamps, constraints, and
owner-scoped RLS policies. `202607130002_workflows_schedules.sql` adds logical
workflows, immutable plan versions, target-bound schedules, and owner/device
RLS. `202607130008_run_grants.sql` adds short-lived signed run-grant issuance,
one-time consumption, and service-only approval/target/expiry checks. Production
keys and generated local database data must never be committed. `202607130009_terminal_sessions_signaling.sql` adds owner-scoped terminal control state, append-only Realtime signaling records, and service-only initialization/append functions.
