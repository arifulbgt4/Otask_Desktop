begin;

select plan(10);

select has_table('public', 'release_artifacts', 'release artifacts table exists');
select ok((select relrowsecurity from pg_class where oid = 'public.release_artifacts'::regclass), 'release artifacts RLS enabled');
select policies_are('public', 'release_artifacts', array['release_artifacts_select_published'], 'only published release metadata is client-readable');
select ok(has_function_privilege('service_role', 'public.get_release_artifact_for_download(text)', 'EXECUTE'), 'service role can gate signed downloads');
select ok(not has_function_privilege('anon', 'public.get_release_artifact_for_download(text)', 'EXECUTE'), 'anon cannot call the metadata gate directly');
select ok(not has_function_privilege('authenticated', 'public.get_release_artifact_for_download(text)', 'EXECUTE'), 'authenticated clients cannot call the metadata gate directly');
select ok((select prosecdef from pg_proc where oid = 'public.get_release_artifact_for_download(text)'::regprocedure), 'download gate is security definer');
select ok(has_table_privilege('service_role', 'public.release_artifacts', 'SELECT'), 'service role can read release metadata for URL signing');
select ok((select to_regclass('public.release_artifacts_channel_idx') is not null), 'release channel/version index exists');
select ok((select pg_get_functiondef('public.get_release_artifact_for_download(text)'::regprocedure) like '%status = ''published''%'), 'download gate requires published status');

select * from finish();
rollback;
