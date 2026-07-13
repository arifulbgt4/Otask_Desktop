# Supabase tests

Positive and negative RLS, migration, idempotency, concurrency, and Edge
Function authorization tests are added in `P02`.

`p02_012_ci.sql` also verifies the deterministic `supabase/seed.sql` data,
private Storage buckets, public-table RLS coverage, and service-only download
function privileges after a clean local reset.
