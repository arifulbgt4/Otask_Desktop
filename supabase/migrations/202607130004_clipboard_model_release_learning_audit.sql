create table if not exists public.clipboard_items (
  clipboard_id text primary key check (clipboard_id ~ '^clipboard_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$'),
  user_id uuid not null references auth.users (id) on delete cascade,
  device_id text not null references public.devices (device_id) on delete cascade,
  content_hash text not null check (content_hash ~ '^[a-f0-9]{64}$'),
  payload_ref text not null check (char_length(payload_ref) between 1 and 512 and payload_ref ~ '^storage://clipboard/[A-Za-z0-9._/-]+$'),
  sensitivity text not null default 'normal' check (sensitivity in ('normal', 'sensitive', 'secret')),
  pinned boolean not null default false,
  expires_at timestamptz not null,
  deleted_at timestamptz,
  revision bigint not null default 0 check (revision >= 0),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check (expires_at > created_at),
  check (deleted_at is null or deleted_at >= created_at)
);

create table if not exists public.clipboard_heads (
  user_id uuid not null references auth.users (id) on delete cascade,
  device_id text not null references public.devices (device_id) on delete cascade,
  current_clipboard_id text references public.clipboard_items (clipboard_id) on delete set null,
  revision bigint not null default 0 check (revision >= 0),
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, device_id)
);

create table if not exists public.sync_changes (
  change_id text primary key check (change_id ~ '^change_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$'),
  user_id uuid not null references auth.users (id) on delete cascade,
  device_id text references public.devices (device_id) on delete set null,
  entity_type text not null check (entity_type in ('clipboard_item', 'clipboard_head', 'workflow', 'schedule', 'run', 'notification')),
  entity_id text not null check (char_length(entity_id) between 8 and 128),
  operation text not null check (operation in ('upsert', 'delete', 'tombstone')),
  entity_revision bigint not null check (entity_revision >= 0),
  content_hash text not null check (content_hash ~ '^[a-f0-9]{64}$'),
  expires_at timestamptz not null,
  created_at timestamptz not null default timezone('utc', now()),
  unique (user_id, entity_type, entity_id, entity_revision),
  check (expires_at > created_at)
);

create table if not exists public.notifications (
  notification_id text primary key check (notification_id ~ '^notification_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$'),
  user_id uuid not null references auth.users (id) on delete cascade,
  kind text not null check (kind in ('run', 'approval', 'device', 'release', 'security', 'system')),
  title text not null check (char_length(title) between 1 and 160),
  body text not null default '' check (char_length(body) <= 2000),
  action_ref text check (action_ref is null or char_length(action_ref) between 1 and 256),
  read_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  check (expires_at is null or expires_at > created_at)
);

create table if not exists public.model_packages (
  model_package_id text primary key check (model_package_id ~ '^model_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$'),
  model_id text not null check (model_id ~ '^[a-z0-9][a-z0-9._-]{1,95}$'),
  display_name text not null check (char_length(display_name) between 1 and 160),
  version text not null check (version ~ '^[0-9]+[.][0-9]+[.][0-9]+([+-][A-Za-z0-9.-]+)?$'),
  runtime text not null check (runtime = 'llama_cpp'),
  model_format text not null check (model_format = 'gguf'),
  manifest_ref text not null check (char_length(manifest_ref) between 1 and 512 and manifest_ref ~ '^storage://models/[A-Za-z0-9._/-]+$'),
  weights_ref text not null check (char_length(weights_ref) between 1 and 512 and weights_ref ~ '^storage://models/[A-Za-z0-9._/-]+$'),
  content_hash text not null check (content_hash ~ '^[a-f0-9]{64}$'),
  size_bytes bigint not null check (size_bytes between 1 and 1099511627776),
  signature text not null check (char_length(signature) between 43 and 256),
  status text not null default 'approved' check (status in ('approved', 'revoked')),
  created_at timestamptz not null default timezone('utc', now()),
  revoked_at timestamptz,
  unique (model_id, version),
  check ((status = 'approved' and revoked_at is null) or (status = 'revoked' and revoked_at is not null))
);

create table if not exists public.model_installations (
  installation_id text primary key check (installation_id ~ '^model_installation_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$'),
  model_package_id text not null references public.model_packages (model_package_id) on delete restrict,
  device_id text not null references public.devices (device_id) on delete cascade,
  state text not null check (state in ('pending', 'downloading', 'verifying', 'installed', 'failed', 'removed')),
  verification_status text not null default 'unverified' check (verification_status in ('unverified', 'verified', 'rejected')),
  installed_ref text check (installed_ref is null or (char_length(installed_ref) between 1 and 512 and installed_ref ~ '^storage://models/[A-Za-z0-9._/-]+$')),
  verified_hash text check (verified_hash is null or verified_hash ~ '^[a-f0-9]{64}$'),
  active boolean not null default false,
  installed_at timestamptz,
  verified_at timestamptz,
  last_error text not null default '' check (char_length(last_error) <= 500),
  revision bigint not null default 0 check (revision >= 0),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (model_package_id, device_id),
  check ((verification_status = 'verified' and verified_at is not null and verified_hash is not null) or verification_status <> 'verified'),
  check (state <> 'installed' or verification_status = 'verified'),
  check (not active or state = 'installed')
);

