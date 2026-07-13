create table if not exists public.execution_runs (
  run_id text primary key check (run_id ~ '^run_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$'),
  workflow_version_id text not null references public.workflow_versions (workflow_version_id) on delete restrict,
  target_device_id text not null references public.devices (device_id) on delete restrict,
  state text not null default 'draft' check (state in ('draft', 'validated', 'awaiting_approval', 'queued', 'running', 'success', 'failed', 'cancelled', 'timeout', 'evidence_finalized', 'synced', 'rejected', 'expired', 'retry_queued')),
  plan_hash text not null check (plan_hash ~ '^[a-f0-9]{64}$'),
  idempotency_key text not null check (char_length(idempotency_key) between 16 and 128),
  lease_id text check (lease_id is null or lease_id ~ '^lease_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$'),
  started_at timestamptz,
  finished_at timestamptz,
  final_result jsonb check (final_result is null or jsonb_typeof(final_result) = 'object'),
  revision bigint not null default 0 check (revision >= 0),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (target_device_id, idempotency_key)
);

create table if not exists public.execution_step_events (
  event_id text primary key check (event_id ~ '^event_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$'),
  run_id text not null references public.execution_runs (run_id) on delete cascade,
  sequence bigint not null check (sequence >= 1),
  event_type text not null check (event_type in ('run.created', 'run.validated', 'run.state.changed', 'step.state.changed', 'run.evidence.finalized', 'run.synced', 'run.rejected', 'run.expired')),
  step_id text check (step_id is null or step_id ~ '^[a-z][a-z0-9_-]{0,47}$'),
  from_state text,
  to_state text not null,
  actor text not null check (actor in ('system', 'user', 'desktop', 'mobile', 'web', 'cloud')),
  payload jsonb not null default '{}'::jsonb check (jsonb_typeof(payload) = 'object'),
  occurred_at timestamptz not null default timezone('utc', now()),
  unique (run_id, sequence)
);

create table if not exists public.execution_log_chunks (
  log_chunk_id text primary key check (log_chunk_id ~ '^log_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$'),
  run_id text not null references public.execution_runs (run_id) on delete cascade,
  sequence bigint not null check (sequence >= 1),
  stream text not null check (stream in ('stdout', 'stderr', 'system')),
  content_hash text not null check (content_hash ~ '^[a-f0-9]{64}$'),
  byte_size integer not null check (byte_size between 0 and 1048576),
  redacted boolean not null default true,
  payload_ref text not null check (payload_ref ~ '^storage://logs/[A-Za-z0-9._/-]{1,512}$'),
  created_at timestamptz not null default timezone('utc', now()),
  unique (run_id, sequence)
);

