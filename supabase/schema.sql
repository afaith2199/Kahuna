-- Kahuna: Church Plant Operations Management System
-- Run this entire file in Supabase Dashboard → SQL Editor

-- ── TABLES ───────────────────────────────────────────────────────────────────

create table if not exists churches (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  pastor     text not null default 'Lead Pastor',
  city       text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists tasks (
  id         uuid    primary key default gen_random_uuid(),
  church_id  uuid    not null references churches(id) on delete cascade,
  local_id   integer not null,
  cat        text    not null,
  phase      text    not null,
  name       text    not null,
  owner      text    not null default 'Lead Pastor',
  due        text    not null default '',
  status     text    not null default 'Not Started',
  priority   text    not null default 'High',
  risk       text    not null default 'Medium',
  notes      jsonb   not null default '[]',
  docs       jsonb   not null default '[]',
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists church_members (
  id         uuid primary key default gen_random_uuid(),
  church_id  uuid not null references churches(id) on delete cascade,
  user_id    uuid not null references auth.users(id) on delete cascade,
  role       text not null default 'member',
  created_at timestamptz not null default now(),
  unique(church_id, user_id)
);

-- ── ROW LEVEL SECURITY ────────────────────────────────────────────────────────

alter table churches       enable row level security;
alter table tasks          enable row level security;
alter table church_members enable row level security;

-- church_members
create policy "Users see own memberships"
  on church_members for select
  using (auth.uid() = user_id);

create policy "Users can join churches"
  on church_members for insert
  with check (auth.uid() = user_id);

-- churches
create policy "Members can view churches"
  on churches for select
  using (
    exists (
      select 1 from church_members
      where church_members.church_id = churches.id
        and church_members.user_id   = auth.uid()
    )
  );

create policy "Authenticated users can create churches"
  on churches for insert
  to authenticated
  with check (true);

create policy "Members can update churches"
  on churches for update
  using (
    exists (
      select 1 from church_members
      where church_members.church_id = churches.id
        and church_members.user_id   = auth.uid()
    )
  );

-- tasks
create policy "Members can view tasks"
  on tasks for select
  using (
    exists (
      select 1 from church_members
      where church_members.church_id = tasks.church_id
        and church_members.user_id   = auth.uid()
    )
  );

create policy "Members can insert tasks"
  on tasks for insert
  with check (
    exists (
      select 1 from church_members
      where church_members.church_id = tasks.church_id
        and church_members.user_id   = auth.uid()
    )
  );

create policy "Members can update tasks"
  on tasks for update
  using (
    exists (
      select 1 from church_members
      where church_members.church_id = tasks.church_id
        and church_members.user_id   = auth.uid()
    )
  );

create policy "Members can delete tasks"
  on tasks for delete
  using (
    exists (
      select 1 from church_members
      where church_members.church_id = tasks.church_id
        and church_members.user_id   = auth.uid()
    )
  );
