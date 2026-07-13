begin;

select plan(6);

insert into public.release_artifacts (
  release_artifact_id, release_version, channel, platform, architecture,
  artifact_kind, download_ref, content_hash, size_bytes, signature,
  status, published_at
) values
  ('release_artifact_p02011_stable', '1.0.0', 'stable', 'linux', 'x64', 'package', 'storage://releases/p02011/otask.tar.gz', repeat('a', 64), 1024, repeat('S', 64), 'published', now()),
  ('release_artifact_p02011_draft', '1.0.1', 'beta', 'linux', 'x64', 'package', 'storage://releases/p02011/draft.tar.gz', repeat('b', 64), 1024, repeat('T', 64), 'draft', null),
  ('release_artifact_p02011_revoked', '0.9.0', 'stable', 'linux', 'x64', 'package', 'storage://releases/p02011/revoked.tar.gz', repeat('c', 64), 1024, repeat('U', 64), 'revoked', null);

set local role service_role;
select lives_ok($$select public.get_release_artifact_for_download('release_artifact_p02011_stable')$$, 'published release passes signed-download gate');
select is((public.get_release_artifact_for_download('release_artifact_p02011_stable')->>'download_ref'), 'storage://releases/p02011/otask.tar.gz', 'published storage reference is returned');
select is((public.get_release_artifact_for_download('release_artifact_p02011_stable')->>'release_version'), '1.0.0', 'published version metadata is returned');
select throws_ok($$select public.get_release_artifact_for_download('release_artifact_p02011_draft')$$, '42501', NULL, 'draft release cannot be signed');
select throws_ok($$select public.get_release_artifact_for_download('release_artifact_p02011_revoked')$$, '42501', NULL, 'revoked release cannot be signed');
select throws_ok($$select public.get_release_artifact_for_download('release_artifact_p02011_missing')$$, '42501', NULL, 'unknown release cannot be signed');

reset role;
select * from finish();
rollback;
