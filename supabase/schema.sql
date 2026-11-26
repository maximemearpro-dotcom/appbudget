-- =====================================================================
--  Mon budget : création de la base de données Supabase
--  À coller en entier dans Supabase > SQL Editor > New query, puis « Run ».
--  Le script peut être relancé sans danger.
-- =====================================================================

-- 1. Budget de chaque mois (revenus, charges fixes, budgets variables, épargne, marge, solde recalé)
create table if not exists public.months (
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  ym         text not null check (ym ~ '^[0-9]{4}-[0-9]{2}$'),
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (user_id, ym)
);

-- 2. Opérations (dépenses et rentrées d'argent)
create table if not exists public.transactions (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  ym         text not null check (ym ~ '^[0-9]{4}-[0-9]{2}$'),
  date       date not null,
  kind       text not null check (kind in ('depense', 'rentree')),
  line_id    text not null,
  cat        text not null check (char_length(cat) <= 120),
  label      text not null default '' check (char_length(label) <= 200),
  amount     numeric(12,2) not null check (amount > 0 and amount < 1000000),
  ts         bigint not null default (extract(epoch from now()) * 1000)::bigint,
  created_at timestamptz not null default now()
);
create index if not exists transactions_user_ym_idx on public.transactions (user_id, ym);

-- 3. Réglages personnels (photos de fond)
create table if not exists public.settings (
  user_id    uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  look       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- 4. Sécurité : chaque personne ne voit et ne modifie QUE ses propres lignes
alter table public.months       enable row level security;
alter table public.transactions enable row level security;
alter table public.settings     enable row level security;

drop policy if exists "months_own" on public.months;
create policy "months_own" on public.months for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

drop policy if exists "transactions_own" on public.transactions;
create policy "transactions_own" on public.transactions for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

drop policy if exists "settings_own" on public.settings;
create policy "settings_own" on public.settings for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

-- 4 bis. Droits d'accès par l'application (obligatoire pour les projets Supabase créés depuis mai 2026,
--        où les nouvelles tables ne sont plus ouvertes automatiquement). Les visiteurs non connectés n'ont aucun accès.
grant select, insert, update, delete on public.months, public.transactions, public.settings to authenticated;
revoke all on public.months, public.transactions, public.settings from anon;

-- 5. Photos de fond personnelles : espace de stockage privé, un dossier par personne
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('photos', 'photos', false, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

drop policy if exists "photos_select_own" on storage.objects;
create policy "photos_select_own" on storage.objects for select to authenticated
  using (bucket_id = 'photos' and (storage.foldername(name))[1] = (select auth.uid())::text);

drop policy if exists "photos_insert_own" on storage.objects;
create policy "photos_insert_own" on storage.objects for insert to authenticated
  with check (bucket_id = 'photos' and (storage.foldername(name))[1] = (select auth.uid())::text);

drop policy if exists "photos_delete_own" on storage.objects;
create policy "photos_delete_own" on storage.objects for delete to authenticated
  using (bucket_id = 'photos' and (storage.foldername(name))[1] = (select auth.uid())::text);

-- 6. « Supprimer mon compte » : efface le compte et, en cascade, toutes ses données
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Non connecté';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;
revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;

-- Version 2 : projets d'épargne et abonnements
-- 8. Projets d'épargne (cagnottes avec objectif et date)
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

-- 9. Abonnements (Netflix, salle de sport…)
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

-- 10. Sécurité : chaque personne ne voit et ne modifie que ses propres lignes
alter table public.projects      enable row level security;
alter table public.subscriptions enable row level security;

drop policy if exists "projects_own" on public.projects;
create policy "projects_own" on public.projects for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

drop policy if exists "subscriptions_own" on public.subscriptions;
create policy "subscriptions_own" on public.subscriptions for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

-- 11. Droits d'accès pour l'application (personnes connectées uniquement)
grant select, insert, update, delete on public.projects, public.subscriptions to authenticated;
revoke all on public.projects, public.subscriptions from anon;

-- 7. Prise en compte immédiate par l'API
notify pgrst, 'reload schema';
