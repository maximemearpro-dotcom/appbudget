-- =====================================================================
--  Mon budget, version 2 : projets d'épargne et abonnements
--  À coller en entier dans Supabase > SQL Editor > New query, puis « Run ».
--  Ne touche pas à vos données existantes. Peut être relancé sans danger.
-- =====================================================================

-- 1. Projets d'épargne (cagnottes avec objectif et date)
create table if not exists public.projects (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name       text not null check (char_length(name) between 1 and 60),
  icon       text not null default 'piggy' check (char_length(icon) <= 20),
  target     numeric(12,2) not null check (target > 0 and target < 100000000),
  saved      numeric(12,2) not null default 0 check (saved >= 0 and saved < 100000000),
  deadline   date,
  moves      jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists projects_user_idx on public.projects (user_id);

-- 2. Abonnements (Netflix, salle de sport…)
create table if not exists public.subscriptions (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name       text not null check (char_length(name) between 1 and 60),
  amount     numeric(12,2) not null check (amount > 0 and amount < 1000000),
  period     text not null default 'mois' check (period in ('semaine', 'mois', 'trimestre', 'an')),
  ref_date   date not null,
  active     boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists subscriptions_user_idx on public.subscriptions (user_id);

-- 3. Sécurité : chaque personne ne voit et ne modifie que ses propres lignes
alter table public.projects      enable row level security;
alter table public.subscriptions enable row level security;

drop policy if exists "projects_own" on public.projects;
create policy "projects_own" on public.projects for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

drop policy if exists "subscriptions_own" on public.subscriptions;
create policy "subscriptions_own" on public.subscriptions for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

-- 4. Droits d'accès pour l'application (personnes connectées uniquement)
grant select, insert, update, delete on public.projects, public.subscriptions to authenticated;
revoke all on public.projects, public.subscriptions from anon;

-- 5. Prise en compte immédiate par l'API
notify pgrst, 'reload schema';

-- Vérification : doit afficher 2 lignes (projects, subscriptions) avec DELETE, INSERT, SELECT, UPDATE
select table_name, string_agg(privilege_type, ', ' order by privilege_type) as droits
from information_schema.role_table_grants
where grantee = 'authenticated' and table_schema = 'public'
  and table_name in ('projects', 'subscriptions')
  and privilege_type in ('SELECT', 'INSERT', 'UPDATE', 'DELETE')
group by table_name
order by table_name;
