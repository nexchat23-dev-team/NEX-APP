-- NEX-APP Supabase schema and RLS policies
-- Run this in the Supabase SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  username text,
  email text,
  photo_url text,
  name text,
  referral_code text unique,
  created_at timestamptz default now(),
  referral_count int default 0,
  pending_referral_tokens int default 0,
  referred_by uuid,
  joined_with_referral boolean default false
);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  created_by uuid references auth.users(id) on delete cascade,
  participants uuid[] default array[]::uuid[],
  is_group boolean default false,
  group_name text,
  admins uuid[] default array[]::uuid[],
  created_at timestamptz default now(),
  last_message text,
  last_message_time timestamptz,
  invite_code text unique,
  invite_link text,
  auto_join_enabled boolean default false,
  archived boolean default false,
  pinned boolean default false,
  muted boolean default false,
  deleted_by uuid[] default array[]::uuid[]
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid references public.conversations(id) on delete cascade,
  sender_id uuid references auth.users(id) on delete cascade,
  text text default '',
  type text default 'text',
  audio_url text,
  reply_to uuid,
  reply_text text,
  reply_sender text,
  created_at timestamptz default now()
);

create table if not exists public.join_requests (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid references public.conversations(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  user_email text,
  status text default 'pending',
  requested_at timestamptz default now(),
  approved_at timestamptz,
  approved_by uuid,
  rejected_at timestamptz,
  rejected_by uuid
);

create table if not exists public.blocked_users (
  id uuid primary key default gen_random_uuid(),
  blocker_id uuid references auth.users(id) on delete cascade,
  blocked_id uuid references auth.users(id) on delete cascade,
  created_at timestamptz default now()
);

do $$
begin
  if exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'users') then
    alter table public.users enable row level security;
  end if;
  if exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'conversations') then
    alter table public.conversations enable row level security;
  end if;
  if exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'messages') then
    alter table public.messages enable row level security;
  end if;
  if exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'join_requests') then
    alter table public.join_requests enable row level security;
  end if;
  if exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'blocked_users') then
    alter table public.blocked_users enable row level security;
  end if;
end $$;

-- Make chat tables available to Supabase Realtime.
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'conversations'
    ) then
      alter publication supabase_realtime add table public.conversations;
    end if;

    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'messages'
    ) then
      alter publication supabase_realtime add table public.messages;
    end if;
  end if;
end $$;

-- Users: auth + referrals + profile data
 drop policy if exists "users_read_authenticated" on public.users;
 create policy "users_read_authenticated" on public.users
   for select to authenticated
   using (true);

drop policy if exists "users_insert_own" on public.users;
 create policy "users_insert_own" on public.users
   for insert to authenticated
   with check (auth.uid() = id);

drop policy if exists "users_update_own" on public.users;
 create policy "users_update_own" on public.users
   for update to authenticated
   using (auth.uid() = id)
   with check (auth.uid() = id);

-- Conversations: direct chat, group chat, invite codes, settings
 drop policy if exists "conversations_select_member" on public.conversations;
 create policy "conversations_select_member" on public.conversations
   for select to authenticated
   using (auth.uid() = created_by or auth.uid() = any(participants));

drop policy if exists "conversations_insert_creator" on public.conversations;
 create policy "conversations_insert_creator" on public.conversations
   for insert to authenticated
   with check (auth.uid() = created_by);

drop policy if exists "conversations_update_member_or_admin" on public.conversations;
 create policy "conversations_update_member_or_admin" on public.conversations
   for update to authenticated
   using (auth.uid() = created_by or auth.uid() = any(admins) or auth.uid() = any(participants))
   with check (auth.uid() = created_by or auth.uid() = any(admins) or auth.uid() = any(participants));

drop policy if exists "conversations_delete_creator_or_admin" on public.conversations;
 create policy "conversations_delete_creator_or_admin" on public.conversations
   for delete to authenticated
   using (auth.uid() = created_by or auth.uid() = any(admins));

