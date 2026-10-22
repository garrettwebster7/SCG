# Springfield Concrete Group - setup

From an empty Supabase project and Vercel account to a live site and CRM. Do the
steps in order. **Never commit keys or paste them into chat or issues.** They go
in Vercel's Environment Variables (and an untracked `.env.local` for local dev).

## 1. Your own GitHub repo

Create an empty repo on GitHub (for example `springfield-concrete-group`,
private), then push this code to it:

```bash
git remote set-url origin https://github.com/<you>/springfield-concrete-group.git
git push -u origin main
```

## 2. Create the Supabase project

1. supabase.com -> New project. Region: **US East (Ohio)** or **Central US**, whichever is
   closest to Springfield, IL. Save the database password in a password manager.
2. Wait for it to finish provisioning.

## 3. Build the database (one paste)

1. Supabase -> **SQL Editor** -> New query.
2. Paste the whole of [`supabase/bootstrap.sql`](supabase/bootstrap.sql) and click **Run**.

That creates every table, function, trigger, RLS policy and grant, plus the two
**private** storage buckets (`quote-uploads`, `agreements`). It runs as one
transaction: if anything fails, nothing is applied.

Run it **once**, on the **empty** project only. It replays `supabase/archive/` in
the order in [`supabase/archive/README.md`](supabase/archive/README.md) and then
`supabase/migrations/`. Some of those files rewrite rows, so re-running it on a
database with data is not safe. It was tested end to end on a clean Postgres, and
the result matches `supabase/schema.sql` (225 columns, 26 policies, same functions).

For future schema changes, add a new file to `supabase/migrations/` and run just
that file.

## 4. Create your owner account

The CRM signs in with Supabase Auth. Every new auth user automatically gets an
**inactive contractor** row in `public.staff`; you promote yourself once.

1. Supabase -> **Authentication -> Users -> Add user -> Create new user**. Enter your
   email and a password, and tick **Auto Confirm User**.
2. SQL Editor, replacing the email and name:

   ```sql
   update public.staff
   set role = 'owner', active = true, full_name = 'Your Name'
   where email = 'you@example.com';
   ```

3. Check that it returns `UPDATE 1`.

Contractors are invited later from the CRM (**Contractors -> Invite**).

**Login allowlist:** by default only emails at your site's domain (taken from
`NEXT_PUBLIC_SITE_URL`) may sign in. If you use Gmail or another outside address,
set `CRM_ALLOWED_EMAILS=you@gmail.com` (comma-separated) in Vercel, or you will be
locked out.

## 5. Import into Vercel

1. vercel.com -> **Add New -> Project** -> import your GitHub repo. The framework is
   detected as Next.js; keep the defaults.
2. Before the first deploy, open **Environment Variables** and add the values from
   [`.env.example`](.env.example). The minimum to work:

   | Variable | Where to find it |
   | --- | --- |
   | `NEXT_PUBLIC_SITE_URL` | Your domain, e.g. `https://www.springfieldconcretegroup.com` |
   | `NEXT_PUBLIC_SUPABASE_URL` | Supabase -> Project Settings -> API -> Project URL |
   | `NEXT_PUBLIC_SUPABASE_ANON_KEY` | same page, **anon / publishable** key |
   | `SUPABASE_SERVICE_ROLE_KEY` | same page, **service_role / secret** key (secret!) |
   | `CRON_SECRET` | any long random string (`openssl rand -hex 32`) |
   | `CRM_ALLOWED_EMAILS` | your login email, if it isn't at your domain |
   | `OWNER_PHONE` | your mobile in `+1217...` form, for lead alerts |

   Optional: an SMS provider (Quo/OpenPhone or Twilio) for customer texts, Stripe
   for deposits, Google Calendar sync, Upstash for rate limits, Clarity for
   session recordings. Each is described in `.env.example`. Without SMS keys,
   texts are skipped and nothing else breaks.
3. **Deploy.**

If you use Vercel's Supabase integration instead, it adds the Supabase variables
for you. Confirm that the browser ones carry the `NEXT_PUBLIC_` prefix.

## 6. Domain and the CRM subdomain

1. Vercel -> Project -> **Domains**: add `springfieldconcretegroup.com` (or your
   domain) and `www.`. Follow the DNS instructions.
2. Optional: add `crm.<your-domain>` too. The middleware serves the CRM at the
   root of any `crm.` host. Otherwise the CRM is at `/crm`.
3. Update `NEXT_PUBLIC_SITE_URL` if it changed, then redeploy.

## 7. Check it works

- Submit a quote from the site. It appears in **/crm** and in Supabase -> Table
  Editor -> `quote_requests`.
- CRM -> **Settings**: send yourself a test text, and check the clock card says
  `America/Chicago`.
- Crons (`vercel.json`) run daily at 14:00 UTC (9am CDT / 8am CST) and 23:00 UTC
  (6pm CDT / 5pm CST). The Hobby plan allows one run per day per cron.

## Before going live: still to replace

- **Phone and NAP** in `src/lib/site-data.ts` (`phoneDisplay`, `phoneHref`).
- **Domain:** `springfieldconcretegroup.com` is a placeholder fallback in
  `src/lib/seo.ts`, `src/lib/crm/env.ts` and `src/lib/crm/access.ts`. Setting
  `NEXT_PUBLIC_SITE_URL` overrides all three.
- **Contractor agreement** (`docs/INDEPENDENT CONTRACTOR AGREEMENT.docx`): now names
  Springfield Concrete Group and Illinois governing law. Have an Illinois attorney
  review it before use.
- **Office fee, deposits, discounts:** review the business numbers in
  `src/lib/crm/constants.ts` and `src/lib/crm/fees.ts` for your own pricing.
