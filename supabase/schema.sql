-- Godwin Store: jalankan di Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'customer' check (role in ('customer','admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  brand text not null,
  name text not null,
  description text,
  image_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.offers (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  marketplace text not null check (marketplace in ('Shopee','Tokopedia','Bukalapak')),
  price numeric(14,2) not null check (price >= 0),
  currency text not null default 'IDR',
  product_url text not null,
  affiliate_url text,
  is_active boolean not null default true,
  last_checked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists products_active_created_idx on public.products(is_active, created_at desc);
create index if not exists offers_product_active_price_idx on public.offers(product_id, is_active, price);
create index if not exists profiles_role_idx on public.profiles(role);

create or replace function public.is_godwin_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid()) and role = 'admin'
  );
$$;

alter table public.profiles enable row level security;
alter table public.products enable row level security;
alter table public.offers enable row level security;

-- Hak baca profil hanya milik sendiri; role tidak dapat diubah dari browser.
drop policy if exists "profile read own" on public.profiles;
create policy "profile read own" on public.profiles
for select to authenticated using (id = (select auth.uid()));

drop policy if exists "public read active products" on public.products;
create policy "public read active products" on public.products
for select to anon, authenticated using (is_active = true or (select public.is_godwin_admin()));

drop policy if exists "admin insert products" on public.products;
create policy "admin insert products" on public.products
for insert to authenticated with check ((select public.is_godwin_admin()));

drop policy if exists "admin update products" on public.products;
create policy "admin update products" on public.products
for update to authenticated using ((select public.is_godwin_admin()))
with check ((select public.is_godwin_admin()));

drop policy if exists "admin delete products" on public.products;
create policy "admin delete products" on public.products
for delete to authenticated using ((select public.is_godwin_admin()));

drop policy if exists "public read active offers" on public.offers;
create policy "public read active offers" on public.offers
for select to anon, authenticated using (
  is_active = true and exists (
    select 1 from public.products p where p.id = product_id and p.is_active = true
  )
  or (select public.is_godwin_admin())
);

drop policy if exists "admin insert offers" on public.offers;
create policy "admin insert offers" on public.offers
for insert to authenticated with check ((select public.is_godwin_admin()));

drop policy if exists "admin update offers" on public.offers;
create policy "admin update offers" on public.offers
for update to authenticated using ((select public.is_godwin_admin()))
with check ((select public.is_godwin_admin()));

drop policy if exists "admin delete offers" on public.offers;
create policy "admin delete offers" on public.offers
for delete to authenticated using ((select public.is_godwin_admin()));

grant select on public.products, public.offers to anon, authenticated;
grant insert, update, delete on public.products, public.offers to authenticated;
grant select on public.profiles to authenticated;
grant execute on function public.is_godwin_admin() to anon, authenticated;

-- SETELAH membuat user admin melalui Authentication > Users, jalankan:
-- insert into public.profiles (id, role)
-- values ('GANTI_DENGAN_AUTH_USER_UUID', 'admin')
-- on conflict (id) do update set role = 'admin';

-- Kolom tambahan: harga yang ditetapkan pemilik dan dokumen PDF produk.
alter table public.products add column if not exists base_price numeric(14,2) check (base_price is null or base_price >= 0);
alter table public.products add column if not exists document_url text;

-- Bucket publik untuk foto dan PDF katalog. Hanya admin yang boleh mengunggah/mengubah/menghapus.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('product-media', 'product-media', true, 15728640, array['image/jpeg','image/png','image/webp','application/pdf'])
on conflict (id) do update set public = true, file_size_limit = 15728640,
  allowed_mime_types = array['image/jpeg','image/png','image/webp','application/pdf'];

drop policy if exists "public read Godwin product media" on storage.objects;
create policy "public read Godwin product media" on storage.objects
for select to anon, authenticated using (bucket_id = 'product-media');

drop policy if exists "admin upload Godwin product media" on storage.objects;
create policy "admin upload Godwin product media" on storage.objects
for insert to authenticated with check (bucket_id = 'product-media' and (select public.is_godwin_admin()));

drop policy if exists "admin update Godwin product media" on storage.objects;
create policy "admin update Godwin product media" on storage.objects
for update to authenticated using (bucket_id = 'product-media' and (select public.is_godwin_admin()))
with check (bucket_id = 'product-media' and (select public.is_godwin_admin()));

drop policy if exists "admin delete Godwin product media" on storage.objects;
create policy "admin delete Godwin product media" on storage.objects
for delete to authenticated using (bucket_id = 'product-media' and (select public.is_godwin_admin()));
