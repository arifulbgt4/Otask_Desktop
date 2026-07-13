-- P02-011 exposes only published release metadata to the signed-download
-- function. Storage objects remain private and are signed by the Edge layer.

create or replace function public.get_release_artifact_for_download(
  p_release_artifact_id text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_artifact public.release_artifacts%rowtype;
  v_now timestamptz := timezone('utc', now());
begin
  if p_release_artifact_id is null
     or p_release_artifact_id !~ '^release_artifact_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$' then
    raise exception 'release artifact id is invalid' using errcode = '22023';
  end if;

  select * into v_artifact
    from public.release_artifacts
   where release_artifact_id = p_release_artifact_id
     and status = 'published'
     and revoked_at is null
     and published_at is not null
     and published_at <= v_now;
  if not found then
    raise exception 'release artifact is not downloadable' using errcode = '42501';
  end if;

  return jsonb_build_object(
    'release_artifact_id', v_artifact.release_artifact_id,
    'release_version', v_artifact.release_version,
    'channel', v_artifact.channel,
    'platform', v_artifact.platform,
    'architecture', v_artifact.architecture,
    'artifact_kind', v_artifact.artifact_kind,
    'download_ref', v_artifact.download_ref,
    'content_hash', v_artifact.content_hash,
    'size_bytes', v_artifact.size_bytes,
    'signature', v_artifact.signature,
    'published_at', v_artifact.published_at
  );
end;
$$;

revoke execute on function public.get_release_artifact_for_download(text) from public, anon, authenticated;
grant execute on function public.get_release_artifact_for_download(text) to service_role;
grant select on public.release_artifacts to service_role;

comment on function public.get_release_artifact_for_download(text) is 'Service-only published-artifact gate used before creating a private Storage signed URL.';
