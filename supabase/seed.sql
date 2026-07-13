-- Deterministic local bootstrap data. This seed is safe to re-run after every
-- `supabase db reset` and contains no user credentials or private content.

insert into storage.buckets (id, name, public)
values
  ('clipboard', 'clipboard', false),
  ('learning', 'learning', false),
  ('logs', 'logs', false),
  ('models', 'models', false),
  ('releases', 'releases', false)
on conflict (id) do update
set public = excluded.public;

insert into public.learning_resources (
  resource_id,
  slug,
  locale,
  resource_type,
  title,
  summary,
  content_ref,
  access,
  version,
  published_at,
  updated_at
)
values (
  'resource_seed_learning',
  'getting-started',
  'en',
  'tutorial',
  'OTask local learning seed',
  'Deterministic learning content used by local reset and RLS checks.',
  'storage://learning/seed/getting-started.md',
  'public',
  1,
  timezone('utc', '2026-01-01 00:00:00+00'::timestamptz),
  timezone('utc', '2026-01-01 00:00:00+00'::timestamptz)
)
on conflict (slug, locale, version) do update
set title = excluded.title,
    summary = excluded.summary,
    content_ref = excluded.content_ref,
    access = excluded.access,
    published_at = excluded.published_at,
    updated_at = excluded.updated_at;