create unique index if not exists model_installations_one_active_idx
  on public.model_installations (device_id)
  where active;

create table if not exists public.release_artifacts (
  release_artifact_id text primary key check (release_artifact_id ~ '^release_artifact_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$'),
  release_version text not null check (release_version ~ '^[0-9]+[.][0-9]+[.][0-9]+$'),
  channel text not null check (channel in ('internal', 'beta', 'stable')),
  platform text not null check (platform in ('macos', 'windows', 'linux', 'android', 'ios', 'web')),
  architecture text not null check (architecture in ('x64', 'arm64', 'armv7', 'universal')),
  artifact_kind text not null check (artifact_kind in ('installer', 'package', 'symbols', 'checksums')),
  download_ref text not null check (char_length(download_ref) between 1 and 512 and download_ref ~ '^storage://releases/[A-Za-z0-9._/-]+$'),
  content_hash text not null check (content_hash ~ '^[a-f0-9]{64}$'),
  size_bytes bigint not null check (size_bytes between 1 and 10737418240),
  signature text not null check (char_length(signature) between 43 and 256),
  status text not null default 'draft' check (status in ('draft', 'published', 'revoked')),
  published_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  check ((status = 'published' and published_at is not null and revoked_at is null) or status <> 'published'),
  check (status <> 'revoked' or revoked_at is not null),
  unique (release_version, channel, platform, architecture, artifact_kind)
);

create table if not exists public.learning_resources (
  resource_id text primary key check (resource_id ~ '^resource_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$'),
  slug text not null check (slug ~ '^[a-z0-9][a-z0-9-]{1,127}$'),
  locale text not null default 'en' check (locale ~ '^[a-z]{2}(-[A-Z]{2})?$'),
  resource_type text not null check (resource_type in ('doc', 'tutorial', 'faq', 'troubleshooting', 'privacy')),
  title text not null check (char_length(title) between 1 and 200),
  summary text not null default '' check (char_length(summary) <= 1000),
  content_ref text not null check (char_length(content_ref) between 1 and 512 and content_ref ~ '^storage://learning/[A-Za-z0-9._/-]+$'),
  access text not null default 'public' check (access in ('public', 'authenticated')),
  version integer not null default 1 check (version >= 1),
  published_at timestamptz,
  updated_at timestamptz not null default timezone('utc', now()),
  unique (slug, locale, version),
  check ((published_at is null and access in ('public', 'authenticated')) or published_at is not null)
);

create table if not exists public.audit_events (
  audit_event_id text primary key check (audit_event_id ~ '^audit_[A-Za-z0-9][A-Za-z0-9_-]{7,95}$'),
  user_id uuid references auth.users (id) on delete set null,
  device_id text references public.devices (device_id) on delete set null,
  actor_type text not null check (actor_type in ('system', 'user', 'desktop', 'mobile', 'web', 'service')),
  event_type text not null check (char_length(event_type) between 3 and 96),
  entity_type text not null check (char_length(entity_type) between 3 and 96),
  entity_id text check (entity_id is null or char_length(entity_id) between 8 and 128),
  outcome text not null check (outcome in ('accepted', 'rejected', 'failed', 'observed')),
  metadata jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata) = 'object'),
  redacted boolean not null default true,
  occurred_at timestamptz not null default timezone('utc', now()),
  retention_until timestamptz not null,
  check (retention_until > occurred_at)
);

create index if not exists clipboard_items_user_created_idx on public.clipboard_items (user_id, created_at desc);
create index if not exists clipboard_items_device_idx on public.clipboard_items (device_id, created_at desc);
create index if not exists sync_changes_user_created_idx on public.sync_changes (user_id, created_at);
create index if not exists notifications_user_created_idx on public.notifications (user_id, created_at desc);
create index if not exists model_packages_status_idx on public.model_packages (status, model_id);
create index if not exists model_installations_device_idx on public.model_installations (device_id, updated_at desc);
create index if not exists release_artifacts_channel_idx on public.release_artifacts (channel, release_version desc);
create index if not exists learning_resources_public_idx on public.learning_resources (access, published_at desc);
create index if not exists audit_events_user_occurred_idx on public.audit_events (user_id, occurred_at desc);
create index if not exists audit_events_retention_idx on public.audit_events (retention_until);

