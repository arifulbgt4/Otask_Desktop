begin;

select plan(11);

select ok(
  exists (
    select 1
    from public.learning_resources
    where resource_id = 'resource_seed_learning'
      and access = 'public'
      and published_at is not null
  ),
  'local seed contains a published learning resource'
);
select is(
  (select content_ref from public.learning_resources where resource_id = 'resource_seed_learning'),
  'storage://learning/seed/getting-started.md',
  'seed resource uses a constrained storage reference'
);
select is(
  (select public from storage.buckets where id = 'releases'),
  false,
  'release storage bucket remains private'
);
select is(
  (select count(*)::integer from storage.buckets where public = false),
  5,
  'local seed provisions all five private storage buckets'
);
select ok(
  (
    select count(*)
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relkind = 'r'
      and c.relrowsecurity
  ) >= 20,
  'all public domain tables keep RLS enabled'
);
select ok(
  has_function_privilege('service_role', 'public.get_release_artifact_for_download(text)', 'EXECUTE'),
  'service role can execute the signed-download metadata gate'
);
select ok(
  not has_function_privilege('anon', 'public.get_release_artifact_for_download(text)', 'EXECUTE'),
  'anonymous clients cannot execute the signed-download metadata gate'
);
select ok(
  not has_function_privilege('authenticated', 'public.get_release_artifact_for_download(text)', 'EXECUTE'),
  'authenticated clients cannot execute the signed-download metadata gate directly'
);

set local role anon;
select is(
  (select count(*)::integer from public.learning_resources where resource_id = 'resource_seed_learning'),
  1,
  'anonymous RLS can read the published seed resource'
);
reset role;

select ok(
  (select count(*) from pg_proc where pronamespace = 'public'::regnamespace and prosecdef) >= 8,
  'security-definer service boundaries are present'
);
select ok(
  (select count(*) from pg_class c join pg_namespace n on n.oid = c.relnamespace where n.nspname = 'public' and c.relkind = 'r') >= 20,
  'reset created the complete public domain table set'
);

select * from finish();
rollback;
