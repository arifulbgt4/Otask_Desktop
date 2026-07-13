# Supabase migrations

`202607130001_profiles_devices.sql` creates the user/device identity boundary,
versioned public keys, capabilities, indexes, timestamps, constraints, and
owner-scoped RLS policies. Production keys and generated local database data
must never be committed.