drop trigger if exists clipboard_items_set_updated_at on public.clipboard_items;
create trigger clipboard_items_set_updated_at
before update on public.clipboard_items
for each row execute function public.set_updated_at();

drop trigger if exists model_installations_set_updated_at on public.model_installations;
create trigger model_installations_set_updated_at
before update on public.model_installations
for each row execute function public.set_updated_at();

create or replace function public.prevent_p02_004_append_only_mutation()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  raise exception '% is append-only; create a new event', tg_table_name;
end;
$$;

drop trigger if exists sync_changes_append_only on public.sync_changes;
create trigger sync_changes_append_only
before update or delete on public.sync_changes
for each row execute function public.prevent_p02_004_append_only_mutation();

drop trigger if exists audit_events_append_only on public.audit_events;
create trigger audit_events_append_only
before update or delete on public.audit_events
for each row execute function public.prevent_p02_004_append_only_mutation();

alter table public.clipboard_items enable row level security;
alter table public.clipboard_heads enable row level security;
alter table public.sync_changes enable row level security;
alter table public.notifications enable row level security;
alter table public.model_packages enable row level security;
alter table public.model_installations enable row level security;
alter table public.release_artifacts enable row level security;
alter table public.learning_resources enable row level security;
alter table public.audit_events enable row level security;

drop policy if exists clipboard_items_select_own on public.clipboard_items;
create policy clipboard_items_select_own on public.clipboard_items
for select to authenticated using ((select auth.uid()) = user_id);

drop policy if exists clipboard_items_insert_own on public.clipboard_items;
create policy clipboard_items_insert_own on public.clipboard_items
for insert to authenticated with check ((select auth.uid()) = user_id);

drop policy if exists clipboard_items_update_own on public.clipboard_items;
create policy clipboard_items_update_own on public.clipboard_items
for update to authenticated using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists clipboard_heads_select_own on public.clipboard_heads;
create policy clipboard_heads_select_own on public.clipboard_heads
for select to authenticated using ((select auth.uid()) = user_id);

drop policy if exists clipboard_heads_insert_own on public.clipboard_heads;
create policy clipboard_heads_insert_own on public.clipboard_heads
for insert to authenticated with check ((select auth.uid()) = user_id);

drop policy if exists clipboard_heads_update_own on public.clipboard_heads;
create policy clipboard_heads_update_own on public.clipboard_heads
for update to authenticated using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists sync_changes_select_own on public.sync_changes;
create policy sync_changes_select_own on public.sync_changes
for select to authenticated using ((select auth.uid()) = user_id);

drop policy if exists notifications_select_own on public.notifications;
create policy notifications_select_own on public.notifications
for select to authenticated using ((select auth.uid()) = user_id);

drop policy if exists notifications_update_own on public.notifications;
create policy notifications_update_own on public.notifications
for update to authenticated using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists model_packages_select_approved on public.model_packages;
create policy model_packages_select_approved on public.model_packages
for select to anon, authenticated using (status = 'approved');

drop policy if exists model_installations_select_own on public.model_installations;
create policy model_installations_select_own on public.model_installations
for select to authenticated using (exists (select 1 from public.devices d where d.device_id = model_installations.device_id and d.user_id = (select auth.uid())));

drop policy if exists release_artifacts_select_published on public.release_artifacts;
create policy release_artifacts_select_published on public.release_artifacts
for select to anon, authenticated using (status = 'published');

drop policy if exists learning_resources_select_public on public.learning_resources;
create policy learning_resources_select_public on public.learning_resources
for select to anon, authenticated using (access = 'public' and published_at is not null);

drop policy if exists learning_resources_select_authenticated on public.learning_resources;
create policy learning_resources_select_authenticated on public.learning_resources
for select to authenticated using (access = 'authenticated' and published_at is not null);

drop policy if exists audit_events_select_own on public.audit_events;
create policy audit_events_select_own on public.audit_events
for select to authenticated using ((select auth.uid()) = user_id);

comment on table public.clipboard_items is 'Encrypted text clipboard metadata and payload references; short TTL, pinning, and tombstones; no binary payloads.';
comment on table public.clipboard_heads is 'Per-user/device current clipboard pointer for explicit sync and foreground apply.';
comment on table public.sync_changes is 'Append-only revision ledger; service-owned writes and bounded retention support conflict-safe sync.';
comment on table public.notifications is 'Durable user notifications; body is untrusted display data and may expire.';
comment on table public.model_packages is 'Approved signed Gemma/llama.cpp model manifests; weights are never stored in the database.';
comment on table public.model_installations is 'Per-device model verification and active-version state.';
comment on table public.release_artifacts is 'Signed installer/package metadata for internal, beta, and stable channels.';
comment on table public.learning_resources is 'Versioned documentation/tutorial metadata with explicit public/authenticated access.';
comment on table public.audit_events is 'Redacted append-only security and administrative event ledger with retention deadline.';
