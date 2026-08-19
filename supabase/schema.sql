-- VetEstimator: anonymous estimate submissions
-- Run this once in the Supabase SQL Editor (Project → SQL Editor → New query).

create table if not exists public.estimates (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),

  species text not null check (species in ('dog', 'cat', 'other')),
  weight numeric not null check (weight > 0),
  tier text not null check (tier in ('small', 'medium', 'large')),
  gender text not null check (gender in ('male', 'female')),
  region text not null check (region in ('metro', 'city', 'rural')),
  emergency boolean not null default false,
  hospital_days integer not null default 0 check (hospital_days >= 0),

  -- [{ "key": "scaling", "label": "스케일링 (치석제거)", "min": 200000, "max": 300000 }, ...]
  selected_items jsonb not null default '[]'::jsonb,

  subtotal_min integer not null,
  subtotal_max integer not null,
  total_min integer not null,
  total_max integer not null
);

comment on table public.estimates is 'Anonymous submissions from the vet cost estimator, logged when a visitor saves their result as an image.';

alter table public.estimates enable row level security;

-- Anyone using the public anon key may insert a row (this is a public-facing
-- form). No select/update/delete policy is defined for anon, so RLS denies
-- those by default — only readable from the Supabase dashboard or a
-- service_role key, never from the browser.
create policy "Anonymous users can submit estimates"
  on public.estimates
  for insert
  to anon
  with check (true);


-- Migration 2: actual-price feedback
-- Run this in the SQL Editor if the `estimates` table above already exists.
-- Visitors can optionally report what they actually paid after their vet
-- visit; this is a separate insert (same table) rather than an update,
-- since the anon key intentionally has no update/select permission.

alter table public.estimates
  add column if not exists actual_price integer check (actual_price is null or actual_price >= 0),
  add column if not exists comparison text check (comparison is null or comparison in ('cheaper', 'similar', 'more_expensive'));
