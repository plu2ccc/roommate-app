-- 合租生活管家 · Supabase 数据库初始化脚本
-- 用法：Supabase 控制台 → SQL Editor → New query → 粘贴全部内容 → Run

-- 1. 表结构 ---------------------------------------------------------------
create table if not exists public.houses (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  invite_code text not null unique default substr(md5(random()::text), 1, 6),
  created_by  uuid not null default auth.uid(),
  created_at  timestamptz not null default now()
);

create table if not exists public.house_members (
  house_id  uuid not null references public.houses(id) on delete cascade,
  user_id   uuid not null,
  joined_at timestamptz not null default now(),
  primary key (house_id, user_id)
);

-- 每个合租屋的数据按模块存成一行（expenses、rules、tasks …），value 为 JSON
create table if not exists public.house_docs (
  house_id   uuid not null references public.houses(id) on delete cascade,
  key        text not null,
  value      jsonb not null,
  updated_by uuid default auth.uid(),
  updated_at timestamptz not null default now(),
  primary key (house_id, key)
);

-- 2. 权限：只有同一合租屋的成员能读写该屋的数据 -------------------------------
create or replace function public.is_member(h uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (select 1 from house_members where house_id = h and user_id = auth.uid());
$$;

alter table public.houses        enable row level security;
alter table public.house_members enable row level security;
alter table public.house_docs    enable row level security;

drop policy if exists "members read house"   on public.houses;
drop policy if exists "members read members" on public.house_members;
drop policy if exists "members read docs"    on public.house_docs;
drop policy if exists "members insert docs"  on public.house_docs;
drop policy if exists "members update docs"  on public.house_docs;

create policy "members read house"   on public.houses        for select to authenticated using (public.is_member(id));
create policy "members read members" on public.house_members for select to authenticated using (public.is_member(house_id));
create policy "members read docs"    on public.house_docs    for select to authenticated using (public.is_member(house_id));
create policy "members insert docs"  on public.house_docs    for insert to authenticated with check (public.is_member(house_id));
create policy "members update docs"  on public.house_docs    for update to authenticated using (public.is_member(house_id)) with check (public.is_member(house_id));

-- 3. 创建 / 加入合租屋（通过函数完成，避免直接开放写 houses 和 house_members）-----
create or replace function public.create_house(p_name text)
returns public.houses
language plpgsql security definer set search_path = public
as $$
declare h public.houses;
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  insert into houses (name, created_by) values (left(trim(p_name), 40), auth.uid()) returning * into h;
  insert into house_members (house_id, user_id) values (h.id, auth.uid());
  return h;
end;
$$;

create or replace function public.join_house(p_code text)
returns public.houses
language plpgsql security definer set search_path = public
as $$
declare h public.houses;
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  select * into h from houses where invite_code = lower(trim(p_code));
  if not found then raise exception 'invalid invite code'; end if;
  insert into house_members (house_id, user_id) values (h.id, auth.uid()) on conflict do nothing;
  return h;
end;
$$;

revoke all on function public.create_house(text) from public, anon;
revoke all on function public.join_house(text)   from public, anon;
grant execute on function public.create_house(text) to authenticated;
grant execute on function public.join_house(text)   to authenticated;
grant execute on function public.is_member(uuid)    to authenticated;

-- 表权限（具体能看到哪些行仍由上面的 RLS 规则决定；未登录的 anon 不授予任何权限）
revoke all on public.houses, public.house_members, public.house_docs from anon;
grant select on public.houses, public.house_members to authenticated;
grant select, insert, update on public.house_docs to authenticated;

-- 4. 开启实时同步（室友的修改会即时推送到其他人页面）------------------------------
do $$
begin
  alter publication supabase_realtime add table public.house_docs;
exception when duplicate_object then null;
end $$;
