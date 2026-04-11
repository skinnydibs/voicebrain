-- VoiceBrain Supabase Setup
-- Paste this into the Supabase SQL editor and run it

-- ── NOTES TABLE ──────────────────────────────────────────────────────────────
create table notes (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid references auth.users(id) on delete cascade not null,
  created_at       timestamptz default now(),
  raw_transcript   text,
  clean_text       text,
  title            text,
  summary          text,
  category         text default 'general',
  tags             text[],
  linked_themes    text[],
  reminder_time    timestamptz,
  source           text default 'text',
  tone             text,
  duration_seconds int,
  is_done          boolean default false
);

-- ── NOTE REPLIES TABLE ────────────────────────────────────────────────────────
create table note_replies (
  id         uuid primary key default gen_random_uuid(),
  note_id    uuid references notes(id) on delete cascade not null,
  user_id    uuid references auth.users(id) on delete cascade not null,
  created_at timestamptz default now(),
  role       text not null,   -- 'user' or 'assistant'
  content    text not null,
  dismissed  boolean default false
);

-- ── MIGRATION: add dismissed column if table already exists ───────────────────
-- Run this if you created note_replies before this column was added:
-- alter table note_replies add column if not exists dismissed boolean default false;

-- ── ROW LEVEL SECURITY ────────────────────────────────────────────────────────
alter table notes enable row level security;
alter table note_replies enable row level security;

create policy "Users manage their own notes"
  on notes for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users manage their own replies"
  on note_replies for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
