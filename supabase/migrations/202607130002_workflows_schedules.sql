create table if not exists public.workflows (
  workflow_id text primary key check (workflow_id ~ '^workflow_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$'),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 120),
  description text not null default '' check (char_length(description) <= 1000),
  archived boolean not null default false,
  revision bigint not null default 0 check (revision >= 0),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.workflow_versions (
  workflow_version_id text primary key check (workflow_version_id ~ '^workflow_version_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$'),
  workflow_id text not null references public.workflows (workflow_id) on delete restrict,
  version integer not null check (version >= 1),
  schema_version text not null check (schema_version ~ '^[0-9]+[.][0-9]+$'),
  plan jsonb not null check (jsonb_typeof(plan) = 'object'),
  content_hash text not null check (content_hash ~ '^[a-f0-9]{64}$'),
  risk_level text not null check (risk_level in ('low', 'medium', 'high', 'critical')),
  created_at timestamptz not null default timezone('utc', now()),
  unique (workflow_id, version)
);

create table if not exists public.schedules (
  schedule_id text primary key check (schedule_id ~ '^schedule_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$'),
  workflow_version_id text not null references public.workflow_versions (workflow_version_id) on delete restrict,
  target_device_id text not null references public.devices (device_id) on delete restrict,
  timezone text not null check (char_length(timezone) between 1 and 64),
  trigger jsonb not null check (jsonb_typeof(trigger) = 'object'),
  next_run_at timestamptz,
  approval_mode text not null check (approval_mode in ('always', 'first_run', 'risk_change', 'preapproved')),
  lateness_policy text not null check (lateness_policy in ('skip', 'run_immediately', 'ask')),
  retry_policy jsonb not null default '{}'::jsonb check (jsonb_typeof(retry_policy) = 'object'),
  preconditions jsonb not null default '{}'::jsonb check (jsonb_typeof(preconditions) = 'object'),
  enabled boolean not null default true,
  revision bigint not null default 0 check (revision >= 0),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists workflows_user_id_idx on public.workflows (user_id);
create index if not exists workflow_versions_workflow_id_idx on public.workflow_versions (workflow_id);
create index if not exists schedules_workflow_version_id_idx on public.schedules (workflow_version_id);
create index if not exists schedules_target_device_id_idx on public.schedules (target_device_id);

drop trigger if exists workflows_set_updated_at on public.workflows;
create trigger workflows_set_updated_at
before update on public.workflows
for each row execute function public.set_updated_at();

drop trigger if exists schedules_set_updated_at on public.schedules;
create trigger schedules_set_updated_at
before update on public.schedules
for each row execute function public.set_updated_at();

create or replace function public.prevent_immutable_workflow_version_mutation()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  raise exception 'workflow_versions are immutable; create a new version';
end;
$$;

drop trigger if exists workflow_versions_immutable on public.workflow_versions;
create trigger workflow_versions_immutable
before update or delete on public.workflow_versions
for each row execute function public.prevent_immutable_workflow_version_mutation();

alter table public.workflows enable row level security;
alter table public.workflow_versions enable row level security;
alter table public.schedules enable row level security;

drop policy if exists workflows_select_own on public.workflows;
create policy workflows_select_own on public.workflows
for select to authenticated using ((select auth.uid()) = user_id);

drop policy if exists workflows_insert_own on public.workflows;
create policy workflows_insert_own on public.workflows
for insert to authenticated with check ((select auth.uid()) = user_id);

drop policy if exists workflows_update_own on public.workflows;
create policy workflows_update_own on public.workflows
for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists workflows_delete_own on public.workflows;
create policy workflows_delete_own on public.workflows
for delete to authenticated using ((select auth.uid()) = user_id);

drop policy if exists workflow_versions_select_own on public.workflow_versions;
create policy workflow_versions_select_own on public.workflow_versions
for select to authenticated
using (
  exists (
    select 1 from public.workflows w
    where w.workflow_id = workflow_versions.workflow_id
      and w.user_id = (select auth.uid())
  )
);

drop policy if exists workflow_versions_insert_own on public.workflow_versions;
create policy workflow_versions_insert_own on public.workflow_versions
for insert to authenticated
with check (
  exists (
    select 1 from public.workflows w
    where w.workflow_id = workflow_versions.workflow_id
      and w.user_id = (select auth.uid())
  )
);

drop policy if exists schedules_select_own on public.schedules;
create policy schedules_select_own on public.schedules
for select to authenticated
using (
  exists (
    select 1
    from public.workflow_versions v
    join public.workflows w on w.workflow_id = v.workflow_id
    join public.devices d on d.device_id = schedules.target_device_id
    where v.workflow_version_id = schedules.workflow_version_id
      and w.user_id = (select auth.uid())
      and d.user_id = (select auth.uid())
  )
);

drop policy if exists schedules_insert_own on public.schedules;
create policy schedules_insert_own on public.schedules
for insert to authenticated
with check (
  exists (
    select 1
    from public.workflow_versions v
    join public.workflows w on w.workflow_id = v.workflow_id
    join public.devices d on d.device_id = schedules.target_device_id
    where v.workflow_version_id = schedules.workflow_version_id
      and w.user_id = (select auth.uid())
      and d.user_id = (select auth.uid())
  )
);

drop policy if exists schedules_update_own on public.schedules;
create policy schedules_update_own on public.schedules
for update to authenticated
using (
  exists (
    select 1
    from public.workflow_versions v
    join public.workflows w on w.workflow_id = v.workflow_id
    join public.devices d on d.device_id = schedules.target_device_id
    where v.workflow_version_id = schedules.workflow_version_id
      and w.user_id = (select auth.uid())
      and d.user_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1
    from public.workflow_versions v
    join public.workflows w on w.workflow_id = v.workflow_id
    join public.devices d on d.device_id = schedules.target_device_id
    where v.workflow_version_id = schedules.workflow_version_id
      and w.user_id = (select auth.uid())
      and d.user_id = (select auth.uid())
  )
);

drop policy if exists schedules_delete_own on public.schedules;
create policy schedules_delete_own on public.schedules
for delete to authenticated
using (
  exists (
    select 1
    from public.workflow_versions v
    join public.workflows w on w.workflow_id = v.workflow_id
    join public.devices d on d.device_id = schedules.target_device_id
    where v.workflow_version_id = schedules.workflow_version_id
      and w.user_id = (select auth.uid())
      and d.user_id = (select auth.uid())
  )
);