-- Messages: sending, reading, deleting own messages
 drop policy if exists "messages_select_conversation_member" on public.messages;
 create policy "messages_select_conversation_member" on public.messages
   for select to authenticated
   using (
     exists (
       select 1 from public.conversations c
       where c.id = conversation_id
         and (auth.uid() = c.created_by or auth.uid() = any(c.participants))
     )
   );

drop policy if exists "messages_insert_sender" on public.messages;
 create policy "messages_insert_sender" on public.messages
   for insert to authenticated
   with check (auth.uid() = sender_id);

drop policy if exists "messages_update_sender" on public.messages;
 create policy "messages_update_sender" on public.messages
   for update to authenticated
   using (auth.uid() = sender_id)
   with check (auth.uid() = sender_id);

drop policy if exists "messages_delete_sender" on public.messages;
 create policy "messages_delete_sender" on public.messages
   for delete to authenticated
   using (auth.uid() = sender_id);

-- Join requests: requesting to join, admins approving/rejecting
 drop policy if exists "join_requests_select_relevant" on public.join_requests;
 create policy "join_requests_select_relevant" on public.join_requests
   for select to authenticated
   using (
     auth.uid() = user_id
     or exists (
       select 1 from public.conversations c
       where c.id = conversation_id
         and (auth.uid() = c.created_by or auth.uid() = any(c.admins))
     )
   );

drop policy if exists "join_requests_insert_self" on public.join_requests;
 create policy "join_requests_insert_self" on public.join_requests
   for insert to authenticated
   with check (auth.uid() = user_id);

drop policy if exists "join_requests_update_admin" on public.join_requests;
 create policy "join_requests_update_admin" on public.join_requests
   for update to authenticated
   using (
     exists (
       select 1 from public.conversations c
       where c.id = conversation_id
         and (auth.uid() = c.created_by or auth.uid() = any(c.admins))
     )
   )
   with check (
     exists (
       select 1 from public.conversations c
       where c.id = conversation_id
         and (auth.uid() = c.created_by or auth.uid() = any(c.admins))
     )
   );

-- Blocked users: users can manage their own block list
 drop policy if exists "blocked_select_self" on public.blocked_users;
 create policy "blocked_select_self" on public.blocked_users
   for select to authenticated
   using (auth.uid() = blocker_id or auth.uid() = blocked_id);

drop policy if exists "blocked_insert_self" on public.blocked_users;
 create policy "blocked_insert_self" on public.blocked_users
   for insert to authenticated
   with check (auth.uid() = blocker_id);

drop policy if exists "blocked_delete_self" on public.blocked_users;
 create policy "blocked_delete_self" on public.blocked_users
   for delete to authenticated
   using (auth.uid() = blocker_id);

-- Storage bucket: create a bucket named chat-media first, then apply these policies.
-- For the current app flow, create the bucket as public so getPublicUrl works.
 drop policy if exists "chat_media_select_public" on storage.objects;
 create policy "chat_media_select_public" on storage.objects
   for select to anon
   using (bucket_id = 'chat-media');

drop policy if exists "chat_media_select_authenticated" on storage.objects;
 create policy "chat_media_select_authenticated" on storage.objects
   for select to authenticated
   using (bucket_id = 'chat-media');

drop policy if exists "chat_media_insert_authenticated" on storage.objects;
 create policy "chat_media_insert_authenticated" on storage.objects
   for insert to authenticated
   with check (bucket_id = 'chat-media');

drop policy if exists "chat_media_update_owner" on storage.objects;
 create policy "chat_media_update_owner" on storage.objects
   for update to authenticated
   using (bucket_id = 'chat-media' and owner = auth.uid()::text)
   with check (bucket_id = 'chat-media' and owner = auth.uid()::text);

drop policy if exists "chat_media_delete_owner" on storage.objects;
 create policy "chat_media_delete_owner" on storage.objects
   for delete to authenticated
   using (bucket_id = 'chat-media' and owner = auth.uid()::text);
