-- =====================================================================
-- Phase 1 setup for Supabase.  Paste ALL of this into: SQL Editor -> New query -> Run.
-- Safe to run more than once.
-- Design: one row per project; the project's content is a single JSON document
-- (the same shape as data/projects.json). Simple on purpose for the pilot.
-- =====================================================================

-- 1) Projects: what the public viewer reads ------------------------------
create table if not exists public.projects (
  slug         text primary key check (slug ~ '^[a-z0-9-]+$'),
  builder_name text not null,
  published    boolean not null default false,   -- only published projects are visible to the public
  data         jsonb not null,
  updated_at   timestamptz not null default now()
);
alter table public.projects enable row level security;

drop policy if exists "public can read published projects" on public.projects;
create policy "public can read published projects"
  on public.projects for select to anon, authenticated
  using (published = true);

-- 2) Leads: the public can ADD a lead but can never READ any ---------------
create table if not exists public.leads (
  id           uuid primary key default gen_random_uuid(),
  project_slug text not null references public.projects(slug),
  cp_code      text check (cp_code is null or cp_code ~ '^[a-z0-9_-]{1,40}$'),
  name         text not null check (char_length(name) between 1 and 100),
  phone        text not null check (phone ~ '^[0-9+ ]{10,15}$'),
  consent      boolean not null check (consent = true),
  created_at   timestamptz not null default now()
);
alter table public.leads enable row level security;
revoke select, update, delete on public.leads from anon;

drop policy if exists "anyone can submit a lead" on public.leads;
create policy "anyone can submit a lead"
  on public.leads for insert to anon, authenticated
  with check (true);

-- 3) Scans: page opens and AR starts. Add-only for the public ----------------
create table if not exists public.scans (
  id           bigint generated always as identity primary key,
  project_slug text not null references public.projects(slug),
  cp_code      text check (cp_code is null or cp_code ~ '^[a-z0-9_-]{1,40}$'),
  event        text not null check (event in ('page_view', 'ar_start', 'ar_target_found')),
  created_at   timestamptz not null default now()
);
alter table public.scans enable row level security;
revoke select, update, delete on public.scans from anon;

drop policy if exists "anyone can record a scan" on public.scans;
create policy "anyone can record a scan"
  on public.scans for insert to anon, authenticated
  with check (true);

create index if not exists leads_project_created on public.leads (project_slug, created_at desc);
create index if not exists scans_project_created on public.scans (project_slug, created_at desc);

-- 4) Demo project (the Green Meadows data you already know) -----------------
insert into public.projects (slug, builder_name, published, data)
values ('greenmeadows', 'Demo Builders Pvt Ltd', true, $json${
  "name": "Green Meadows",
  "builder": "Demo Builders Pvt Ltd",
  "location": "Whitefield, Bengaluru",
  "status": "Under construction",
  "possession": "Dec 2027",
  "rera": "PRM/KA/RERA/DEMO-0000",
  "configs": "2 & 3 BHK apartments",
  "price_from": "₹1.2 Cr onwards",
  "sales_whatsapp": "910000000000",
  "disclaimer": "Demo data for illustration only. The 3D view is an artist’s impression and not to scale.",
  "progress": {
    "stage": "Structure – 7th slab",
    "percent": 38
  },
  "towers": [
    {
      "name": "Tower A",
      "floors": 14,
      "units_total": 56,
      "units_available": 21
    },
    {
      "name": "Tower B",
      "floors": 12,
      "units_total": 48,
      "units_available": 30
    }
  ],
  "updates": [
    {
      "date": "2026-11-05",
      "text": "Tower A: 7th floor slab cast."
    },
    {
      "date": "2026-10-18",
      "text": "Clubhouse foundation work started."
    },
    {
      "date": "2026-09-30",
      "text": "Tower B: 5th floor slab cast."
    }
  ],
  "cps": {
    "ravi": {
      "name": "Ravi Kumar",
      "role": "Channel partner"
    },
    "meena": {
      "name": "Meena Rao",
      "role": "Channel partner"
    }
  },
  "ar_views": [
    "gallery",
    "video",
    "towers"
  ],
  "media": {
    "gallery": [
      {
        "src": "media/progress-1.jpg",
        "caption": "Sep 2026 · Tower B, 5th slab"
      },
      {
        "src": "media/progress-2.jpg",
        "caption": "Oct 2026 · Clubhouse foundation"
      },
      {
        "src": "media/progress-3.jpg",
        "caption": "Nov 2026 · Tower A, 7th slab"
      }
    ],
    "video": {
      "src": "media/walkthrough.mp4",
      "poster": "media/walkthrough-poster.jpg",
      "caption": "Project walkthrough"
    },
    "audio": {
      "src": "media/welcome.mp3",
      "label": "Welcome message"
    }
  }
}$json$::jsonb)
on conflict (slug) do update
  set builder_name = excluded.builder_name,
      published    = excluded.published,
      data         = excluded.data,
      updated_at   = now();
