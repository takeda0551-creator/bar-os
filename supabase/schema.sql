-- BAR OS shared-data foundation. Run in Supabase SQL Editor after creating a private project.
create extension if not exists pgcrypto;
create table if not exists public.shops(id uuid primary key default gen_random_uuid(),name text not null);
create table if not exists public.shop_members(shop_id uuid not null references public.shops(id),user_id uuid not null references auth.users(id),role text not null check(role in ('owner','manager','staff')),display_name text not null,primary key(shop_id,user_id));
create table if not exists public.seats(id uuid primary key default gen_random_uuid(),shop_id uuid not null references public.shops(id),name text not null,unique(shop_id,name));
create table if not exists public.products(id uuid primary key default gen_random_uuid(),shop_id uuid not null references public.shops(id),name text not null,category text not null,price_yen integer not null check(price_yen>=0),cost_yen integer not null default 0 check(cost_yen>=0),stock numeric(12,3) not null default 0,active boolean not null default true);
create table if not exists public.tabs(id uuid primary key default gen_random_uuid(),shop_id uuid not null references public.shops(id),seat_id uuid references public.seats(id),guest_count integer not null check(guest_count>=0),opened_at timestamptz not null default now(),closed_at timestamptz,status text not null default 'open' check(status in ('open','closed')));
create table if not exists public.order_lines(id uuid primary key default gen_random_uuid(),tab_id uuid not null references public.tabs(id),product_id uuid references public.products(id),description text not null,unit_price_yen integer not null,unit_cost_yen integer not null default 0,quantity integer not null check(quantity>0),created_by uuid references auth.users(id),created_at timestamptz not null default now());
create table if not exists public.payments(id uuid primary key default gen_random_uuid(),tab_id uuid not null references public.tabs(id),amount_yen integer not null check(amount_yen>0),method text not null check(method in ('cash','card','other')),received_by uuid references auth.users(id),received_at timestamptz not null default now());
create table if not exists public.shifts(id uuid primary key default gen_random_uuid(),shop_id uuid not null references public.shops(id),user_id uuid not null references auth.users(id),clock_in timestamptz not null,clock_out timestamptz,hourly_wage_yen integer not null default 0 check(hourly_wage_yen>=0),check(clock_out is null or clock_out>=clock_in));
create table if not exists public.audit_events(id uuid primary key default gen_random_uuid(),shop_id uuid not null references public.shops(id),actor uuid references auth.users(id),action text not null,entity_type text not null,entity_id uuid,before_data jsonb,after_data jsonb,reason text,created_at timestamptz not null default now());
create index if not exists idx_tabs_shop on public.tabs(shop_id,status);
create index if not exists idx_shifts_shop on public.shifts(shop_id,clock_in);
create index if not exists idx_audit_shop on public.audit_events(shop_id,created_at desc);
-- Deny all client access until server-side shop membership RLS policies are installed.
alter table public.shops enable row level security;
alter table public.shop_members enable row level security;
alter table public.seats enable row level security;
alter table public.products enable row level security;
alter table public.tabs enable row level security;
alter table public.order_lines enable row level security;
alter table public.payments enable row level security;
alter table public.shifts enable row level security;
alter table public.audit_events enable row level security;
-- No policies intentionally: secure-by-default, not yet wired to app.
