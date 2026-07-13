# Supabase migrations

`202607130001_profiles_devices.sql` creates the user/device identity boundary,
versioned public keys, capabilities, indexes, timestamps, constraints, and
owner-scoped RLS policies. `202607130002_workflows_schedules.sql` adds logical
workflows, immutable plan versions, target-bound schedules, and owner/device
RLS. Production keys and generated local database data must never be committed.