create table if not exists public.execution_artifacts (
  artifact_id text primary key check (artifact_id ~ '^artifact_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$'),
  run_id text not null references public.execution_runs (run_id) on delete cascade,
  kind text not null check (kind in ('log', 'file', 'screenshot', 'manifest')),
  content_hash text not null check (content_hash ~ '^[a-f0-9]{64}$'),
  size_bytes bigint not null check (size_bytes between 0 and 104857600),
  mime_type text not null check (char_length(mime_type) between 3 and 120),
  storage_ref text not null check (storage_ref ~ '^storage://[A-Za-z0-9._/-]{1,512}$'),
  redacted boolean not null default true,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.approvals (
  approval_id text primary key check (approval_id ~ '^approval_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$'),
  run_id text not null references public.execution_runs (run_id) on delete cascade,
  decided_by uuid not null references auth.users (id) on delete restrict,
  decision text not null check (decision in ('approved', 'rejected')),
  scope text not null check (scope in ('run', 'plan_version', 'step')),
  step_id text check (step_id is null or step_id ~ '^[a-z][a-z0-9_-]{0,47}$'),
  plan_hash text not null check (plan_hash ~ '^[a-f0-9]{64}$'),
  decided_at timestamptz not null default timezone('utc', now()),
  expires_at timestamptz not null,
  revoked boolean not null default false,
  reason text not null default '' check (char_length(reason) <= 500),
  revision bigint not null default 0 check (revision >= 0)
);

create table if not exists public.session_grants (
  grant_id text primary key check (grant_id ~ '^grant_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$'),
  grant_type text not null check (grant_type in ('run', 'terminal')),
  user_id uuid not null references auth.users (id) on delete cascade,
  device_id text not null references public.devices (device_id) on delete cascade,
  run_id text not null references public.execution_runs (run_id) on delete cascade,
  plan_hash text not null check (plan_hash ~ '^[a-f0-9]{64}$'),
  scope jsonb not null check (jsonb_typeof(scope) = 'object'),
  issued_at timestamptz not null default timezone('utc', now()),
  expires_at timestamptz not null,
  nonce text not null check (char_length(nonce) between 16 and 128),
  signature text not null check (char_length(signature) between 43 and 256),
  revoked_at timestamptz
);

create index if not exists execution_runs_workflow_version_id_idx on public.execution_runs (workflow_version_id);
create index if not exists execution_runs_target_device_id_idx on public.execution_runs (target_device_id);
create index if not exists execution_step_events_run_id_idx on public.execution_step_events (run_id, sequence);
create index if not exists execution_log_chunks_run_id_idx on public.execution_log_chunks (run_id, sequence);
create index if not exists execution_artifacts_run_id_idx on public.execution_artifacts (run_id);
create index if not exists approvals_run_id_idx on public.approvals (run_id);
create index if not exists session_grants_device_id_idx on public.session_grants (device_id);

drop trigger if exists execution_runs_set_updated_at on public.execution_runs;
create trigger execution_runs_set_updated_at
before update on public.execution_runs
for each row execute function public.set_updated_at();

alter table public.execution_runs enable row level security;
alter table public.execution_step_events enable row level security;
alter table public.execution_log_chunks enable row level security;
alter table public.execution_artifacts enable row level security;
alter table public.approvals enable row level security;
alter table public.session_grants enable row level security;

drop policy if exists execution_runs_select_own on public.execution_runs;
create policy execution_runs_select_own on public.execution_runs
for select to authenticated
using (
  exists (
    select 1
    from public.workflow_versions v
    join public.workflows w on w.workflow_id = v.workflow_id
    join public.devices d on d.device_id = execution_runs.target_device_id
    where v.workflow_version_id = execution_runs.workflow_version_id
      and w.user_id = (select auth.uid())
      and d.user_id = (select auth.uid())
  )
);

drop policy if exists execution_runs_insert_own on public.execution_runs;
create policy execution_runs_insert_own on public.execution_runs
for insert to authenticated
with check (
  exists (
    select 1
    from public.workflow_versions v
    join public.workflows w on w.workflow_id = v.workflow_id
    join public.devices d on d.device_id = execution_runs.target_device_id
    where v.workflow_version_id = execution_runs.workflow_version_id
      and w.user_id = (select auth.uid())
      and d.user_id = (select auth.uid())
  )
);

drop policy if exists execution_step_events_select_own on public.execution_step_events;
create policy execution_step_events_select_own on public.execution_step_events
for select to authenticated
using (exists (select 1 from public.execution_runs r where r.run_id = execution_step_events.run_id and r.target_device_id in (select d.device_id from public.devices d where d.user_id = (select auth.uid()))));

drop policy if exists execution_log_chunks_select_own on public.execution_log_chunks;
create policy execution_log_chunks_select_own on public.execution_log_chunks
for select to authenticated
using (exists (select 1 from public.execution_runs r join public.devices d on d.device_id = r.target_device_id where r.run_id = execution_log_chunks.run_id and d.user_id = (select auth.uid())));

drop policy if exists execution_artifacts_select_own on public.execution_artifacts;
create policy execution_artifacts_select_own on public.execution_artifacts
for select to authenticated
using (exists (select 1 from public.execution_runs r join public.devices d on d.device_id = r.target_device_id where r.run_id = execution_artifacts.run_id and d.user_id = (select auth.uid())));

drop policy if exists approvals_select_own on public.approvals;
create policy approvals_select_own on public.approvals
for select to authenticated
using ((select auth.uid()) = decided_by);

drop policy if exists approvals_insert_own on public.approvals;
create policy approvals_insert_own on public.approvals
for insert to authenticated
with check ((select auth.uid()) = decided_by);

drop policy if exists session_grants_select_own on public.session_grants;
create policy session_grants_select_own on public.session_grants
for select to authenticated using ((select auth.uid()) = user_id);
