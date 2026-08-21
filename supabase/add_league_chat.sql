-- ============================================================
-- League chat tables. lib/features/league/data/league_chat_repository.dart
-- reads/writes public.league_chat_messages and reports against
-- public.league_chat_message_reports, but neither table was ever added to
-- the schema (reset_schema.sql predates the chat feature) — hence
-- "Could not find the table 'public.league_chat_messages' in the schema
-- cache". Mirrors the public.comments / public.comment_reports pattern.
--
-- Run once in the Supabase SQL Editor. After running, also enable Realtime
-- for public.league_chat_messages (Database -> Replication in the Supabase
-- dashboard) — LeagueChatRepository.subscribeToNewMessages listens for
-- postgres_changes inserts on it, which only fire once the table is added
-- to the realtime publication.
-- ============================================================

create table public.league_chat_messages (
  id uuid primary key default gen_random_uuid(),
  league_id uuid not null references public.leagues(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  body text not null check (char_length(btrim(body)) between 1 and 1000),
  created_at timestamptz not null default now()
);
create index league_chat_messages_league_id_created_at_idx on public.league_chat_messages (league_id, created_at);
create index league_chat_messages_user_id_idx on public.league_chat_messages (user_id);

create table public.league_chat_message_reports (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.league_chat_messages(id) on delete cascade,
  reporter_id uuid not null references auth.users(id) on delete cascade,
  reason text,
  created_at timestamptz not null default now(),
  unique (message_id, reporter_id)
);

alter table public.league_chat_messages enable row level security;
alter table public.league_chat_message_reports enable row level security;

create policy "signed-in users read league chat" on public.league_chat_messages for select using (auth.uid() is not null);
create policy "create own league chat messages" on public.league_chat_messages for insert with check (user_id = auth.uid());
create policy "delete own league chat messages" on public.league_chat_messages for delete using (user_id = auth.uid());

create policy "report league chat messages as self" on public.league_chat_message_reports for insert with check (reporter_id = auth.uid());

grant select on public.league_chat_messages, public.league_chat_message_reports to authenticated;
grant insert, delete on public.league_chat_messages to authenticated;
grant insert on public.league_chat_message_reports to authenticated;
