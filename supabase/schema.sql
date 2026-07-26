-- ZenTask cloud schema (Phase 11).
--
-- Run this once in your Supabase project's SQL Editor
-- (https://supabase.com/dashboard/project/_/sql/new). Safe to re-run —
-- every statement is idempotent (`if not exists` / `create or replace`).
--
-- Before running: Authentication > Providers > enable "Anonymous
-- Sign-ins" if you want the app's "Continue without an account" button
-- to work (email sign-up/sign-in works with the default settings).
--
-- id columns are `text`, not `uuid` — they hold the same string ids
-- ZenTask already generates locally (see `lib/utils/id_generator.dart`),
-- so a record's id never changes when it round-trips to the cloud.
--
-- Every table has a `deleted_at` column instead of supporting hard
-- deletes: the app has no way to tell other devices "this record used
-- to exist and is now gone" once a row is truly removed, so deletes are
-- soft (`deleted_at = now()`) and devices sync that flag like any other
-- field. A scheduled cleanup job for old soft-deleted rows is a
-- reasonable future addition, not included here.

create table if not exists public.projects (
  id text primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text not null default '',
  color_value bigint not null default 4278668719,
  icon_key text not null default 'folder',
  category text not null default 'other',
  priority text not null default 'medium',
  is_archived boolean not null default false,
  is_favorite boolean not null default false,
  linked_event_id text,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz
);

create table if not exists public.tasks (
  id text primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  project_id text,
  title text not null,
  description text not null default '',
  priority text not null default 'medium',
  due_date timestamptz,
  reminder timestamptz,
  status text not null default 'todo',
  tags jsonb not null default '[]'::jsonb,
  subtasks jsonb not null default '[]'::jsonb,
  recurrence jsonb,
  "order" integer not null default 0,
  created_at timestamptz,
  updated_at timestamptz not null,
  deleted_at timestamptz
);

create table if not exists public.events (
  id text primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  platform text not null default '',
  type text not null default 'hackathon',
  start_date timestamptz,
  end_date timestamptz,
  registration_deadline timestamptz,
  submission_deadline timestamptz,
  event_url text,
  location text,
  description text not null default '',
  logo text,
  color_value bigint not null default 4278668719,
  bookmarked boolean not null default false,
  linked_project_id text,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz
);

-- Mirrors BookmarksRepository's `'<entityType>:<entityId>'` key shape.
create table if not exists public.bookmarks (
  owner_id uuid not null references auth.users(id) on delete cascade,
  key text not null,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  primary key (owner_id, key)
);

-- One row per user: the whitelisted subset of the local settings box
-- that makes sense to sync (theme, accent, notification preference) —
-- not the whole box, which also holds device-local things like
-- migration flags that should never sync. See CloudSyncEngine's
-- `_settingsSyncKeys` for the exact key list.
create table if not exists public.user_settings (
  owner_id uuid primary key references auth.users(id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null
);

alter table public.projects enable row level security;
alter table public.tasks enable row level security;
alter table public.events enable row level security;
alter table public.bookmarks enable row level security;
alter table public.user_settings enable row level security;

drop policy if exists "Users manage their own projects" on public.projects;
create policy "Users manage their own projects" on public.projects
  for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

drop policy if exists "Users manage their own tasks" on public.tasks;
create policy "Users manage their own tasks" on public.tasks
  for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

drop policy if exists "Users manage their own events" on public.events;
create policy "Users manage their own events" on public.events
  for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

drop policy if exists "Users manage their own bookmarks" on public.bookmarks;
create policy "Users manage their own bookmarks" on public.bookmarks
  for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

drop policy if exists "Users manage their own settings" on public.user_settings;
create policy "Users manage their own settings" on public.user_settings
  for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

-- Realtime: let the app subscribe to postgres_changes on these tables.
-- `alter publication ... add table` errors if the table was already
-- added by a previous run of this script, so each is wrapped to make
-- the whole script safely re-runnable.
do $$
begin
  begin
    alter publication supabase_realtime add table public.projects;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.tasks;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.events;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.bookmarks;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.user_settings;
  exception when duplicate_object then null;
  end;
end $$;
