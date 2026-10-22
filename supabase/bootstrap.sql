-- Springfield Concrete Group - build a FRESH Supabase database in one go.
--
-- GENERATED from supabase/archive/*.sql (in the order in archive/README.md) followed by
-- supabase/migrations/*.sql. Do not edit by hand; edit the source files instead.
--
-- Run ONCE, on a brand-new, empty Supabase project: SQL Editor -> New query -> paste -> Run.
-- It is one transaction, so it either all applies or nothing does.
-- Never run it on a database that already has data: several archive files rewrite rows
-- (see archive/README.md, "Destructive to re-run").
--
-- Creates: every public table, function, trigger, RLS policy and grant the app uses, plus the
-- private storage buckets `quote-uploads` and `agreements`.
-- Does NOT create your owner login: see SETUP.md, step "Create your owner account".

begin;


-- ═════ archive/schema.sql ═════
-- Springfield Concrete Group - quote request storage
-- Run this once in your Supabase project: Dashboard → SQL Editor → New query → paste → Run.
-- Safe to re-run: every statement is idempotent.

-- ── 1. Leads table ──────────────────────────────────────────────────────────
create table if not exists public.quote_requests (
  id             uuid primary key default gen_random_uuid(),
  created_at     timestamptz not null default now(),
  name           text not null,
  phone          text not null,
  email          text,
  service        text,
  address        text,
  city           text,
  details        text,
  quote_type     text,        -- 'online' or 'inperson'
  preferred_time text,        -- in-person scheduling preference
  file_urls      jsonb,       -- array of uploaded photo/video URLs (online quotes)
  source_path    text
);

-- If the table already existed from an earlier version, add the new columns.
alter table public.quote_requests add column if not exists email text;
alter table public.quote_requests add column if not exists quote_type text;
alter table public.quote_requests add column if not exists preferred_time text;
alter table public.quote_requests add column if not exists file_urls jsonb;

-- Row Level Security: lock the table, then allow ONLY anonymous inserts.
-- The public site adds leads with the anon key but cannot read, edit or delete
-- them. You read leads in the Supabase dashboard (or with the service-role key).
alter table public.quote_requests enable row level security;

-- The PUBLIC (anon) role gets NO direct access to this table - it cannot read,
-- insert, update or delete. All writes go through the server route /api/quote,
-- which uses the secret service-role key (and re-validates every field). This
-- keeps customer leads safe from scraping and spam straight from the browser.
drop policy if exists "anon can insert quote requests" on public.quote_requests;
revoke all on public.quote_requests from anon;

-- The trusted server role (used ONLY by /api/quote with the secret service_role
-- key, never exposed to the browser) needs table privileges to write/read leads.
-- This is required because the project's default grants didn't cover this table.
grant insert, select on public.quote_requests to service_role;

-- Defense in depth: even a privileged writer must pass these checks, so junk
-- or oversized data can never land in the table.
alter table public.quote_requests drop constraint if exists qr_chk;
alter table public.quote_requests add constraint qr_chk check (
  char_length(name) between 1 and 120
  and char_length(phone) between 7 and 32
  and (email is null or (char_length(email) <= 200 and email ~* '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'))
  and (service is null or char_length(service) <= 120)
  and (address is null or char_length(address) <= 300)
  and (city is null or char_length(city) <= 120)
  and (details is null or char_length(details) <= 2000)
  and (preferred_time is null or char_length(preferred_time) <= 120)
  and (quote_type is null or quote_type in ('online', 'inperson'))
  and (file_urls is null or jsonb_typeof(file_urls) = 'array')
);

-- ── 2. Storage bucket for customer photos / videos (PRIVATE) ─────────────────
-- Private bucket: files are NOT publicly accessible. The site stores each file's
-- path on the lead row (file_urls); you view the photos in the Supabase
-- dashboard (Storage → quote-uploads) or via a signed URL. The `do update`
-- flips an already-created bucket to private.
insert into storage.buckets (id, name, public)
values ('quote-uploads', 'quote-uploads', false)
on conflict (id) do update set public = false;

-- Cap uploads at 50MB (plenty for high-res / HEIC phone photos and the short
-- clips a phone produces; uploads are mostly images) and only allow photo/video
-- types, including HEIC/HEIF and .mov.
-- NOTE: Supabase also has a project-wide "Global file size limit" under
-- Storage → Settings; keep it at or above 50MB.
update storage.buckets
set file_size_limit = 52428800,
    allowed_mime_types = array[
      'image/jpeg','image/png','image/webp','image/heic','image/heif','image/heic-sequence','image/heif-sequence','image/gif',
      'video/mp4','video/quicktime','video/webm','video/3gpp'
    ]
where id = 'quote-uploads';

-- Storage access model: the browser gets NO blanket write access. Customer
-- photos are uploaded with a one-time, single-object SIGNED upload URL minted
-- server-side by /api/upload-url (rate-limited + type-checked). The signed
-- token authorizes that one PUT, so there is no standing anon insert policy to
-- abuse. Reads stay private (no anon select policy); staff view files through
-- the authenticated /crm/api/file proxy. Remove the old broad policy if present.
drop policy if exists "anon can upload quote files" on storage.objects;

-- ═════ archive/crm.sql ═════
-- Springfield Concrete Group - CRM extension
-- Run this AFTER schema.sql, once, in Supabase → SQL Editor. Safe to re-run.
--
-- Adds: staff (owner + contractors), CRM columns on quote_requests (status,
-- assignment, customer/job tokens, view tracking, quote amount), an activity
-- log, and Row-Level Security so a contractor can only ever see jobs assigned to
-- them. The public marketing site and the customer/job token pages never touch
-- these tables directly - those go through server code with the service-role key.

-- ── 1. Staff (one row per Supabase Auth user) ───────────────────────────────
create table if not exists public.staff (
  id         uuid primary key references auth.users(id) on delete cascade,
  email      text,
  full_name  text,
  phone      text,
  role       text not null default 'contractor' check (role in ('owner', 'contractor')),
  active     boolean not null default true,
  created_at timestamptz not null default now()
);

-- New contractors get a temporary password and must set their own on first login.
alter table public.staff add column if not exists must_reset_password boolean not null default false;

alter table public.staff enable row level security;

-- Is the current logged-in user an active owner? SECURITY DEFINER so the policy
-- can read staff without recursing through staff's own RLS.
create or replace function public.is_owner()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.staff s
    where s.id = auth.uid() and s.role = 'owner' and s.active
  );
$$;

drop policy if exists "staff self or owner read" on public.staff;
create policy "staff self or owner read" on public.staff
  for select to authenticated
  using (id = auth.uid() or public.is_owner());

drop policy if exists "owner manages staff" on public.staff;
create policy "owner manages staff" on public.staff
  for all to authenticated
  using (public.is_owner())
  with check (public.is_owner());

grant select, insert, update, delete on public.staff to authenticated;
grant all on public.staff to service_role;

-- New auth users get a contractor staff row that is INACTIVE by default. An
-- owner must explicitly activate it (Staff settings, or flip active = true)
-- before that person can sign in. This means a stray/self-service Supabase
-- signup can never reach the CRM on its own. Promote yourself to owner with the
-- snippet at the bottom of this file (that snippet sets active = true for you).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.staff (id, email, full_name, role, active)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'full_name', ''), 'contractor', false)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ── 2. CRM columns on quote_requests ────────────────────────────────────────
alter table public.quote_requests add column if not exists status         text not null default 'new';
alter table public.quote_requests add column if not exists assigned_to    uuid references public.staff(id) on delete set null;
alter table public.quote_requests add column if not exists quote_amount   numeric(10, 2);
alter table public.quote_requests add column if not exists quote_summary  text;
alter table public.quote_requests add column if not exists internal_notes text;
alter table public.quote_requests add column if not exists public_token   text;
alter table public.quote_requests add column if not exists job_token      text;
alter table public.quote_requests add column if not exists viewed_at      timestamptz;
alter table public.quote_requests add column if not exists view_count     integer not null default 0;
alter table public.quote_requests add column if not exists quote_sent_at  timestamptz;
alter table public.quote_requests add column if not exists updated_at     timestamptz not null default now();

-- Customer self-service from the branded quote page: accept (with a scheduled
-- date) or decline, plus whether they took the 10%-off save offer.
alter table public.quote_requests add column if not exists customer_response     text;
alter table public.quote_requests add column if not exists customer_responded_at timestamptz;
alter table public.quote_requests add column if not exists scheduled_date        date;
alter table public.quote_requests add column if not exists discount_accepted     boolean not null default false;

-- In-person quote appointment the customer picked (so the crew can calendar it).
-- scheduled_date = the booked WORK day (max 1/day); visit_date = an in-person
-- quote visit (max 5/day). Both are enforced in server code.
alter table public.quote_requests add column if not exists visit_date  date;
alter table public.quote_requests add column if not exists visit_time  text;

-- Google Calendar event id, so we can update/cancel the invite we created for a
-- booked job or an in-person quote visit (see lib/crm/gcal.ts).
alter table public.quote_requests add column if not exists gcal_event_id text;

-- Job lifecycle timestamps: the 2-day confirmation reminder, the customer's
-- confirmation, when work was completed on site, when we asked for payment, and
-- when the money landed (Zelle / deposit).
alter table public.quote_requests add column if not exists reminder_sent_at     timestamptz;
alter table public.quote_requests add column if not exists confirmed_at         timestamptz;
alter table public.quote_requests add column if not exists completed_at         timestamptz;
alter table public.quote_requests add column if not exists payment_requested_at timestamptz;
alter table public.quote_requests add column if not exists paid_at              timestamptz;

-- Soft delete: "deleting" a lead from the CRM only sets this timestamp. The row
-- (and every related quote_event) stays in the database untouched - listQuotes
-- just hides archived rows from the pipeline/customers views by default, and
-- an owner can restore one from /crm/archived. Nothing is ever hard-deleted.
alter table public.quote_requests add column if not exists archived_at timestamptz;
create index if not exists qr_archived_idx on public.quote_requests(archived_at);

create index if not exists qr_scheduled_date_idx on public.quote_requests(scheduled_date);
create index if not exists qr_visit_date_idx      on public.quote_requests(visit_date);
-- Hard guarantee: at most one accepted/booked job per calendar day.
create unique index if not exists qr_one_job_per_day
  on public.quote_requests (scheduled_date)
  where customer_response = 'accepted';

alter table public.quote_requests drop constraint if exists qr_customer_response_chk;
alter table public.quote_requests add constraint qr_customer_response_chk
  check (customer_response is null or customer_response in ('accepted', 'declined'));

-- Simplified pipeline: New -> Quoted -> Scheduled -> Completed -> Paid (+ Lost).
-- Confirmation is a flag (confirmed_at) on a Scheduled job, not its own stage.
-- Migrate any rows still using older labels before tightening the constraint.
alter table public.quote_requests drop constraint if exists qr_status_chk;
update public.quote_requests set status = 'new'       where status = 'assigned';
update public.quote_requests set status = 'quoted'    where status in ('sent', 'viewed');
update public.quote_requests set status = 'scheduled' where status in ('won', 'booked', 'confirmed');
update public.quote_requests set status = 'completed' where status = 'complete';
alter table public.quote_requests add constraint qr_status_chk
  check (status in ('new', 'quoted', 'scheduled', 'completed', 'paid', 'lost'));

-- Unguessable capability tokens for the customer quote view and the contractor
-- job/photos view. Backfill existing rows, then default new rows.
update public.quote_requests set public_token = replace(gen_random_uuid()::text, '-', '') where public_token is null;
update public.quote_requests set job_token    = replace(gen_random_uuid()::text, '-', '') where job_token is null;
alter table public.quote_requests alter column public_token set default replace(gen_random_uuid()::text, '-', '');
alter table public.quote_requests alter column job_token    set default replace(gen_random_uuid()::text, '-', '');
create unique index if not exists qr_public_token_idx on public.quote_requests(public_token);
create unique index if not exists qr_job_token_idx    on public.quote_requests(job_token);
create index if not exists qr_assigned_idx on public.quote_requests(assigned_to);
create index if not exists qr_status_idx   on public.quote_requests(status);

-- Keep updated_at fresh on every change.
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists qr_touch_updated_at on public.quote_requests;
create trigger qr_touch_updated_at
  before update on public.quote_requests
  for each row execute function public.touch_updated_at();

-- The server role needs UPDATE too (customer-view tracking on the public quote
-- page bumps view_count / status via the service-role key).
grant insert, select, update on public.quote_requests to service_role;

-- Staff read scoping: owners see everything, contractors see only their jobs.
grant select, update on public.quote_requests to authenticated;

drop policy if exists "staff read quotes" on public.quote_requests;
create policy "staff read quotes" on public.quote_requests
  for select to authenticated
  using (public.is_owner() or assigned_to = auth.uid());

drop policy if exists "owner updates quotes" on public.quote_requests;
create policy "owner updates quotes" on public.quote_requests
  for update to authenticated
  using (public.is_owner())
  with check (public.is_owner());

-- Contractors may update a job that is assigned to them, but cannot reassign it
-- away from themselves (the WITH CHECK keeps assigned_to = their id).
drop policy if exists "contractor updates assigned" on public.quote_requests;
create policy "contractor updates assigned" on public.quote_requests
  for update to authenticated
  using (assigned_to = auth.uid())
  with check (assigned_to = auth.uid());

-- ── 3. Activity log ─────────────────────────────────────────────────────────
create table if not exists public.quote_events (
  id         uuid primary key default gen_random_uuid(),
  quote_id   uuid not null references public.quote_requests(id) on delete cascade,
  type       text not null,
  meta       jsonb,
  actor      uuid references public.staff(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists qe_quote_idx on public.quote_events(quote_id);
alter table public.quote_events enable row level security;
grant select, insert on public.quote_events to authenticated;
grant all on public.quote_events to service_role;

drop policy if exists "staff read events" on public.quote_events;
create policy "staff read events" on public.quote_events
  for select to authenticated
  using (
    public.is_owner()
    or exists (
      select 1 from public.quote_requests q
      where q.id = quote_events.quote_id and q.assigned_to = auth.uid()
    )
  );

drop policy if exists "staff insert events" on public.quote_events;
create policy "staff insert events" on public.quote_events
  for insert to authenticated
  with check (
    public.is_owner()
    or exists (
      select 1 from public.quote_requests q
      where q.id = quote_events.quote_id and q.assigned_to = auth.uid()
    )
  );

-- ── 3b. Integrations (Google Calendar OAuth tokens, etc.) ───────────────────
-- Singleton-ish key/value store for third-party tokens. Only ever touched by
-- server code with the service-role key - no authenticated grants, RLS on with
-- no policies so a logged-in user can never read the refresh token.
create table if not exists public.app_integrations (
  provider   text primary key,
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.app_integrations enable row level security;
grant all on public.app_integrations to service_role;

-- ── 3c. Login attempts (owner-visible security log) ─────────────────────────
-- Every POST to /crm/api/login writes one row here, success or failure, with
-- the service-role key (there's no user session yet at login time). Owners can
-- read it from the CRM Security dashboard; nothing else can touch it.
create table if not exists public.login_attempts (
  id         uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  email      text,
  success    boolean not null,
  reason     text not null,
  staff_id   uuid references public.staff(id) on delete set null,
  ip         text,
  user_agent text
);
create index if not exists la_created_idx on public.login_attempts(created_at desc);
create index if not exists la_email_idx   on public.login_attempts(email);
create index if not exists la_ip_idx      on public.login_attempts(ip);

alter table public.login_attempts enable row level security;
grant all on public.login_attempts to service_role;
grant select on public.login_attempts to authenticated;

drop policy if exists "owner reads login attempts" on public.login_attempts;
create policy "owner reads login attempts" on public.login_attempts
  for select to authenticated
  using (public.is_owner());

-- ── 4. One-time: make yourself the owner ────────────────────────────────────
-- Passwords live in Supabase Auth (auth.users), NOT in this table - never add a
-- password column here.
-- 1) Supabase → Authentication → Users → "Add user" → set your email + password
--    and CHECK "Auto Confirm User" (an unconfirmed email can't sign in).
-- 2) Then run this (replace the email + your name). It links your auth user to a
--    staff row and flips it to owner:
--
insert into public.staff (id, email, full_name, role, active)
select id, email, 'Your Name', 'owner', true
from auth.users
where email = 'you@example.com'
on conflict (id) do update set role = 'owner', active = true;

-- ═════ archive/agreements.sql ═════
-- Springfield Concrete Group - signed agreements
-- Run this AFTER crm.sql, once, in Supabase → SQL Editor. Safe to re-run.
--
-- Stores the contracts you send out through DocuSeal. DocuSeal itself is managed
-- separately (you build the template there, it emails the signer, and the signer
-- signs on DocuSeal's hosted page). This table is the CRM-side record: what was
-- sent, to whom, where it stands, an optional link back to the DocuSeal
-- submission, and the signed PDF once you download it.
--
-- Two kinds:
--   contractor - one onboarding agreement per crew member (staff_id)
--   customer - one agreement per job (quote_id)

-- ── 1. Private bucket for contract files ────────────────────────────────────
-- Private, exactly like quote-uploads: no anon read/write policy exists, so the
-- only way to see a contract is through the authenticated CRM proxy at
-- /crm/api/agreement, which scopes access with RLS.
insert into storage.buckets (id, name, public)
values ('agreements', 'agreements', false)
on conflict (id) do update set public = false;

-- 25MB is plenty for a signed contract; PDFs plus scans/photos of a wet-ink copy.
update storage.buckets
set file_size_limit = 26214400,
    allowed_mime_types = array['application/pdf', 'image/jpeg', 'image/png', 'image/heic', 'image/webp']
where id = 'agreements';

-- ── 2. Agreements table ─────────────────────────────────────────────────────
create table if not exists public.agreements (
  id           uuid primary key default gen_random_uuid(),
  kind         text not null check (kind in ('contractor', 'customer')),
  -- Exactly one of these is set, enforced by agreements_target_chk below.
  staff_id     uuid references public.staff(id) on delete cascade,
  quote_id     uuid references public.quote_requests(id) on delete cascade,
  title        text not null,
  status       text not null default 'pending'
               check (status in ('pending', 'sent', 'signed', 'declined', 'void')),
  file_path    text,
  docuseal_url text,
  sent_at      timestamptz,
  signed_at    timestamptz,
  notes        text,
  created_by   uuid references public.staff(id) on delete set null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- A contractor agreement hangs off a staff row; a customer agreement off a job.
-- Never both, never neither - otherwise the RLS policies below can't scope it.
alter table public.agreements drop constraint if exists agreements_target_chk;
alter table public.agreements add constraint agreements_target_chk
  check (
    (kind = 'contractor' and staff_id is not null and quote_id is null)
    or
    (kind = 'customer' and quote_id is not null and staff_id is null)
  );

create index if not exists ag_staff_idx   on public.agreements(staff_id);
create index if not exists ag_quote_idx   on public.agreements(quote_id);
create index if not exists ag_status_idx  on public.agreements(status);
create index if not exists ag_created_idx on public.agreements(created_at desc);

alter table public.agreements enable row level security;
grant select, insert, update, delete on public.agreements to authenticated;
grant all on public.agreements to service_role;

-- Owners see and manage everything. A contractor sees only their own onboarding
-- agreement and the customer agreements for jobs assigned to them - the same
-- scoping rule the rest of the CRM uses.
drop policy if exists "staff read agreements" on public.agreements;
create policy "staff read agreements" on public.agreements
  for select to authenticated
  using (
    public.is_owner()
    or staff_id = auth.uid()
    or exists (
      select 1 from public.quote_requests q
      where q.id = agreements.quote_id and q.assigned_to = auth.uid()
    )
  );

-- Only owners create, edit or delete agreements. Contractors are read-only here:
-- they sign in DocuSeal, they don't change the CRM record.
drop policy if exists "owner writes agreements" on public.agreements;
create policy "owner writes agreements" on public.agreements
  for all to authenticated
  using (public.is_owner())
  with check (public.is_owner());

-- Keep updated_at honest.
create or replace function public.touch_agreements_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists agreements_touch_updated_at on public.agreements;
create trigger agreements_touch_updated_at
  before update on public.agreements
  for each row execute function public.touch_agreements_updated_at();

-- ═════ archive/invites.sql ═════
-- Springfield Concrete Group - contractor invites
-- Run this AFTER crm.sql, once, in Supabase → SQL Editor. Safe to re-run.
--
-- Instead of the owner typing a contractor's details in by hand, they text an
-- invite to one phone number. That link opens a public onboarding form where the
-- contractor fills in their own name/email and chooses their own password, which
-- creates their account.
--
-- The token is the only thing protecting that form, so it is treated like a
-- capability: long and random, single-use, and short-lived.

create table if not exists public.contractor_invites (
  id         uuid primary key default gen_random_uuid(),
  -- 32 hex chars from gen_random_uuid(), same shape as the customer/job tokens.
  token      text not null unique,
  -- E.164, the only number this invite was ever sent to.
  phone      text not null,
  full_name  text,
  created_by uuid references public.staff(id) on delete set null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  -- Set the moment an account is created from it; a used invite is dead.
  used_at    timestamptz,
  used_by    uuid references public.staff(id) on delete set null,
  revoked_at timestamptz
);

create index if not exists ci_token_idx   on public.contractor_invites(token);
create index if not exists ci_created_idx on public.contractor_invites(created_at desc);

alter table public.contractor_invites enable row level security;
grant all on public.contractor_invites to service_role;
grant select on public.contractor_invites to authenticated;

-- Owners can see the invites they've sent. Nobody else has any access, and the
-- public onboarding form never runs as a user - it goes through server code with
-- the service-role key, which is what lets an unauthenticated visitor redeem a
-- token without opening this table up.
drop policy if exists "owner reads invites" on public.contractor_invites;
create policy "owner reads invites" on public.contractor_invites
  for select to authenticated
  using (public.is_owner());

-- ═════ archive/invite-tracking.sql ═════
-- Springfield Concrete Group - contractor invite tracking
-- Run this AFTER invites.sql, once, in Supabase → SQL Editor. Safe to re-run.
--
-- Adds the missing middle step. Before this an invite was only "pending" or
-- "used", which can't tell "they never opened the link" from "they opened it and
-- got stuck" - and those need completely different follow-ups from the owner.

alter table public.contractor_invites add column if not exists opened_at timestamptz;

-- How many times the link was opened. A repeated open with no account at the end
-- usually means something on the form is blocking them.
alter table public.contractor_invites add column if not exists open_count integer not null default 0;

-- ═════ archive/locale.sql ═════
-- Springfield Concrete Group - CRM language preference
-- Run this AFTER crm.sql, once, in Supabase → SQL Editor. Safe to re-run.
--
-- Each staff member picks the language the CRM renders in. Stored on the staff
-- row rather than a cookie so it follows them to any device they sign in from,
-- which matters for crew who mostly use a phone.

alter table public.staff add column if not exists locale text not null default 'en';

alter table public.staff drop constraint if exists staff_locale_chk;
alter table public.staff add constraint staff_locale_chk
  check (locale in ('en', 'es'));

-- ═════ archive/quote-detail.sql ═════
-- Springfield Concrete Group - structured quotes, link expiry, service routing,
-- and job photos.
-- Run this in Supabase → SQL Editor. Safe to re-run (every statement is
-- idempotent).

-- ── 1. The five sections every quote covers ────────────────────────────────
-- Replaces the single free-text quote_summary as the thing the customer
-- reads. quote_summary is deliberately left in place: existing quotes still
-- have their text in it, and the customer page falls back to it for any quote
-- sent before this migration.
--
-- Each section is required before a quote can be sent, but "Not applicable"
-- is a valid answer - a slab replacement with no permit and nothing to
-- demolish should say so rather than leave the customer wondering what we
-- left out.
alter table public.quote_requests add column if not exists quote_scope text;
alter table public.quote_requests add column if not exists quote_permits text;
alter table public.quote_requests add column if not exists quote_prep text;
alter table public.quote_requests add column if not exists quote_pour text;
alter table public.quote_requests add column if not exists quote_cleanup text;

-- One cap for all five. quote_summary never had one (the 4000-char slice in
-- saveQuote was the only limit); these get a real constraint so a paste
-- accident can't put a novel on the customer's quote page.
alter table public.quote_requests drop constraint if exists qr_sections_chk;
alter table public.quote_requests add constraint qr_sections_chk check (
  (quote_scope    is null or char_length(quote_scope)    <= 2000)
  and (quote_permits is null or char_length(quote_permits) <= 2000)
  and (quote_prep    is null or char_length(quote_prep)    <= 2000)
  and (quote_pour    is null or char_length(quote_pour)    <= 2000)
  and (quote_cleanup is null or char_length(quote_cleanup) <= 2000)
);

-- ── 2. Quote links expire ──────────────────────────────────────────────────
-- Set to seven days out whenever the quote is sent, and re-set whenever it is
-- sent again, so a re-send is what revives an expired link. Null means "no
-- expiry recorded" - every quote sent before this migration, which the app
-- treats as still valid rather than retroactively killing live links.
alter table public.quote_requests add column if not exists quote_expires_at timestamptz;

-- ── 3. Job photos ──────────────────────────────────────────────────────────
-- file_urls holds what the CUSTOMER sent with their request and is written by
-- the public form. These three are ours:
--
--   internal_urls  reference photos staff add from the CRM after the fact
--   before_urls    the site before work started
--   after_urls     the finished work - required to mark a job complete, so
--                  there is always a record of what was handed over
alter table public.quote_requests add column if not exists internal_urls text[];
alter table public.quote_requests add column if not exists before_urls text[];
alter table public.quote_requests add column if not exists after_urls text[];

-- ── 4. Which job types each contractor takes ───────────────────────────────
-- Drives auto-assignment for both web and call-in leads. Null or empty means
-- "no restriction" - they can take anything, which is what every existing
-- contractor should keep doing until an owner says otherwise. Values are the
-- customer-facing service names from quoteServiceOptions (src/lib/site-data.ts),
-- matched case-insensitively because `service` is free text on the wire.
alter table public.staff add column if not exists service_types text[];

-- ═════ archive/hourly-reminders.sql ═════
-- Springfield Concrete Group - reminder tracking (stale leads, quote visits, follow-ups)
-- Run this in Supabase → SQL Editor. Safe to re-run (every statement is
-- "if not exists").
--
-- Backs the extra jobs in /api/cron/reminders (stale lead nudge, 48h quote
-- follow-up) and /api/cron/visit-reminders (night-before quote visit). Each
-- is a one-shot per row, tracked the same way reminder_sent_at already is: a
-- null timestamp means "not sent yet", set once and never cleared.
--
-- stale_lead_reminded_at    a new lead nobody has quoted or scheduled a visit
--                           for, 12+ hours old. Cleared never - once a lead
--                           moves past status "new" it stops qualifying anyway.
--
-- visit_reminder_sent_at    the customer's night-before reminder for their
--                           in-person quote visit (separate from
--                           reminder_sent_at, which is the 2-day heads-up for a
--                           booked WORK day, not a quote visit).
--
-- visit_crew_reminded_at    the assigned contractor's night-before reminder
--                           for the same quote visit. Separate from
--                           crew_reminders (which counts down a booked work
--                           day) because a quote visit only ever gets one
--                           reminder, the night before - no 3-day or
--                           morning-of stage.
--
-- quote_followup_sent_at    a sent quote nobody has accepted or declined,
--                           48+ hours later.

alter table public.quote_requests add column if not exists stale_lead_reminded_at timestamptz;
alter table public.quote_requests add column if not exists visit_reminder_sent_at timestamptz;
alter table public.quote_requests add column if not exists visit_crew_reminded_at timestamptz;
alter table public.quote_requests add column if not exists quote_followup_sent_at timestamptz;

-- ═════ archive/manual-quote.sql ═════
-- Springfield Concrete Group - let an owner create a lead themselves
-- Run this in Supabase → SQL Editor. Safe to re-run.
--
-- Every quote_requests row so far has come from the public /api/quote
-- endpoint (service role, no session). This adds the missing insert grant +
-- RLS policy for the CRM's own "log a call-in lead" form, which runs as the
-- signed-in staff member (pgUser), not the service role. Owner-only, same as
-- the existing "owner updates quotes" policy below it - contractors can't
-- create leads, only work the ones assigned to them. Uses the same
-- public.is_owner() helper that policy already relies on.

grant insert on public.quote_requests to authenticated;

drop policy if exists "staff insert quotes" on public.quote_requests;
create policy "owner inserts quotes" on public.quote_requests
  for insert to authenticated
  with check (public.is_owner());

-- ═════ archive/scheduling.sql ═════
-- Springfield Concrete Group - approval / scheduling split
-- Run this AFTER crm.sql, once, in Supabase → SQL Editor. Safe to re-run.
--
-- Before: a customer accepting their quote also picked the install date, which
-- committed the crew to a day nobody had checked. After: accepting records the
-- approval and the customer's PREFERRED days, the job parks in a new "approved"
-- stage, and the assigned contractor (or an owner) confirms the real date.
--
-- Note on qr_one_job_per_day: it's a unique index on scheduled_date where
-- customer_response = 'accepted'. Approved-but-unscheduled rows have a NULL
-- date, and Postgres allows many NULLs in a unique index, so they coexist fine
-- while the one-job-per-day rule still holds for confirmed dates.

-- ── 1. New pipeline stage ───────────────────────────────────────────────────
-- new -> quoted -> approved (needs scheduling) -> scheduled -> completed -> paid
alter table public.quote_requests drop constraint if exists qr_status_chk;
alter table public.quote_requests add constraint qr_status_chk
  check (status in ('new', 'quoted', 'approved', 'scheduled', 'completed', 'paid', 'lost'));

-- Any job the customer already accepted but that has no date yet belongs in the
-- new stage, so nothing approved is left sitting invisibly in "scheduled".
update public.quote_requests
set status = 'approved'
where customer_response = 'accepted'
  and scheduled_date is null
  and status = 'scheduled';

-- ── 2. Customer's preferred days ────────────────────────────────────────────
-- Up to three ISO dates (YYYY-MM-DD) the customer said work for them. Stored as
-- text[] to match how file_urls is handled elsewhere.
alter table public.quote_requests add column if not exists preferred_dates text[];

-- Who confirmed the date and when, so the job page can show it and a reschedule
-- can be told apart from the first booking.
alter table public.quote_requests add column if not exists scheduled_by uuid references public.staff(id) on delete set null;
alter table public.quote_requests add column if not exists scheduled_at timestamptz;

-- ═════ archive/scheduled-time.sql ═════
-- Springfield Concrete Group - appointment time on booked jobs
-- Run this AFTER scheduling.sql, once, in Supabase → SQL Editor. Safe to re-run.
--
-- Jobs were booked to a DAY only, so "your project is confirmed" couldn't tell
-- the customer when to expect the crew. The crew now picks a start time when
-- they confirm the day, and it rides through rescheduling, the confirmation
-- texts and the 2-day reminder.
--
-- Text rather than a time column, matching visit_time: it's display copy
-- ("9:00 AM"), never arithmetic.

alter table public.quote_requests add column if not exists scheduled_time text;

-- ═════ archive/crew-reminders.sql ═════
-- Springfield Concrete Group - appointment time + crew reminder tracking
-- Run this in Supabase → SQL Editor. Safe to re-run, and safe to run even if
-- you already ran scheduled-time.sql (both statements are "if not exists").
--
-- RUN THIS ONE FILE and both columns below exist. If confirming a work day is
-- showing "Could not save that date", it's because scheduled_time is missing.
--
-- scheduled_time  the crew's start time for a booked day, e.g. "9:00 AM".
--                 Text rather than a time column, matching visit_time: it's
--                 display copy, never arithmetic.
--
-- crew_reminders  which countdown texts the crew has already had for this
--                 booking: '3' (three days out), '1' (day before), '0' (the
--                 morning of). An array rather than three timestamp columns so
--                 changing the schedule is a constant in the code, not another
--                 migration. Confirming or moving a date clears it, so the new
--                 date gets its own full run of reminders.

alter table public.quote_requests add column if not exists scheduled_time text;
alter table public.quote_requests add column if not exists crew_reminders text[];

-- ═════ archive/appointments.sql ═════
-- Springfield Concrete Group - back-to-back quote visits + per-contractor hours
-- Run this AFTER crm.sql, scheduling.sql and locale.sql, once, in Supabase →
-- SQL Editor. Safe to re-run.
--
-- Before: quote visits were five fixed slots two hours apart, capped at five a
-- day for the whole business, and the cap was checked against whoever happened
-- to be the primary contractor. A crew member with a free afternoon could not
-- be booked into it, and a busy one could be booked on top of.
--
-- After: a visit is an hourly slot on ONE contractor's day. They can run back
-- to back all day with an hour between each, and the only limits are that
-- contractor's own working window and the hour of clearance either side.
--
-- Booked WORK days are deliberately untouched: still one per calendar day for
-- the whole business, still guaranteed by qr_one_job_per_day in crm.sql. A pour
-- is a crew, a truck and a day; only the visits stack.

-- ── 1. Each contractor's working window ─────────────────────────────────────
-- Both hours are the hour a slot STARTS, so 8..16 is nine slots, 8:00 AM
-- through 4:00 PM. Editable per person under CRM → Settings → Working hours.
alter table public.staff add column if not exists work_start_hour int not null default 8;
alter table public.staff add column if not exists work_end_hour   int not null default 16;

-- Days of the week they take visits, 0=Sunday .. 6=Saturday.
--
-- Defaulted to all seven rather than Monday-Friday on purpose. Customers could
-- already book a Saturday visit, and shipping a migration that quietly cancels
-- weekend availability for every contractor at once is not a default, it is a
-- policy change nobody asked for. The preference starts as "no restriction".
alter table public.staff add column if not exists work_days int[] not null default '{0,1,2,3,4,5,6}';

alter table public.staff drop constraint if exists staff_work_hours_chk;
alter table public.staff add constraint staff_work_hours_chk
  check (
    work_start_hour between 5 and 21
    and work_end_hour between 5 and 21
    and work_end_hour >= work_start_hour
  );

-- ── 2. The time the customer asked for, per preferred day ───────────────────
-- Index-aligned with preferred_dates: preferred_times[i] is the start time the
-- customer wants on preferred_dates[i]. Text, like scheduled_time and
-- visit_time, because it is display copy ("9:00 AM") and never arithmetic.
--
-- Nullable and allowed to be shorter than preferred_dates: every quote accepted
-- before this column existed has days with no time against them, and the crew's
-- scheduling card falls back to its own default for those.
alter table public.quote_requests add column if not exists preferred_times text[];

-- ── 3. A lost job stops holding its day ─────────────────────────────────────
-- qr_one_job_per_day guarantees at most one accepted job per calendar day. It
-- did not exclude lost ones, so a customer who accepted, got a date and then
-- pulled out kept that day locked forever if the lead was dragged to Lost
-- rather than having its appointment cancelled - and no screen said why the
-- day was full. The app's own countJobsOn is widened to match.
--
-- Safe to run: the new index is strictly looser than the old one, so any data
-- the old one allowed the new one allows too.
drop index if exists public.qr_one_job_per_day;
create unique index if not exists qr_one_job_per_day
  on public.quote_requests (scheduled_date)
  where customer_response = 'accepted' and status <> 'lost';

-- ── Note on enforcement ─────────────────────────────────────────────────────
-- There is deliberately no unique index behind the one-hour gap. It is a
-- distance between start times rather than a repeated value, so it is not
-- expressible as uniqueness - and a contractor booking a 9:30 visit from their
-- job page has to block both the 9:00 and the 10:00 slot, which a unique index
-- on (assigned_to, visit_date, visit_time) would let straight through. Every
-- path that writes a visit date runs findVisitConflict first: the public quote
-- form, confirmVisit, rescheduleVisit and the calendar's drag-and-drop.

-- ═════ archive/quote-options.sql ═════
-- Springfield Concrete Group - quote line items the customer answers one by one
-- Run this AFTER crm.sql, once, in Supabase → SQL Editor. Safe to re-run.
--
-- Until now a quote was one price. That works for "pour this patio" and breaks
-- the moment a customer asks the question they always ask: "what would the
-- sidewalk cost while you're here?" The honest answer is two prices and a
-- choice, which a single quote_amount cannot hold - so it got handled over the
-- phone, off the record, and the crew found out on the day.
--
-- A quote may now carry line items. Each is either part of the base job or an
-- optional extra the customer says yes or no to, and the total is whatever they
-- said yes to. A quote with NO rows in this table behaves exactly as it always
-- has: one price, one accept/decline. Nothing existing changes.

create table if not exists public.quote_options (
  id          uuid primary key default gen_random_uuid(),
  quote_id    uuid not null references public.quote_requests(id) on delete cascade,
  -- What it is, e.g. "Back patio" or "Sidewalk to the driveway".
  title       text not null,
  -- What it includes. The five quote sections still cover the job as a whole;
  -- this is what is specific to this item.
  description text,
  amount      numeric(10, 2) not null default 0,
  -- Part of the base job (the customer cannot drop it) vs an extra they choose.
  -- Without this a customer could decline the driveway and accept the $800
  -- apron extension that only exists because of it.
  required    boolean not null default false,
  -- The order the customer reads them in, set by whoever wrote the quote.
  sort_order  int not null default 0,
  -- The customer's answer to THIS item. Null until they respond. A required
  -- item is written 'accepted' along with the rest when they approve.
  customer_response text,
  responded_at      timestamptz,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

alter table public.quote_options drop constraint if exists qo_chk;
alter table public.quote_options add constraint qo_chk check (
  char_length(title) between 1 and 120
  and (description is null or char_length(description) <= 2000)
  and amount >= 0 and amount <= 99999999
  and (customer_response is null or customer_response in ('accepted', 'declined'))
);

create index if not exists qo_quote_idx on public.quote_options(quote_id, sort_order);

drop trigger if exists qo_touch_updated_at on public.quote_options;
create trigger qo_touch_updated_at
  before update on public.quote_options
  for each row execute function public.touch_updated_at();

alter table public.quote_options enable row level security;
grant select, insert, update, delete on public.quote_options to authenticated;
grant all on public.quote_options to service_role;

-- Same scoping as the job itself, and for the same reason: a contractor writes
-- the quote for the jobs assigned to them, from their own job page, so read and
-- write travel together here rather than being split owner/crew.
--
-- One policy per command instead of one FOR ALL, because insert has no USING
-- row to test against - the row does not exist yet - and folding them together
-- is how an insert policy quietly ends up checking nothing.
drop policy if exists "staff read options" on public.quote_options;
create policy "staff read options" on public.quote_options
  for select to authenticated
  using (
    public.is_owner()
    or exists (
      select 1 from public.quote_requests q
      where q.id = quote_options.quote_id and q.assigned_to = auth.uid()
    )
  );

drop policy if exists "staff insert options" on public.quote_options;
create policy "staff insert options" on public.quote_options
  for insert to authenticated
  with check (
    public.is_owner()
    or exists (
      select 1 from public.quote_requests q
      where q.id = quote_options.quote_id and q.assigned_to = auth.uid()
    )
  );

drop policy if exists "staff update options" on public.quote_options;
create policy "staff update options" on public.quote_options
  for update to authenticated
  using (
    public.is_owner()
    or exists (
      select 1 from public.quote_requests q
      where q.id = quote_options.quote_id and q.assigned_to = auth.uid()
    )
  )
  with check (
    public.is_owner()
    or exists (
      select 1 from public.quote_requests q
      where q.id = quote_options.quote_id and q.assigned_to = auth.uid()
    )
  );

drop policy if exists "staff delete options" on public.quote_options;
create policy "staff delete options" on public.quote_options
  for delete to authenticated
  using (
    public.is_owner()
    or exists (
      select 1 from public.quote_requests q
      where q.id = quote_options.quote_id and q.assigned_to = auth.uid()
    )
  );

-- The customer's own answers are written by the token endpoint with the
-- service-role key (there is no session on /q/<token>), which the grant above
-- already covers. Nothing anonymous ever touches this table directly.

-- ═════ archive/quote-packages.sql ═════
-- Springfield Concrete Group - two ways to do the same job
-- Run this AFTER crm.sql and quote-options.sql, once, in Supabase → SQL Editor.
-- Safe to re-run.
--
-- quote-options.sql answered "what else would you like while we're here": a
-- list of things the customer says yes or no to, one at a time, and the total
-- follows. It cannot answer the other question customers ask, which is not
-- "and also" but "or instead":
--
--   "What would it cost in concrete, and what would it cost in asphalt?"
--
-- Those are not two line items. Adding both to one list would have the customer
-- buying a concrete driveway AND an asphalt one on the same patch of ground,
-- and the total would be the sum of two jobs only one of which is happening.
-- Until now the second price got quoted over the phone, or as a second quote on
-- a second link, and whichever one the customer answered was the one the crew
-- found out about.
--
-- A quote may now carry packages: complete, mutually exclusive ways of doing
-- the job. The customer picks exactly one. Line items (quote_options) keep
-- working exactly as they did and apply whichever package is chosen - the
-- tear-out, the extra sidewalk - so the two features compose instead of
-- competing.
--
-- A quote with NO rows in this table behaves exactly as it always has.

create table if not exists public.quote_packages (
  id          uuid primary key default gen_random_uuid(),
  quote_id    uuid not null references public.quote_requests(id) on delete cascade,
  -- What this way of doing it is called, e.g. "Concrete driveway".
  title       text not null,
  -- Why somebody would pick this one over the other. The five quote sections
  -- still cover how the job is run; this is what is specific to this choice.
  description text,
  -- What this way of doing it costs, on its own. Line items are added on top
  -- and are shared across every package, so this is the price of the work
  -- itself and not of the whole quote.
  amount      numeric(10, 2) not null default 0,
  -- The one the contractor would pick if it were their driveway. At most one
  -- per quote - the index below enforces it, because two recommendations is
  -- no recommendation.
  recommended boolean not null default false,
  -- The order the customer reads them in, set by whoever wrote the quote.
  sort_order  int not null default 0,
  -- The customer's answer. Null until they respond; on approval the one they
  -- picked is written 'accepted' and every other package on the quote is
  -- written 'declined', so the row is a record of the choice and not just of
  -- the winner.
  customer_response text,
  responded_at      timestamptz,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

alter table public.quote_packages drop constraint if exists qp_chk;
alter table public.quote_packages add constraint qp_chk check (
  char_length(title) between 1 and 120
  and (description is null or char_length(description) <= 2000)
  and amount >= 0 and amount <= 99999999
  and (customer_response is null or customer_response in ('accepted', 'declined'))
);

create index if not exists qp_quote_idx on public.quote_packages(quote_id, sort_order);

-- One recommendation per quote. A partial unique index rather than a check,
-- because the rule is about the other rows on the same quote and a check
-- constraint can only see its own.
create unique index if not exists qp_one_recommended
  on public.quote_packages(quote_id) where recommended;

drop trigger if exists qp_touch_updated_at on public.quote_packages;
create trigger qp_touch_updated_at
  before update on public.quote_packages
  for each row execute function public.touch_updated_at();

alter table public.quote_packages enable row level security;
grant select, insert, update, delete on public.quote_packages to authenticated;
grant all on public.quote_packages to service_role;

-- Same scoping as quote_options, and for the same reason: a contractor writes
-- the quote for the jobs assigned to them, from their own job page, so read and
-- write travel together here rather than being split owner/crew.
--
-- One policy per command instead of one FOR ALL, because insert has no USING
-- row to test against - the row does not exist yet - and folding them together
-- is how an insert policy quietly ends up checking nothing.
drop policy if exists "staff read packages" on public.quote_packages;
create policy "staff read packages" on public.quote_packages
  for select to authenticated
  using (
    public.is_owner()
    or exists (
      select 1 from public.quote_requests q
      where q.id = quote_packages.quote_id and q.assigned_to = auth.uid()
    )
  );

drop policy if exists "staff insert packages" on public.quote_packages;
create policy "staff insert packages" on public.quote_packages
  for insert to authenticated
  with check (
    public.is_owner()
    or exists (
      select 1 from public.quote_requests q
      where q.id = quote_packages.quote_id and q.assigned_to = auth.uid()
    )
  );

drop policy if exists "staff update packages" on public.quote_packages;
create policy "staff update packages" on public.quote_packages
  for update to authenticated
  using (
    public.is_owner()
    or exists (
      select 1 from public.quote_requests q
      where q.id = quote_packages.quote_id and q.assigned_to = auth.uid()
    )
  )
  with check (
    public.is_owner()
    or exists (
      select 1 from public.quote_requests q
      where q.id = quote_packages.quote_id and q.assigned_to = auth.uid()
    )
  );

drop policy if exists "staff delete packages" on public.quote_packages;
create policy "staff delete packages" on public.quote_packages
  for delete to authenticated
  using (
    public.is_owner()
    or exists (
      select 1 from public.quote_requests q
      where q.id = quote_packages.quote_id and q.assigned_to = auth.uid()
    )
  );

-- The customer's own choice is written by the token endpoint with the
-- service-role key (there is no session on /q/<token>), which the grant above
-- already covers. Nothing anonymous ever touches this table directly.

-- ═════ archive/message-log.sql ═════
-- Per-customer log of every text we send, and whether it actually went out.
--
-- Until now a send was best-effort and silent: `notifyNewQuote(...).catch(() => {})`
-- swallowed the failure so a lead could arrive with nobody being told, and the
-- only trace was a line in the Vercel logs nobody reads. This table is the trace
-- that lives where the job does, so "did the customer get that?" is answerable
-- from the job page instead of by guessing.
--
-- Written only by server code with the service-role key (sends happen from the
-- public /api/quote route, which has no user session), so there is no insert
-- policy for logged-in users - only a read policy matching quote_events.
--
-- Run in Supabase → SQL Editor. Safe to re-run.

create table if not exists public.quote_messages (
  id         uuid primary key default gen_random_uuid(),
  -- Nullable: a send we could not tie to a job is still worth recording.
  quote_id   uuid references public.quote_requests(id) on delete cascade,
  created_at timestamptz not null default now(),
  -- Which notification this was, e.g. 'received', 'quote_ready', 'crew_reminder'.
  kind       text not null,
  -- Who it was aimed at: 'customer', 'owner' or 'crew'.
  role       text not null,
  to_phone   text,
  body       text,
  -- The provider accepted it. Not the same as "it arrived" - carrier delivery
  -- is a separate thing we don't get told about - but it is the line between
  -- "our fault" and "not our fault", which is the question being asked.
  ok         boolean not null default false,
  provider   text,
  status     int,
  detail     text
);

create index if not exists qm_quote_idx on public.quote_messages(quote_id, created_at desc);
create index if not exists qm_phone_idx on public.quote_messages(to_phone);

alter table public.quote_messages enable row level security;
grant select on public.quote_messages to authenticated;
grant all on public.quote_messages to service_role;

-- Same scoping as the activity log: owners see everything, a contractor sees
-- the jobs assigned to them.
drop policy if exists "staff read messages" on public.quote_messages;
create policy "staff read messages" on public.quote_messages
  for select to authenticated
  using (
    public.is_owner()
    or exists (
      select 1 from public.quote_requests q
      where q.id = quote_messages.quote_id and q.assigned_to = auth.uid()
    )
  );

-- ═════ archive/quiet-hours.sql ═════
-- Springfield Concrete Group - quiet hours (no CUSTOMER texts 7pm to 8am Central)
-- Run this in Supabase → SQL Editor. Safe to re-run.
--
-- A text to a CUSTOMER raised between 7pm and 8am Central isn't sent and isn't
-- dropped: it's held, and it goes out at 8am. (The owner and the crew are on
-- the job and get theirs at any hour - the gate is on the send's role, not the
-- clock alone.) The message log is where it waits, because the log already
-- holds everything a queued text needs - who it's for, what it says, which job
-- it belongs to - and a held message showing up in "Texts sent" as "Waiting
-- until 8:00 AM" is exactly where somebody would look for it.
--
-- send_after   when this may go out. Null on everything sent immediately,
--              which is every row written before today and every row written
--              during the day.
-- sent_at      when the queue actually delivered it. Null while it's waiting.
--
-- So: a row is still queued if send_after is not null and sent_at is null.
-- Old rows have both null and are untouched by any of this.

alter table public.quote_messages add column if not exists send_after timestamptz;
alter table public.quote_messages add column if not exists sent_at timestamptz;

-- The flush query: everything due and not yet delivered, oldest first. Partial,
-- because the queue is a handful of rows against a table that only grows.
create index if not exists qm_due_idx
  on public.quote_messages (send_after)
  where send_after is not null and sent_at is null;

-- ═════ archive/cancel-held-text.sql ═════
-- Springfield Concrete Group - call a held text back before it goes out
-- Run this AFTER quiet-hours.sql, once, in Supabase → SQL Editor. Safe to re-run.
--
-- Quiet hours hold a customer text until 8am, and spacing holds a crew text for
-- a few minutes. Both mean the same thing for the person who raised it: there
-- is a window where the text has not gone anywhere yet. Until now that window
-- was one-way - the queue would send it in the morning whatever happened in
-- between, including the customer ringing at 9pm to say theyd changed their
-- mind, or the office realising the quote had the wrong number on it.
--
-- A queued row can now be cancelled. It is not deleted: the message log is the
-- record of what this job told people, and a text somebody stopped is part of
-- that record - "why didnt they get the quote?" is answered by the row saying
-- Cancelled, not by its absence.
--
-- cancelled_at  when a member of staff called it back. Null on everything else,
--               which is every row that exists today.
--
-- So a row is still queued if send_after is not null and BOTH sent_at and
-- cancelled_at are null. Once either is set the queue is done with it.

alter table public.quote_messages add column if not exists cancelled_at timestamptz;

-- The flush query narrows by the same three columns, so the partial index does
-- too. Recreated rather than added alongside: a queued row is a handful of rows
-- against a table that only grows, and two indexes for one query is one too many.
drop index if exists public.qm_due_idx;
create index if not exists qm_due_idx
  on public.quote_messages (send_after)
  where send_after is not null and sent_at is null and cancelled_at is null;

-- No new grant. Staff still only SELECT this table. the cancel is written by the
-- server action with the service-role key, which checks the person can reach the
-- job first. That keeps every write to the message log in one place - the server
-- - rather than opening the log up to UPDATE from the browser to support one button.

-- ═════ archive/queue-retry.sql ═════
-- Springfield Concrete Group - a held text that fails to send is tried again
-- Run this AFTER cancel-held-text.sql, once, in Supabase SQL Editor. Safe to re-run.
--
-- The queue claims a row before it sends it: sent_at is stamped first, so a
-- crash mid-send leaves a text unsent rather than sent twice. The cost of that
-- choice was that a FAILED send was indistinguishable from a delivered one as
-- far as the queue was concerned - sent_at was set, the row dropped out of the
-- due list, and nothing ever looked at it again. One blip from the SMS provider
-- at the moment the morning drain ran meant that quote never went out, ever,
-- and the only trace was a failed row in a log nobody opens.
--
-- attempts  how many times the queue has handed this row to the provider.
--           A failed send now clears sent_at and puts the row back, until
--           attempts reaches the cap in src/lib/crm/queries.ts, at which point
--           it stays failed and stops being retried.
--
-- Rows that already exist are on 0, which is right: none of them have been
-- tried by the retrying version of the code.

alter table public.quote_messages add column if not exists attempts int not null default 0;

-- ═════ archive/payments.sql ═════
-- Springfield Concrete Group - the payment ledger
-- Run this AFTER crm.sql and appointments.sql, once, in Supabase → SQL Editor.
-- Safe to re-run.
--
-- Until now "paid" was a single timestamp somebody set by hand after a Zelle
-- landed. That cannot answer the questions the business actually has: how much
-- of this job has been collected, by what means, and what does the contractor
-- still owe the office?
--
-- A job now has a TOTAL and a list of PAYMENTS. "Deposit" stops being a column
-- and becomes simply the first payment, which is what lets one job carry
-- $4,000 in cash and $6,000 on a card without a schema change. Three
-- instalments, an overpayment and a half-refunded cancellation all fall out of
-- the same shape.
--
-- The money only ever moves one way. The customer pays the CONTRACTOR - their
-- Stripe account is the merchant of record, so their card fees and their
-- 1099-K - and the contractor pays the office its percentage out of that. The
-- office never holds the customer's money and never owes a contractor
-- anything, which is the whole reason this is worth the trouble.

-- ── 1. The contractor's Stripe account ──────────────────────────────────────
-- Created in the Stripe Dashboard and onboarded by the contractor themselves;
-- the office pastes the resulting acct_… here. The three flags are Stripe's
-- answer to "can this person actually be paid", refreshed from the API and
-- kept current by the account.updated webhook. They are cached rather than
-- asked live because every screen that offers a payment button needs to know,
-- and none of them should wait on a round-trip to Stripe to render.
alter table public.staff add column if not exists stripe_account_id       text;
alter table public.staff add column if not exists stripe_charges_enabled  boolean not null default false;
alter table public.staff add column if not exists stripe_payouts_enabled  boolean not null default false;
alter table public.staff add column if not exists stripe_details_submitted boolean not null default false;
alter table public.staff add column if not exists stripe_checked_at       timestamptz;

-- One Stripe account per contractor, and never the same one on two people:
-- two contractors sharing an acct_ would each be taking the other's money.
create unique index if not exists staff_stripe_account_idx
  on public.staff(stripe_account_id)
  where stripe_account_id is not null;

-- ── 2. The office's cut, frozen onto the job ────────────────────────────────
-- The rate is 15% for a contractor's first three paid jobs and 10% after, but
-- it is written onto the JOB the first time money moves and never recalculated.
-- A contractor crossing the threshold mid-job must not silently reprice work
-- that was already quoted and agreed.
--
-- fee_total_cents is what the office has EARNED on this job. What it has
-- actually COLLECTED is the sum of fee_cents on the paid rows below, and the
-- difference is what the contractor still owes. That subtraction is the whole
-- cash board.
alter table public.quote_requests add column if not exists fee_rate       numeric(5, 4);
alter table public.quote_requests add column if not exists fee_total_cents integer;

-- ── 3. The ledger ───────────────────────────────────────────────────────────
create table if not exists public.quote_payments (
  id         uuid primary key default gen_random_uuid(),
  quote_id   uuid not null references public.quote_requests(id) on delete cascade,

  -- How the customer paid. 'card' is the only one that moves through Stripe;
  -- the rest are the crew telling us what landed in their hand or their phone.
  method     text not null,

  -- Cents throughout, never a float. Money in this table is compared, summed
  -- and handed to Stripe, and Stripe counts in cents - carrying dollars as
  -- numeric here would mean converting at every boundary and rounding at some
  -- of them.
  amount_cents integer not null,

  -- The office's cut taken out of THIS payment. Only ever non-zero on a card
  -- payment, where Stripe moves it automatically as the application fee. A
  -- recorded cash payment collects nothing, which is exactly why the debt on
  -- the job survives it.
  fee_cents  integer not null default 0,

  status     text not null default 'pending',

  -- Stripe's side. Null on anything the crew recorded by hand.
  --
  -- stripe_account_id is stored per PAYMENT rather than read from the
  -- contractor when needed: a job can be reassigned after money has moved, and
  -- the record has to keep saying whose account actually received it.
  stripe_account_id   text,
  checkout_session_id text,
  payment_intent_id   text,

  refunded_cents integer not null default 0,

  -- Who keyed it in. Null means nobody did - the customer paid it themselves
  -- through Stripe and the webhook wrote the row.
  recorded_by uuid references public.staff(id) on delete set null,
  note        text,

  created_at  timestamptz not null default now(),
  paid_at     timestamptz,
  refunded_at timestamptz
);

alter table public.quote_payments drop constraint if exists qp_chk;
alter table public.quote_payments add constraint qp_chk check (
  method in ('card', 'cash', 'venmo', 'zelle', 'check', 'other')
  and status in ('pending', 'paid', 'failed', 'refunded')
  -- A zero-dollar payment is a mis-tap, and a negative one is a refund wearing
  -- a disguise. Refunds are recorded on the row they reverse.
  and amount_cents > 0
  and amount_cents <= 100000000
  and fee_cents >= 0
  -- Stripe's own rule for an application fee, enforced here too so a bad
  -- calculation is caught by the database rather than by a customer's failed
  -- checkout: the fee is always strictly smaller than the payment carrying it.
  and fee_cents < amount_cents
  and refunded_cents >= 0
  and refunded_cents <= amount_cents
  and (note is null or char_length(note) <= 500)
);

-- The ledger is always read per job, newest first.
create index if not exists qp_quote_idx on public.quote_payments(quote_id, created_at desc);
-- The cash board reads it the other way: everything paid in a date range,
-- across every job, grouped by contractor.
create index if not exists qp_paid_idx on public.quote_payments(paid_at desc) where status = 'paid';
create index if not exists qp_account_idx on public.quote_payments(stripe_account_id);

-- Stripe delivers a webhook more than once, by design. This is what makes that
-- harmless: the second delivery for a session collides here instead of adding
-- a second payment to the job.
create unique index if not exists qp_session_idx
  on public.quote_payments(checkout_session_id)
  where checkout_session_id is not null;

-- ── 4. RLS - scoped exactly like the job it belongs to ──────────────────────
-- Owners see every payment. A contractor sees the payments on jobs assigned to
-- them, which is what lets the crew record cash from their own job page.
--
-- One policy per command rather than one FOR ALL: insert has no existing row
-- to test with USING, and folding them together is how an insert policy
-- quietly ends up checking nothing.
alter table public.quote_payments enable row level security;
grant select, insert, update on public.quote_payments to authenticated;
grant all on public.quote_payments to service_role;

-- Deliberately no delete grant. A payment that turns out to be wrong is
-- refunded or corrected, never erased: the ledger is the record the office and
-- the contractor settle up from, and a row vanishing out of it is the one
-- thing that would make it untrustworthy.

drop policy if exists "staff read payments" on public.quote_payments;
create policy "staff read payments" on public.quote_payments
  for select to authenticated
  using (
    public.is_owner()
    or exists (
      select 1 from public.quote_requests q
      where q.id = quote_payments.quote_id and q.assigned_to = auth.uid()
    )
  );

drop policy if exists "staff insert payments" on public.quote_payments;
create policy "staff insert payments" on public.quote_payments
  for insert to authenticated
  with check (
    public.is_owner()
    or exists (
      select 1 from public.quote_requests q
      where q.id = quote_payments.quote_id and q.assigned_to = auth.uid()
    )
  );

drop policy if exists "staff update payments" on public.quote_payments;
create policy "staff update payments" on public.quote_payments
  for update to authenticated
  using (
    public.is_owner()
    or exists (
      select 1 from public.quote_requests q
      where q.id = quote_payments.quote_id and q.assigned_to = auth.uid()
    )
  )
  with check (
    public.is_owner()
    or exists (
      select 1 from public.quote_requests q
      where q.id = quote_payments.quote_id and q.assigned_to = auth.uid()
    )
  );

-- ── 5. Settling the contractor's debt to the office ─────────────────────────
-- A card payment pays the office automatically, as the Stripe application fee.
-- Cash does not, so the fee stays owed on the job until the contractor sends
-- it over - by Zelle or Venmo, usually - and the office records that here.
--
-- Owner-only, and separate from quote_payments on purpose: these are two
-- different debts moving in two different directions, and a contractor being
-- able to write "I paid the office" would make the board they are settled from
-- worthless.
create table if not exists public.fee_settlements (
  id           uuid primary key default gen_random_uuid(),
  staff_id     uuid not null references public.staff(id) on delete cascade,
  -- Optional: the job this was settling, when it is one job's fee rather than
  -- a contractor clearing several at once.
  quote_id     uuid references public.quote_requests(id) on delete set null,
  amount_cents integer not null,
  method       text not null,
  note         text,
  recorded_by  uuid references public.staff(id) on delete set null,
  created_at   timestamptz not null default now()
);

alter table public.fee_settlements drop constraint if exists fs_chk;
alter table public.fee_settlements add constraint fs_chk check (
  amount_cents > 0
  and amount_cents <= 100000000
  and method in ('cash', 'venmo', 'zelle', 'check', 'card', 'other')
  and (note is null or char_length(note) <= 500)
);

create index if not exists fs_staff_idx on public.fee_settlements(staff_id, created_at desc);

alter table public.fee_settlements enable row level security;
grant select, insert on public.fee_settlements to authenticated;
grant all on public.fee_settlements to service_role;

drop policy if exists "owner read settlements" on public.fee_settlements;
create policy "owner read settlements" on public.fee_settlements
  for select to authenticated using (public.is_owner());

drop policy if exists "owner insert settlements" on public.fee_settlements;
create policy "owner insert settlements" on public.fee_settlements
  for insert to authenticated with check (public.is_owner());

-- ═════ archive/test-data.sql ═════
-- Springfield Concrete Group - leads that exist to be practised on
-- Run in Supabase → SQL Editor. Safe to re-run.
--
-- Testing a payment means recording a real row in quote_payments: the same
-- table, the same arithmetic, the same webhook. That is the point - a test that
-- takes a different path tests nothing - and it is also why a morning spent
-- trying out a feature ends with the Money page reporting takings that never
-- happened.
--
-- Deleting them afterwards is the wrong answer twice over: it throws away the
-- fixture you will want again next week, and it is one careless `where` clause
-- from taking a real customer with it. So a lead can now say what it is.
--
-- is_test  this lead exists for testing. It behaves exactly like any other
--          lead everywhere in the app - it can be quoted, approved, scheduled,
--          paid, refunded - and it is left out of every figure on the Money
--          page unless you ask to see it.

alter table public.quote_requests add column if not exists is_test boolean not null default false;

-- Partial: test leads are a handful of rows against a table that only grows,
-- and the only query that wants them is the one asking for exactly these.
create index if not exists qr_is_test_idx on public.quote_requests(is_test) where is_test;

-- ── Test people ─────────────────────────────────────────────────────────────
-- The same problem one level up. A test contractor exists to be assigned work
-- and to settle a fee against, and both of those are real rows: the fee they
-- "sent over" was counting in "your fees, received" while the practice job
-- that earned it was hidden, so the office appeared to have been paid a cut it
-- never earned.
--
-- Their settlements stop counting and their row leaves the contractor table.
-- Jobs keep their own flag: a real customer job that happens to be assigned
-- to a test account is still a real job, and should not disappear because of
-- who is holding it.
alter table public.staff add column if not exists is_test boolean not null default false;

select id, full_name, email, role, active, is_test from public.staff order by full_name;

-- Name the practice accounts here, check the list above, then run it.
update public.staff
set is_test = true
where email ilike '%test%'
  and is_test = false;

-- ── Backfill ────────────────────────────────────────────────────────────────
-- LOOK at this list before running the update under it. `%test%` is a weak
-- filter - it matches "Sam test 2" and "James Test" as well as "Testv3",
-- which is the point - and a real customer whose name happens to contain it
-- would be quietly written out of your revenue.
select id, name, status, quote_amount, created_at,
       (select count(*) from public.quote_payments p where p.quote_id = q.id) as payment_rows
from public.quote_requests q
where q.name ilike '%test%'
order by q.created_at desc;

-- Once the list above is only rows you recognise as practice, run this.
update public.quote_requests
set is_test = true
where name ilike '%test%'
  and is_test = false;

-- ── The ones whose names do not say test ────────────────────────────────────
-- A pattern only finds leads somebody happened to name after what they were
-- doing. The practice job called "Marcus" looks exactly like a customer called
-- Marcus, and no filter will ever tell them apart - only you can.
--
-- Put their names in the list below, check the select, then run the update.
-- After this initial tidy-up, use the Test lead card at the bottom of a job
-- page instead: it is one button, it is owner-only, and it writes a line in
-- the job activity log saying who decided and when.
select id, name, status, quote_amount, is_test, created_at,
       (select count(*) from public.quote_payments p where p.quote_id = q.id) as payment_rows
from public.quote_requests q
where q.name in ('Jose', 'Marcus', 'James P')
order by q.created_at desc;

update public.quote_requests
set is_test = true
where name in ('Jose', 'Marcus', 'James P')
  and is_test = false;

-- ── Undo ────────────────────────────────────────────────────────────────────
-- A real lead caught by the filter. Put its id in and run it.
update public.quote_requests
set is_test = false
where false  -- <= change to true, and put the real id below
  and id = '00000000-0000-0000-0000-000000000000';

-- Nothing else needs changing. The Money page reads the flag, hides those rows
-- from every total by default, and has a switch to show them when you are
-- checking that a test payment landed the way you expected.

-- ═════ archive/least-privilege.sql ═════
-- Springfield Concrete Group - least privilege on the money columns
-- Run this AFTER crm.sql and payments.sql, once, in Supabase -> SQL Editor.
--
-- SUPERSEDED by stage1-price-lockdown.sql, which replaces the
-- guard_quote_money_columns() defined here. Once stage 1 is in, do not re-run
-- this file: it would put the old guard back and silently undo stage 1.
--
-- Why this file exists.
--
-- A contractor does not only reach this database through the CRM. The project
-- URL and the anon key are both public (the browser needs them), and a
-- contractor knows their own email and password - so they can mint their own
-- access token against Supabase Auth and talk to PostgREST directly. Whatever
-- RLS allows, they can do, with curl, regardless of what the screens offer.
--
-- Read that way, two grants were doing far more than the app ever asked of
-- them:
--
--   1. "contractor updates assigned" on quote_requests is a TABLE-wide update.
--      fee_rate and fee_total_cents live on that table, and the fee is frozen
--      on the row the first time money moves. Setting fee_rate to 0 on your own
--      job makes the office earn nothing on it, permanently and silently:
--      ensureFeeOnJob keeps a rate that is already set, readLedger re-derives
--      the fee from it, and the cash board only flags a MISSING rate, not a
--      zero one. is_test hides the job from every figure on that board, and
--      archived_at hides it from the pipeline.
--
--   2. quote_payments granted insert AND update to authenticated. The app never
--      updates that table as a user - markSessionPaid, applyRefund and
--      expireStalePending all go through the service role - so the update grant
--      was pure attack surface: rewriting fee_cents on a paid row moves what
--      you owe the office to zero. The insert grant was shaped for the form
--      that uses it but not enforced, so a hand-rolled insert could claim a
--      card payment that never happened.
--
-- payments.sql already states the principle for fee_settlements: "a contractor
-- being able to write 'I paid the office' would make the board they are settled
-- from worthless." The same sentence applies to every number that board is a
-- sum of. This file finishes the job.
--
-- Nothing here changes what the app can do. Every write the CRM performs was
-- checked against these rules first; the service role is deliberately exempt,
-- because that is the key the server's own code holds and it has already done
-- its own authorization by the time it gets here.

-- Self-sufficient on purpose. The four columns guarded below arrive with
-- payments.sql (the fee pair) and test-data.sql (is_test), and a plpgsql
-- trigger that names a column the table does not have fails at RUN time, not
-- at create time - which would turn "I ran the files in the wrong order" into
-- "every CRM save is broken". These are the same statements those files use,
-- so running this first, last or twice all end in the same place.
alter table public.quote_requests add column if not exists fee_rate        numeric(5, 4);
alter table public.quote_requests add column if not exists fee_total_cents integer;
alter table public.quote_requests add column if not exists is_test         boolean not null default false;
alter table public.quote_requests add column if not exists archived_at     timestamptz;

-- ── 1. The columns a contractor must not write ──────────────────────────────
-- Enforced with a trigger rather than column-level grants because owners are
-- `authenticated` too: a GRANT UPDATE (cols) applies to the whole role and
-- would take the office's own edit rights with it.
--
-- The exemption is `auth.uid() is null`, which is exactly the service role: its
-- key carries no `sub` claim, so server code that has already authorized the
-- caller passes straight through.
--
-- Only columns with NO legitimate contractor write path are listed. Tokens are
-- not here (rotateTokens is open to whoever holds the job), and neither are
-- status/paid_at (the crew move their own cards, and a job marked paid with no
-- payment behind it already shows up on the cash board's "check these rows").
create or replace function public.guard_quote_money_columns()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Service role (server code) and owners write freely.
  if auth.uid() is null or public.is_owner() then
    return new;
  end if;

  if new.fee_rate is distinct from old.fee_rate
     or new.fee_total_cents is distinct from old.fee_total_cents then
    raise exception 'fee_rate and fee_total_cents are set by the office'
      using errcode = '42501';
  end if;

  if new.is_test is distinct from old.is_test then
    raise exception 'is_test is set by the office' using errcode = '42501';
  end if;

  if new.archived_at is distinct from old.archived_at then
    raise exception 'archiving a lead is done by the office' using errcode = '42501';
  end if;

  return new;
end;
$$;

drop trigger if exists qr_guard_money_columns on public.quote_requests;
create trigger qr_guard_money_columns
  before update on public.quote_requests
  for each row execute function public.guard_quote_money_columns();

-- ── 2. The ledger is not writable after the fact ────────────────────────────
-- The app never PATCHes quote_payments as a user. Taking the grant away costs
-- nothing and removes the only way a contractor could restate a payment that
-- has already been recorded - which is the row the office settles up from.
revoke update on public.quote_payments from authenticated;
drop policy if exists "staff update payments" on public.quote_payments;

-- ── 3. What a staff insert on the ledger is allowed to say ──────────────────
-- The one insert the app makes as a user is recordPayment: money the crew were
-- handed, in person, on a job that is theirs. Everything else - a card payment,
-- a pending checkout, anything carrying the office's cut - is written by the
-- server with the service role, and the service role does not consult this
-- policy at all.
--
-- So the shape is pinned to that one case:
--   * never 'card'          - a card payment is Stripe's word, not ours
--   * fee_cents = 0         - nothing was collected for the office on the way past
--   * status = 'paid'       - a hand-recorded payment is money already in hand
--   * recorded_by = you     - the row says who keyed it in, and cannot say
--                             somebody else did
--   * no Stripe identifiers - nothing to attach a real charge to
drop policy if exists "staff insert payments" on public.quote_payments;
create policy "staff insert payments" on public.quote_payments
  for insert to authenticated
  with check (
    (
      public.is_owner()
      or exists (
        select 1 from public.quote_requests q
        where q.id = quote_payments.quote_id and q.assigned_to = auth.uid()
      )
    )
    and method <> 'card'
    and fee_cents = 0
    and status = 'paid'
    and recorded_by = auth.uid()
    and stripe_account_id is null
    and checkout_session_id is null
    and payment_intent_id is null
    and refunded_cents = 0
  );

-- ── 4. Two people cannot collect the same balance twice ─────────────────────
-- recordManualPayment reads the ledger, checks the amount against what is still
-- owed, and then inserts. Those are three steps, and between the first and the
-- third somebody else can record a payment on the same job - the crew on site
-- and the office on the phone, or one person double-tapping a button on a slow
-- connection. Both requests see the same balance and both are allowed through,
-- and the job is over-collected.
--
-- The check belongs here, where it is one statement and cannot be raced.
--
-- Deliberately INSERT-only, and deliberately only for a signed-in user. A card
-- payment becoming paid is Stripe telling us money has ALREADY moved: refusing
-- to record it would not un-charge the customer, it would just lose the record
-- of it. That path is the service role's and passes straight through.
create or replace function public.guard_payment_not_over_total()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  total_cents  integer;
  already_cents integer;
begin
  if auth.uid() is null or new.status <> 'paid' then
    return new;
  end if;

  select round(coalesce(q.quote_amount, 0) * 100)::integer
    into total_cents
    from public.quote_requests q
   where q.id = new.quote_id;

  -- No price on the job yet: the app refuses this case with a better message,
  -- and there is no total here to measure an overpayment against.
  if total_cents is null or total_cents <= 0 then
    return new;
  end if;

  select coalesce(sum(p.amount_cents - p.refunded_cents), 0)
    into already_cents
    from public.quote_payments p
   where p.quote_id = new.quote_id
     and p.status in ('paid', 'refunded');

  if already_cents + new.amount_cents > total_cents then
    raise exception 'that is more than the % cents still owed on this job',
      greatest(total_cents - already_cents, 0)
      using errcode = '23514';
  end if;

  return new;
end;
$$;

drop trigger if exists qp_guard_over_total on public.quote_payments;
create trigger qp_guard_over_total
  before insert on public.quote_payments
  for each row execute function public.guard_payment_not_over_total();

-- ═════ archive/quote-type-plans.sql ═════
-- Springfield Concrete Group - quoting from building plans
-- Run this in Supabase → SQL Editor. Safe to re-run.
--
-- Adds a third quote_type. The two existing ones describe how we look at a
-- job: 'online' from the customer's photos, 'inperson' by driving out.
-- 'plans' is the commercial case - an apartment block priced off the
-- architect's drawings, where nobody visits and there are no photos to work
-- from either.
--
-- Note what this does NOT mean. Everywhere in the app that asks "is somebody
-- expected at this address" reads quote_type together with visit_date
-- (visitDateOf in src/lib/crm/constants.ts), and that test was written as
-- "anything except online is a real visit". A 'plans' row has no visit, so
-- that test is inverted in the same commit as this migration: only
-- 'inperson', and legacy nulls, count as a booked visit.
--
-- qr_chk is redefined whole rather than patched: the original lives in
-- supabase/schema.sql and Postgres has no "alter constraint", so the only
-- honest way to change one clause is to drop and re-add all of them.

alter table public.quote_requests drop constraint if exists qr_chk;
alter table public.quote_requests add constraint qr_chk check (
  char_length(name) between 1 and 120
  and char_length(phone) between 7 and 32
  and (email is null or (char_length(email) <= 200 and email ~* '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'))
  and (service is null or char_length(service) <= 120)
  and (address is null or char_length(address) <= 300)
  and (city is null or char_length(city) <= 120)
  and (details is null or char_length(details) <= 2000)
  and (preferred_time is null or char_length(preferred_time) <= 120)
  and (quote_type is null or quote_type in ('online', 'inperson', 'plans'))
  and (file_urls is null or jsonb_typeof(file_urls) = 'array')
);

-- ═════ archive/quote-ttl-10-days.sql ═════
-- Springfield Concrete Group - give the quotes already out there the longer clock
-- Run this in Supabase → SQL Editor. Safe to re-run.
--
-- QUOTE_TTL_DAYS went from 7 to 10 because customers were going off to collect
-- other quotes and coming back to a dead link. Changing the constant only fixes
-- the quotes sent from now on: quote_expires_at is a real timestamp, written
-- once at send time, so every quote already sitting in somebody's phone still
-- carries the 7-day date it was stamped with.
--
-- This re-stamps them as though the rule had always been 10 days.
--
-- READ THIS BEFORE RUNNING IT. The rule "10 days from when we sent it" also
-- covers quotes that ran out in the last three days, so this REVIVES them - a
-- link a customer found dead yesterday starts working again. That is almost
-- certainly what you want (it is the reason you asked) but it does change what
-- a customer sees, so it should be a decision rather than a side effect.
--
-- Only touches quotes nobody has answered. An accepted quote never expires in
-- the first place, and a declined one has no business coming back to life.

-- 1. Look first. Every row this would change, and what it would change to.
select
  name,
  quote_amount,
  quote_sent_at,
  quote_expires_at                        as expires_now,
  quote_sent_at + interval '10 days'      as expires_after,
  case
    when quote_expires_at < now() then 'REVIVED - had already expired'
    else 'extended'
  end                                     as effect
from public.quote_requests
where quote_sent_at is not null
  and customer_response is null
  and archived_at is null
  and quote_sent_at + interval '10 days' > now()
  and quote_expires_at is distinct from quote_sent_at + interval '10 days'
order by quote_sent_at desc;

-- 2. Then do it. Same conditions, so it changes exactly the rows listed above.
--
-- The last condition is what keeps this idempotent and keeps it off quotes that
-- are dead under the new rule too: a quote sent three weeks ago stays expired,
-- because moving its date would be inventing a price we no longer stand behind.
update public.quote_requests
set quote_expires_at = quote_sent_at + interval '10 days'
where quote_sent_at is not null
  and customer_response is null
  and archived_at is null
  and quote_sent_at + interval '10 days' > now()
  and quote_expires_at is distinct from quote_sent_at + interval '10 days';

-- ═════ archive/funnel.sql ═════
-- Springfield Concrete Group - quote funnel analytics
-- Run once in Supabase -> SQL Editor. Safe to re-run.
--
-- One row per thing a visitor did in the quote form: opened it, reached a
-- step, finished a step, gave up, hit an error, sent it. The CRM's Funnel page
-- (/crm/funnel, owners only) adds them up.
--
-- Nothing personal is stored. No name, phone, email or address - only which
-- step, how long, and which requirement was still unmet ("phone+address") when
-- someone left. attempt_id is random per opening of the form and visitor_id is
-- random per browser tab; neither is linked to the lead it may become.
--
-- Written only by /api/funnel with the service role, and read only by the
-- Funnel page with the service role after it has checked the viewer is an
-- owner. RLS is on with no policies, so the public anon key can do nothing
-- here at all.

create table if not exists public.site_funnel_events (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  attempt_id  text not null,
  visitor_id  text not null,
  form        text not null check (form in ('modal', 'estimate')),
  event       text not null check (event in ('open', 'view', 'done', 'back', 'close', 'error', 'submit')),
  step        text,
  ms          integer,
  mode        text,
  detail      text,
  path        text,
  device      text
);

create index if not exists site_funnel_events_created_at_idx on public.site_funnel_events (created_at desc);

alter table public.site_funnel_events enable row level security;
revoke all on public.site_funnel_events from anon, authenticated;
-- The server's key needs these spelled out: this project's default grants do
-- not cover new tables (schema.sql grants quote_requests the same way). Without
-- them every event came back 403 and the Funnel page stayed empty.
grant insert, select on public.site_funnel_events to service_role;

-- Supabase's free tier holds 500MB. At a few dozen rows per quote attempt this
-- table would take years to matter, but there is no reason to keep old clicks
-- forever. Run this by hand now and then, or schedule it with pg_cron:
--
--   delete from public.site_funnel_events where created_at < now() - interval '180 days';

-- ═════ archive/lead-idempotency.sql ═════
-- Springfield Concrete Group - one lead per filled-in quote form
-- Run once in Supabase -> SQL Editor. Safe to re-run. (Applied to the live
-- database on 23 Sep 2026.)
--
-- The quote form mints a random id when it opens and sends it with every
-- attempt to submit (src/lib/quote-submit.ts). /api/quote stores it here, and
-- the unique index turns a second insert of the same form - a retry after a
-- timeout, a double tap, a flaky connection that sent it twice - into a 409,
-- which the route answers with the lead it already saved.
--
-- That is what makes "press the button again" safe advice on every error the
-- form shows, and so what lets the form fail closed: it never has to guess
-- that a request probably got through and show a success screen on a hunch.
--
-- Nullable: rows from before this, and rows the CRM creates, have none.

alter table public.quote_requests add column if not exists client_submission_id text;

create unique index if not exists qr_client_submission_id_key
  on public.quote_requests (client_submission_id)
  where client_submission_id is not null;

-- ═════ archive/quote-drafts.sql ═════
-- Springfield Concrete Group - quote forms that were started but never sent
-- Run once in Supabase -> SQL Editor. Safe to re-run. (Applied to the live
-- database on 24 Sep 2026.)
--
-- The quote form saves what the customer has typed here as soon as there is a
-- name and a phone number to call, keyed by the same submission id it later
-- sends to /api/quote (see src/app/api/quote/draft/route.ts). When the request
-- is sent, lead_id is filled in. A row with no lead_id is somebody who got far
-- enough to leave a number and then didn't send - closed the tab, got stuck on
-- the address, hit an error - and the CRM's Funnel page lists them so the
-- office can call.
--
-- Nobody is texted from this table. The customer hasn't agreed to texts until
-- they press the button on the last step; the owner gets an alert, and calls.

create table if not exists public.quote_drafts (
  submission_id uuid primary key,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  name          text,
  phone         text,
  email         text,
  address       text,
  mode          text,
  service       text,
  step          text,
  source_path   text,
  lead_id       uuid,
  left_at       timestamptz,
  alerted_at    timestamptz,
  dismissed_at  timestamptz
);

create index if not exists quote_drafts_updated_at_idx on public.quote_drafts (updated_at desc);

alter table public.quote_drafts enable row level security;
revoke all on public.quote_drafts from anon, authenticated;
grant select, insert, update on public.quote_drafts to service_role;

-- Personal details of people who never became customers. Nothing reads rows
-- this old, so there is no reason to keep them:
--
--   delete from public.quote_drafts where updated_at < now() - interval '90 days';

-- ═════ archive/change-orders.sql ═════
-- Springfield Concrete Group - change orders on a job that's already agreed
-- Run this once in Supabase → SQL Editor. Safe to re-run.
--
-- A customer who rings up a week before the pour wanting the patio two feet
-- wider used to leave the crew with nothing good to do. The quote was accepted
-- and the day was booked, so the only lever was the owner editing quote_amount
-- by hand - which changes what the customer owes without the customer ever
-- agreeing to it, and leaves no record that they did.
--
-- A change order is the price moving WITH the customer's say-so. One pending
-- change per job, held in these four columns: set together when the crew sends
-- it, cleared together when the customer answers. "Is there a change waiting?"
-- is therefore just "is change_requested_at set?", with no status column to
-- disagree with itself.
--
-- There is no history table and there does not need to be, for the same reason
-- there is none for quote versions: quote_events already records a row per
-- change with the old and new figures in its meta, so "how did this job get to
-- $9,400" is answerable from the log the office already reads.
--
-- Nothing here touches money. The deposit keeps counting on its own, because
-- the ledger has always been "what the job is worth now, minus what has been
-- collected" - see readLedger in src/lib/crm/fees.ts. Raise the total and the
-- balance grows by the difference; the $4,125 already in the bank stays put.

alter table public.quote_requests
  -- What is changing, in the crew's own words. Goes to the customer verbatim,
  -- so it is the one field on the form that has to be written for them to read.
  add column if not exists change_note text,
  -- The proposed NEW total for the whole job, not the difference. The delta is
  -- derived for every screen that shows one, which means there is exactly one
  -- number stored and no way for "+$1,200" and "$9,400" to drift apart.
  add column if not exists change_amount numeric(10,2),
  add column if not exists change_requested_at timestamptz,
  add column if not exists change_requested_by uuid references public.staff(id) on delete set null;

-- A pending change is all four or none of them. Belt and braces behind the
-- server, which only ever writes them as a set: a row carrying an amount with
-- no note would put a price in front of a customer with nothing explaining it.
alter table public.quote_requests drop constraint if exists quote_requests_change_complete;
alter table public.quote_requests add constraint quote_requests_change_complete check (
  (change_requested_at is null and change_amount is null and change_note is null)
  or (change_requested_at is not null and change_amount is not null and change_note is not null)
);

-- A change order can only ever lower a price to zero, never past it.
alter table public.quote_requests drop constraint if exists quote_requests_change_amount_sane;
alter table public.quote_requests add constraint quote_requests_change_amount_sane check (
  change_amount is null or (change_amount >= 0 and change_amount <= 99999999)
);

-- ═════ archive/payment-corrections.sql ═════
-- Springfield Concrete Group - correcting a payment somebody keyed in wrong
-- Run this AFTER payments.sql, once, in Supabase -> SQL Editor. Safe to re-run.
--
-- Why this file exists.
--
-- A contractor took a 50% deposit and recorded the whole job as paid. Nothing
-- in the app stopped them, and nothing in the app could fix it afterwards:
--
--   * recordManualPayment and the guard_payment_not_over_total trigger both
--     refuse MORE than is owed. On an untouched job the whole total is owed, so
--     the full figure was allowed. The amount box on the form is even
--     pre-filled with the outstanding balance, so recording the entire job is
--     what happens if you open that form and press save.
--   * least-privilege.sql revoked UPDATE on quote_payments from authenticated,
--     deliberately - a contractor restating a payment they already recorded is
--     exactly the thing that file exists to prevent.
--   * refundJobPayment only handles card payments. Cash never moved through
--     Stripe, so there is nothing to send back; the figure is simply wrong.
--
-- That left the Supabase SQL console as the only remedy (money-audit.sql
-- section 8f), which is not a thing to ask somebody to do to their own books at
-- nine in the evening. Corrections now happen in the CRM, owner only, through
-- the service role - which is why no grant or policy changes here. The server
-- checks the role before it writes, and every correction lands in the activity
-- log with the old and the new figure on it.
--
-- All this file does is make room for one new status.

-- ── 'voided': a payment that should never have been recorded ─────────────────
-- Distinct from 'refunded', and the distinction is the whole reason for it:
--
--   refunded  money really did go back to the customer. It belongs on the
--             ledger, on the day it moved, and it reconciles against a bank
--             statement.
--   voided    no money ever moved. The row is a typo - a duplicate, or a
--             payment recorded against the wrong job - and the honest ledger is
--             the one that does not contain it.
--
-- Nothing in the app had to change to make a voided row stop counting. Every
-- figure in the business is summed over rows whose status is 'paid' or
-- 'refunded' (readLedger in src/lib/crm/fees.ts, moneyBoard in money.ts,
-- paidJobCountFor in payments.ts), so a voided row drops out of all of them at
-- once. It stays in the table, visible, with its note saying why - deleting it
-- would leave the office unable to answer "what happened to that $8,250".
alter table public.quote_payments drop constraint if exists qp_chk;
alter table public.quote_payments add constraint qp_chk check (
  method in ('card', 'cash', 'venmo', 'zelle', 'check', 'other')
  and status in ('pending', 'paid', 'failed', 'refunded', 'voided')
  -- A zero-dollar payment is a mis-tap, and a negative one is a refund wearing
  -- a disguise. Refunds are recorded on the row they reverse.
  and amount_cents > 0
  and amount_cents <= 100000000
  and fee_cents >= 0
  -- Stripe's own rule for an application fee, enforced here too so a bad
  -- calculation is caught by the database rather than by a customer's failed
  -- checkout: the fee is always strictly smaller than the payment carrying it.
  --
  -- It also bounds a correction: lowering a payment below the office's cut
  -- already taken out of it is refused here as well as in the server, which is
  -- why only hand-recorded rows (fee_cents = 0) can be corrected at all.
  and fee_cents < amount_cents
  and refunded_cents >= 0
  and refunded_cents <= amount_cents
  and (note is null or char_length(note) <= 500)
);

-- ── Have a look ─────────────────────────────────────────────────────────────
-- The shape that prompted all this: one hand-recorded payment that settles a
-- job exactly, on work that has not been marked finished. Every one of these is
-- either a genuine payment in advance or a deposit entered as the whole job,
-- and only the person who took it can say which.
select q.id, q.name, q.status, q.quote_amount,
       p.id as payment_id, p.method, p.amount_cents, p.paid_at,
       s.full_name as recorded_by
from public.quote_payments p
join public.quote_requests q on q.id = p.quote_id
left join public.staff s on s.id = p.recorded_by
where p.status = 'paid'
  and p.method <> 'card'
  and not coalesce(q.is_test, false)
  and q.completed_at is null
  and round(coalesce(q.quote_amount, 0) * 100) = p.amount_cents
order by p.paid_at desc nulls last;

-- ═════ archive/change-order-lines.sql ═════
-- Springfield Concrete Group - a change order can carry its own price breakdown
-- Run this AFTER change-orders.sql and quote-options.sql.
--
-- SUPERSEDED by stage1-price-lockdown.sql, which replaces the
-- apply_change_response() defined here. Once stage 1 is in, do not re-run
-- this file: it would add the old two-argument version back beside the new
-- one, and the API cannot choose between the two.
--
-- A customer asking for a change on a booked job usually asks a second question
-- straight after: "so what does that come to, and where does it go?" A change
-- order used to answer with one new total. Now it can carry the lines behind
-- it (materials, labor, and so on), the same way a quote can.
--
-- change_lines is the proposed breakdown, held next to change_amount until the
-- customer answers:
--   null   the change does not touch the breakdown (a job priced as one figure,
--          changed to another figure)
--   [...]  the job's breakdown once they approve. Replaces the line items on
--          the job. An empty array means "this job goes back to one price".
--
-- Nothing moves until they approve. Approving is one transaction in
-- apply_change_response below: the line items, the price and the cleared
-- change all land together or not at all, so the job can never show a new
-- breakdown against an old total.

alter table public.quote_requests
  add column if not exists change_lines jsonb;

-- Lines only ever ride on a pending change, and are a short list.
alter table public.quote_requests drop constraint if exists quote_requests_change_lines_sane;
alter table public.quote_requests add constraint quote_requests_change_lines_sane check (
  change_lines is null
  or (
    change_requested_at is not null
    and jsonb_typeof(change_lines) = 'array'
    and jsonb_array_length(change_lines) <= 12
  )
);

-- The customer's answer, applied in one go. Service role only: the customer
-- page has no session, and the unguessable link is checked by the server
-- before this is called.
--
-- Returns what happened, so the caller can log it and text the crew:
--   status     'ok', or 'none' when nothing was waiting (a second tap)
--   quote      the job as it now stands
--   from / to  the total before and after (to is the proposed total either way)
--   note       what the change said
--   old_lines / new_lines  the breakdown before and after, for the activity log
create or replace function public.apply_change_response(p_id uuid, p_accept boolean)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  q public.quote_requests;
  v_from numeric;
  v_to numeric;
  v_note text;
  v_lines jsonb;
  v_old jsonb;
  v_sum numeric;
begin
  -- Locked, so a double tap waits for the first to finish and then sees that
  -- there is nothing left to answer.
  select * into q from public.quote_requests where id = p_id for update;
  if not found or q.change_requested_at is null or q.change_amount is null then
    return jsonb_build_object('status', 'none');
  end if;

  v_from := q.quote_amount;
  v_to := q.change_amount;
  v_note := q.change_note;
  v_lines := q.change_lines;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'title', o.title,
        'description', o.description,
        'amount', o.amount,
        'required', o.required,
        'customer_response', o.customer_response
      )
      order by o.sort_order, o.created_at
    ),
    '[]'::jsonb
  )
  into v_old
  from public.quote_options o
  where o.quote_id = p_id;

  if p_accept and v_lines is not null then
    -- The lines must add up to the total the customer was shown. The server
    -- writes them that way; this is the backstop that keeps a breakdown and a
    -- price from ever disagreeing on a job.
    if jsonb_array_length(v_lines) > 0 then
      select coalesce(sum((l->>'amount')::numeric), 0) into v_sum
      from jsonb_array_elements(v_lines) l;
      if round(v_sum, 2) <> round(v_to, 2) then
        raise exception 'change lines (%) do not add up to the new total (%)', v_sum, v_to;
      end if;
    end if;

    delete from public.quote_options where quote_id = p_id;

    -- Every line is part of the job and already agreed: the customer approved
    -- this exact list a moment ago.
    insert into public.quote_options
      (quote_id, title, description, amount, required, sort_order, customer_response, responded_at)
    select
      p_id,
      l->>'title',
      nullif(l->>'description', ''),
      (l->>'amount')::numeric,
      true,
      (t.ord - 1)::int,
      'accepted',
      now()
    from jsonb_array_elements(v_lines) with ordinality as t(l, ord);
  end if;

  update public.quote_requests
  set
    quote_amount = case when p_accept then v_to else quote_amount end,
    change_note = null,
    change_amount = null,
    change_requested_at = null,
    change_requested_by = null,
    change_lines = null
  where id = p_id
  returning * into q;

  return jsonb_build_object(
    'status', 'ok',
    'quote', to_jsonb(q),
    'from', v_from,
    'to', v_to,
    'note', v_note,
    'old_lines', v_old,
    'new_lines', v_lines
  );
end;
$$;

revoke all on function public.apply_change_response(uuid, boolean) from public;
revoke all on function public.apply_change_response(uuid, boolean) from anon, authenticated;
grant execute on function public.apply_change_response(uuid, boolean) to service_role;

-- ═════ archive/change-deposit.sql ═════
-- Springfield Concrete Group - a change request can ask for a second deposit
-- Run this AFTER change-order-lines.sql.
--
-- SUPERSEDED by stage1-price-lockdown.sql, which replaces the
-- apply_change_response() defined here. Once stage 1 is in, do not re-run
-- this file: it would add the old two-argument version back beside the new
-- one, and the API cannot choose between the two.
--
-- A change that adds materials usually needs money up front to buy them. Dave's
-- patio grew by $1,390 of materials: he sends that now, and the rest is paid
-- when the work is done, like the rest of the job.
--
-- Two columns, both whole cents:
--
--   change_deposit_cents   rides on a pending change, like change_amount. What
--                          the crew asked to be paid up front if the customer
--                          approves. Null when the change asks for nothing.
--
--   deposit_target_cents   on the job, once a change with a deposit is
--                          approved: how much the customer should have paid IN
--                          TOTAL before the work goes ahead. Set to "what they
--                          had paid when they approved" plus the deposit.
--
-- "Due now" is then target minus paid, never below zero and never more than the
-- balance. Stored as a target rather than as "$1,390 owed" so it clears itself:
-- record Dave's check and it reads zero, with nothing to remember to switch off.

alter table public.quote_requests
  add column if not exists change_deposit_cents integer,
  add column if not exists deposit_target_cents integer;

alter table public.quote_requests drop constraint if exists quote_requests_change_deposit_sane;
alter table public.quote_requests add constraint quote_requests_change_deposit_sane check (
  change_deposit_cents is null
  or (change_requested_at is not null and change_deposit_cents > 0 and change_deposit_cents <= 9999999999)
);

alter table public.quote_requests drop constraint if exists quote_requests_deposit_target_sane;
alter table public.quote_requests add constraint quote_requests_deposit_target_sane check (
  deposit_target_cents is null or (deposit_target_cents >= 0 and deposit_target_cents <= 9999999999)
);

-- Same function as change-order-lines.sql, plus the deposit: approving a change
-- that asks for one sets the job's target; either answer clears the request.
create or replace function public.apply_change_response(p_id uuid, p_accept boolean)
returns jsonb language plpgsql security definer set search_path = public
as $fn$
declare
  q public.quote_requests;
  v_from numeric; v_to numeric; v_note text; v_lines jsonb; v_old jsonb; v_sum numeric;
  v_deposit integer; v_paid bigint;
begin
  select * into q from public.quote_requests where id = p_id for update;
  if not found or q.change_requested_at is null or q.change_amount is null then
    return jsonb_build_object('status', 'none');
  end if;
  v_from := q.quote_amount; v_to := q.change_amount; v_note := q.change_note; v_lines := q.change_lines;
  v_deposit := q.change_deposit_cents;
  select coalesce(jsonb_agg(jsonb_build_object('title', o.title, 'description', o.description, 'amount', o.amount,
           'required', o.required, 'customer_response', o.customer_response) order by o.sort_order, o.created_at), '[]'::jsonb)
    into v_old from public.quote_options o where o.quote_id = p_id;
  if p_accept and v_lines is not null then
    if jsonb_array_length(v_lines) > 0 then
      select coalesce(sum((l->>'amount')::numeric), 0) into v_sum from jsonb_array_elements(v_lines) l;
      if round(v_sum, 2) <> round(v_to, 2) then
        raise exception 'change lines (%) do not add up to the new total (%)', v_sum, v_to;
      end if;
    end if;
    delete from public.quote_options where quote_id = p_id;
    insert into public.quote_options (quote_id, title, description, amount, required, sort_order, customer_response, responded_at)
    select p_id, l->>'title', nullif(l->>'description', ''), (l->>'amount')::numeric, true, (t.ord - 1)::int, 'accepted', now()
    from jsonb_array_elements(v_lines) with ordinality as t(l, ord);
  end if;
  -- What they had paid at the moment they approved, read the same way the app's
  -- ledger reads it: settled rows, net of refunds.
  select coalesce(sum(p.amount_cents - p.refunded_cents), 0) into v_paid
    from public.quote_payments p where p.quote_id = p_id and p.status in ('paid', 'refunded');
  update public.quote_requests set
    quote_amount = case when p_accept then v_to else quote_amount end,
    deposit_target_cents = case when p_accept and v_deposit is not null then (v_paid + v_deposit)::int else deposit_target_cents end,
    change_note = null, change_amount = null, change_requested_at = null, change_requested_by = null,
    change_lines = null, change_deposit_cents = null
  where id = p_id returning * into q;
  return jsonb_build_object('status', 'ok', 'quote', to_jsonb(q), 'from', v_from, 'to', v_to, 'note', v_note,
    'old_lines', v_old, 'new_lines', v_lines, 'deposit_cents', case when p_accept then v_deposit else null end,
    'paid_cents', v_paid);
end;
$fn$;
revoke all on function public.apply_change_response(uuid, boolean) from public;
revoke all on function public.apply_change_response(uuid, boolean) from anon, authenticated;
grant execute on function public.apply_change_response(uuid, boolean) to service_role;
notify pgrst, 'reload schema';

-- ═════ archive/fee-waiver.sql ═════
-- Springfield Concrete Group - the owner can waive part of the office fee on a job
--
-- SUPERSEDED by stage1-price-lockdown.sql, which replaces the
-- guard_quote_money_columns() defined here. Once stage 1 is in, do not re-run
-- this file: it would put the old guard back and silently undo stage 1.
--
-- The fee is the rate on the whole job total. Sometimes part of that total is
-- not the office's to take a cut of - a change order that only passed through
-- material costs, say - and the owner needs to take that slice off by hand.
--
--   fee_waived_cents   cents taken off this job's office fee. 0 = none.
--   fee_waived_note    why, for the audit trail.
--
-- Owner only: guard_quote_money_columns refuses the change from anybody else,
-- the same way it protects fee_rate and fee_total_cents. Safe to re-run.

alter table public.quote_requests
  add column if not exists fee_waived_cents integer not null default 0,
  add column if not exists fee_waived_note text;

alter table public.quote_requests drop constraint if exists quote_requests_fee_waived_sane;
alter table public.quote_requests add constraint quote_requests_fee_waived_sane check (
  fee_waived_cents >= 0 and fee_waived_cents <= 9999999999
);

create or replace function public.guard_quote_money_columns()
 returns trigger
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
begin
  -- Service role (server code) and owners write freely.
  if auth.uid() is null or public.is_owner() then
    return new;
  end if;

  if new.fee_rate is distinct from old.fee_rate
     or new.fee_total_cents is distinct from old.fee_total_cents
     or new.fee_waived_cents is distinct from old.fee_waived_cents
     or new.fee_waived_note is distinct from old.fee_waived_note then
    raise exception 'the office fee is set by the office'
      using errcode = '42501';
  end if;

  if new.is_test is distinct from old.is_test then
    raise exception 'is_test is set by the office' using errcode = '42501';
  end if;

  if new.archived_at is distinct from old.archived_at then
    raise exception 'archiving a lead is done by the office' using errcode = '42501';
  end if;

  return new;
end;
$function$;

-- ═════ archive/crew-views.sql ═════
-- Springfield Concrete Group - how often each contractor opens each job
--
-- One row per (job, contractor): how many times they opened the job page, and
-- when first and last. Owner-only to read. Written only by the server (service
-- role) through bump_job_staff_view, never by a contractor's own login, so
-- nobody can edit their own count. Safe to re-run.

create table if not exists public.job_staff_views (
  quote_id uuid not null references public.quote_requests(id) on delete cascade,
  staff_id uuid not null references public.staff(id) on delete cascade,
  view_count integer not null default 0,
  first_viewed_at timestamptz not null default now(),
  last_viewed_at timestamptz not null default now(),
  primary key (quote_id, staff_id)
);

alter table public.job_staff_views enable row level security;

drop policy if exists "owner reads crew views" on public.job_staff_views;
create policy "owner reads crew views" on public.job_staff_views
  for select to authenticated using (public.is_owner());

revoke all on public.job_staff_views from anon, authenticated;
grant select on public.job_staff_views to authenticated;

-- The server writes through this; this database grants new tables to nobody by
-- default, so the service role gets its rights explicitly.
grant select, insert, update on public.job_staff_views to service_role;

-- Opens after the job was marked Lost or archived - when the contractor is
-- locked out (below) and the page refuses them. The owner sees these in red.
alter table public.job_staff_views
  add column if not exists closed_view_count integer not null default 0,
  add column if not exists last_closed_view_at timestamptz;

-- Bodies as plain strings: the SQL runner used here hangs on $$ bodies.
create or replace function public.bump_job_staff_view(p_quote uuid, p_staff uuid, p_closed boolean default false)
  returns void language sql security invoker set search_path to 'public'
  as 'insert into public.job_staff_views (quote_id, staff_id, view_count, closed_view_count, last_closed_view_at) values (p_quote, p_staff, 1, case when p_closed then 1 else 0 end, case when p_closed then now() end) on conflict (quote_id, staff_id) do update set view_count = job_staff_views.view_count + 1, last_viewed_at = now(), closed_view_count = job_staff_views.closed_view_count + case when p_closed then 1 else 0 end, last_closed_view_at = case when p_closed then now() else job_staff_views.last_closed_view_at end';
revoke execute on function public.bump_job_staff_view(uuid, uuid, boolean) from public, anon, authenticated;
grant execute on function public.bump_job_staff_view(uuid, uuid, boolean) to service_role;

-- The first, two-argument version. DROP FUNCTION hangs on this project (its
-- sql_drop hooks never return), so it is kept and points at the one above.
-- The app always sends p_closed, which picks the three-argument one.
create or replace function public.bump_job_staff_view(p_quote uuid, p_staff uuid)
  returns void language sql security invoker set search_path to 'public'
  as 'select public.bump_job_staff_view(p_quote, p_staff, false)';
revoke execute on function public.bump_job_staff_view(uuid, uuid) from public, anon, authenticated;
grant execute on function public.bump_job_staff_view(uuid, uuid) to service_role;

-- ── Lost or archived jobs are the office's alone ───────────────────────────
-- A contractor stops seeing a job - board, customer list, calendar, job page,
-- payments - the moment it is marked Lost or archived. Owners see everything.
-- ALTER rather than DROP + CREATE: see the note on DROP above.
alter policy "staff read quotes" on public.quote_requests
  using (public.is_owner() or (assigned_to = auth.uid() and status <> 'lost' and archived_at is null));

-- ═════ migrations/20261017221826_stage1_price_lockdown.sql ═════
-- Springfield Concrete Group - stage 1: a contractor cannot lower an agreed price
-- Applied to production 2026-10-17 as migration 20261017221826 (already live;
-- do not run again). Undo: undo/20261017221826_stage1_price_lockdown.undo.sql.
-- Check it: verify/20261017221826_stage1_price_lockdown.verify.sql (ends in ROLLBACK).
-- State before it: ../snapshots/2026-10-17-pre-stage1.sql. Files named below
-- without a path (least-privilege.sql, fee-waiver.sql) are in ../archive/.
--
-- Why this file exists.
--
-- The office earns a percentage of the job total, so the job total is the
-- office's income. least-privilege.sql stopped a contractor rewriting the fee
-- RATE on their own job, but "contractor updates assigned" still lets them
-- PATCH every other column on it with their own access token - the anon key is
-- public and they know their own password - and the guard only looked at four
-- of them. The price itself was one of the columns it did not look at:
--
--   * quote_amount, after the customer had approved it. Halve the total and the
--     fee halves with it, because the ledger re-derives the fee from the frozen
--     rate against today's total (ensureFeeOnJob).
--   * customer_response, which is what locks the price: clear it and the job
--     reads as an open quote again, and the price is editable.
--   * status = 'paid' and paid_at, which the cash board reads as settled.
--   * deposit_target_cents, which only an approved change order sets.
--   * a change order already in front of the customer: rewrite change_amount
--     after they have read it, and the figure their Approve applies is not the
--     one they were shown.
--   * a change order of their own that LOWERS the total. The contractor can
--     read their job's public_token (and the text that carried the link), so
--     they can press the customer's Approve themselves. A contractor's change
--     may therefore only raise the total; lowering one is the owner's.
--   * the customer's phone and email, which every text and receipt goes to.
--
-- The owner's rule, which this file enforces for everyone who is not the owner
-- and not the server:
--
--   Before the customer answers, the crew edit the quote exactly as before.
--   Once they have answered, the price moves only through a change order the
--   customer approves - which the server applies with the service role
--   (apply_change_response), so it passes straight through this guard.
--
-- "Answered" is read the way the app reads it (isOpenAgain in queries.ts):
-- accepted, or declined and still Lost. A declined quote the office has moved
-- off Lost is open again - the customer's link shows it, and the next save
-- clears the old "no" - so the crew can re-price it, as they can today.
--
-- Every write the CRM makes with a contractor's token was checked against these
-- rules first (quote editor before an answer, phone approval, booking and
-- releasing a day, visits, photos, marking the job done, sending and
-- withdrawing a change order, rotating links, asking for payment). None of
-- them writes a column this refuses. The exemption is unchanged from
-- least-privilege.sql: `auth.uid() is null` is the service role (its key has no
-- `sub`), and owners pass on is_owner().
--
-- Section 3 replaces apply_change_response so the customer's Approve applies
-- only the change their page showed them (see there). The migration runner
-- wraps the file in one transaction (it was applied with the lock_timeout below).

set local lock_timeout = '5s';

-- ── 1. quote_requests ───────────────────────────────────────────────────────
-- Same function name and trigger as before, so CREATE OR REPLACE swaps the body
-- in place and qr_guard_money_columns keeps firing it. SECURITY DEFINER as the
-- live one is (is_owner() reads staff, which a contractor cannot see in full).
create or replace function public.guard_quote_money_columns()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  answered boolean;
begin
  -- Service role (server code) and owners write freely.
  if auth.uid() is null or public.is_owner() then
    return new;
  end if;

  -- The customer's answer is on file (see the header for why declined-but-
  -- reopened does not count). Read off OLD: what the row said before this
  -- write, so clearing the answer and changing the price in one PATCH is
  -- refused the same as doing it in two.
  answered := coalesce(old.customer_response = 'accepted', false)
              or coalesce(old.customer_response = 'declined' and old.status = 'lost', false);

  -- ── Never, at any stage ──

  -- The office's cut: the rate, the frozen total, and the owner's waiver.
  -- (Unchanged from fee-waiver.sql.)
  if new.fee_rate is distinct from old.fee_rate
     or new.fee_total_cents is distinct from old.fee_total_cents
     or new.fee_waived_cents is distinct from old.fee_waived_cents
     or new.fee_waived_note is distinct from old.fee_waived_note then
    raise exception 'the office fee is set by the office'
      using errcode = '42501';
  end if;

  -- What the Money page counts at all. (Unchanged.)
  if new.is_test is distinct from old.is_test then
    raise exception 'is_test is set by the office' using errcode = '42501';
  end if;

  -- What the pipeline shows at all. (Unchanged.)
  if new.archived_at is distinct from old.archived_at then
    raise exception 'archiving a lead is done by the office' using errcode = '42501';
  end if;

  -- Paid. A job becomes paid when the ledger adds up (settleJobIfPaid /
  -- resyncJobPaidState, service role) or when the owner says so. A contractor
  -- marking their own job paid - or moving one off Paid - is a claim about
  -- money, not about the work. Every other status move stays theirs: booking
  -- (scheduled), releasing a day (approved), marking it done (completed),
  -- a phone approval (approved), sending a quote (quoted), and Lost (which the
  -- server writes for them anyway, see updateQuoteResult).
  if new.status is distinct from old.status
     and (new.status = 'paid' or old.status = 'paid') then
    raise exception 'only the office can mark a job paid, or move it off paid'
      using errcode = '42501';
  end if;
  if new.paid_at is distinct from old.paid_at then
    raise exception 'paid_at is set from the payments ledger' using errcode = '42501';
  end if;

  -- The second deposit a change asked for. Set only when the customer approves
  -- that change (apply_change_response, service role).
  if new.deposit_target_cents is distinct from old.deposit_target_cents then
    raise exception 'the deposit is set by an approved change order' using errcode = '42501';
  end if;

  -- Who the office texts and emails about the job.
  if new.phone is distinct from old.phone or new.email is distinct from old.email then
    raise exception 'the customer''s phone and email are changed by the office'
      using errcode = '42501';
  end if;

  -- ── Once the customer has answered ──

  if answered then
    -- The price they agreed to, and the decline credit that came off it.
    if new.quote_amount is distinct from old.quote_amount
       or new.discount_accepted is distinct from old.discount_accepted then
      raise exception 'the customer has approved this price; send a change order for them to approve'
        using errcode = '42501';
    end if;

    -- Their answer itself. Clearing it is what would unlock the price above.
    if new.customer_response is distinct from old.customer_response
       or new.customer_responded_at is distinct from old.customer_responded_at then
      raise exception 'the customer''s answer is on file and only the office can change it'
        using errcode = '42501';
    end if;
  end if;

  -- ── A change order already in front of the customer ──
  -- Opening one (none pending) and withdrawing one (all six cleared together,
  -- as CLEAR_CHANGE does) are both the crew's. Rewriting one in place is not:
  -- the customer may already be reading it, and their Approve applies whatever
  -- the row says at that moment.
  if old.change_requested_at is not null
     and row(new.change_note, new.change_amount, new.change_requested_at,
             new.change_requested_by, new.change_lines, new.change_deposit_cents)
         is distinct from
         row(old.change_note, old.change_amount, old.change_requested_at,
             old.change_requested_by, old.change_lines, old.change_deposit_cents)
     and not (new.change_note is null and new.change_amount is null
              and new.change_requested_at is null and new.change_requested_by is null
              and new.change_lines is null and new.change_deposit_cents is null) then
    raise exception 'a change is already waiting on the customer; withdraw it first'
      using errcode = '42501';
  end if;

  -- ── Opening a change order ──
  -- The contractor can reach the customer's link, so whatever they open they
  -- can also approve. Compared in cents against quote_amount, the total the
  -- fee is worked out from (toCents in fees.ts): change_amount is the new
  -- total, not a difference (apply_change_response sets quote_amount to it).
  if old.change_requested_at is null and new.change_requested_at is not null then
    if new.change_requested_by is distinct from auth.uid() then
      raise exception 'a change order is sent in your own name' using errcode = '42501';
    end if;
    if round(coalesce(new.change_amount, 0) * 100) < round(coalesce(old.quote_amount, 0) * 100) then
      raise exception 'lowering an approved price is done by the office' using errcode = '42501';
    end if;
  end if;

  return new;
end;
$$;

-- Re-stated so this file stands alone; identical to the live trigger.
create or replace trigger qr_guard_money_columns
  before update on public.quote_requests
  for each row execute function public.guard_quote_money_columns();

-- ── 2. The priced lines behind an answered quote ────────────────────────────
-- quote_options and quote_packages carry their own amounts. Once the customer
-- has answered they are the record of what was bought and at what price, and
-- the starting lines of every later change order. The app never rewrites them
-- after an answer as a contractor: saveQuote only writes lines while the quote
-- is open, and the phone-approval path only stamps customer_response and
-- responded_at on them, which stays allowed. A change order's new lines are
-- written by apply_change_response with the service role.
--
-- So for anyone but the server and the owner, on a job whose customer has
-- answered: no new line, no removed line, and no line repriced or moved to
-- another job. Titles, descriptions and the answer stamps are left alone.
--
-- SECURITY DEFINER because it reads the parent job, and the answer on it has
-- to be read whatever the caller's own policies would show them.
create or replace function public.guard_quote_line_prices()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  jobs uuid[];
begin
  if auth.uid() is null or public.is_owner() then
    if tg_op = 'DELETE' then
      return old;
    end if;
    return new;
  end if;

  if tg_op = 'UPDATE' then
    -- The common case - stamping the customer's answer - touches neither.
    if new.amount is not distinct from old.amount
       and new.quote_id is not distinct from old.quote_id then
      return new;
    end if;
    jobs := array[old.quote_id, new.quote_id];
  elsif tg_op = 'INSERT' then
    jobs := array[new.quote_id];
  else
    jobs := array[old.quote_id];
  end if;

  if exists (
    select 1 from public.quote_requests q
     where q.id = any(jobs)
       and (q.customer_response = 'accepted'
            or (q.customer_response = 'declined' and q.status = 'lost'))
  ) then
    raise exception 'the customer has approved this price; send a change order for them to approve'
      using errcode = '42501';
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

create or replace trigger qo_guard_line_prices
  before insert or update or delete on public.quote_options
  for each row execute function public.guard_quote_line_prices();

create or replace trigger qp_guard_line_prices
  before insert or update or delete on public.quote_packages
  for each row execute function public.guard_quote_line_prices();

-- ── 3. The customer's Approve applies what they were shown ──────────────────
-- /api/change-response sends only the token and accept/decline, and this
-- applied whatever the row held when it took the lock. If the change was
-- withdrawn and a different one opened while the customer's page was open,
-- their Approve landed on a figure they never saw. The page now sends the
-- change_requested_at it displayed; a mismatch under the lock is 'stale' and
-- nothing is written.
--
-- p_requested_at defaults to null, which skips the check: a call with only
-- p_id and p_accept (a page opened before this ran, recordChangeAgreed) behaves
-- exactly as before. Otherwise the body is the live one, verbatim.
--
-- The live body is kept as it is, renamed apply_change_response_core with no
-- API access, and the new three-argument apply_change_response wraps it: it
-- takes the row lock, answers 'stale' on a mismatch, and otherwise hands over
-- to the core, which re-takes the same lock in the same transaction. Renaming
-- rather than dropping leaves no second overload for the API to choose between.
do $$
begin
  if to_regprocedure('public.apply_change_response(uuid, boolean)') is not null then
    alter function public.apply_change_response(uuid, boolean) rename to apply_change_response_core;
    revoke all on function public.apply_change_response_core(uuid, boolean) from public, anon, authenticated, service_role;
  end if;
end $$;

create or replace function public.apply_change_response(p_id uuid, p_accept boolean, p_requested_at timestamptz default null)
 returns jsonb
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
declare
  v_at timestamptz;
begin
  select change_requested_at into v_at from public.quote_requests where id = p_id for update;
  if found and v_at is not null and p_requested_at is not null and v_at is distinct from p_requested_at then
    return jsonb_build_object('status', 'stale');
  end if;
  return public.apply_change_response_core(p_id, p_accept);
end;
$function$;

revoke all on function public.apply_change_response(uuid, boolean, timestamptz) from public, anon, authenticated;
grant execute on function public.apply_change_response(uuid, boolean, timestamptz) to service_role;

-- PostgREST caches function signatures; this makes it pick up the new one now.
notify pgrst, 'reload schema';

-- ═════ migrations/20261017222017_stage3_hardening.sql ═════
-- Springfield Concrete Group - stage 3: database hygiene
-- Applied to production 2026-10-17 as migration 20261017222017 (already live;
-- do not run again). Undo: undo/20261017222017_stage3_hardening.undo.sql.
-- The state it was written against: ../snapshots/2026-10-17-pre-stage3.sql.
--
--   1. The Make.com webhook trigger on new leads is disabled. Nothing uses the
--      scenario any more, and every lead insert was posting the whole row to it.
--      Disabled rather than dropped, so the undo is one ENABLE and the webhook URL
--      never has to live in this repo. To remove it for good, in the SQL Editor:
--        drop trigger send_to_make on public.quote_requests;
--   2. SECURITY DEFINER functions stop being callable by anyone through the REST
--      API. Their EXECUTE came from the built-in PUBLIC grant (proacl NULL), so
--      revoking from anon or authenticated alone changes nothing: it has to come
--      off PUBLIC. A trigger function needs no EXECUTE to fire - that is only
--      checked when the trigger is created - so the guards keep running.
--      is_owner() is the exception: 25 RLS policies call it as the logged-in
--      user, so authenticated (and service_role) get it back explicitly.
--   3. The two updated_at trigger functions get a fixed search_path.
--
-- If stage 1 (20261017221826) runs AFTER this, run this again: it creates
-- guard_quote_line_prices() with the default grants.

set local lock_timeout = '5s';

-- ── 1. The Make.com webhook ─────────────────────────────────────────────────
do $$
begin
  if exists (select 1 from pg_trigger
              where tgrelid = 'public.quote_requests'::regclass and tgname = 'send_to_make') then
    alter table public.quote_requests disable trigger send_to_make;
  end if;
end $$;

-- ── 2. Definer functions ────────────────────────────────────────────────────
revoke execute on function public.guard_payment_not_over_total() from public;
revoke execute on function public.guard_quote_money_columns() from public;
revoke execute on function public.handle_new_user() from public;

revoke execute on function public.is_owner() from public, anon;
grant execute on function public.is_owner() to authenticated, service_role;

-- Stage 1's line-price guard, when it is there.
do $$
begin
  if to_regprocedure('public.guard_quote_line_prices()') is not null then
    revoke execute on function public.guard_quote_line_prices() from public, anon, authenticated;
  end if;
end $$;

-- ── 3. search_path ──────────────────────────────────────────────────────────
alter function public.touch_updated_at() set search_path = public, pg_temp;
alter function public.touch_agreements_updated_at() set search_path = public, pg_temp;

commit;
