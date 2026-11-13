-- Postgres schema (works on Supabase). Not needed for the JSON demo.
-- This is the shape your data takes once real builders are on the platform.

create table builders (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  plan         text not null default 'pilot',      -- pilot | standard | enterprise
  created_at   timestamptz not null default now()
);

create table projects (
  id              uuid primary key default gen_random_uuid(),
  builder_id      uuid not null references builders(id),
  slug            text unique not null,            -- e.g. greenmeadows (used in the QR link)
  name            text not null,
  location        text,
  status          text,
  possession      text,
  rera_number     text,                            -- required on advertising material; verify rules
  configs         text,
  price_from      text,
  sales_whatsapp  text,
  progress_stage  text,
  progress_pct    int check (progress_pct between 0 and 100),
  disclaimer      text,
  active          boolean not null default true
);

create table towers (
  id               uuid primary key default gen_random_uuid(),
  project_id       uuid not null references projects(id) on delete cascade,
  name             text not null,
  floors           int  not null,
  units_total      int  not null,
  units_available  int  not null check (units_available >= 0)
);

create table project_updates (
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid not null references projects(id) on delete cascade,
  posted_on   date not null default current_date,
  body        text not null,
  photo_url   text
);

create table channel_partners (
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid not null references projects(id) on delete cascade,
  code        text not null,                       -- e.g. ravi (used in the QR link)
  name        text not null,
  role        text default 'Channel partner',
  unique (project_id, code)
);

-- One row per page open / AR start. Powers the "which CP's cards get scanned" report.
create table scans (
  id          bigint generated always as identity primary key,
  project_id  uuid not null references projects(id),
  cp_code     text,
  event       text not null,                       -- page_view | ar_start | ar_target_found
  created_at  timestamptz not null default now()
);

-- Personal data (DPDP Act): keep consent proof, and agree with the builder who is the data controller.
create table leads (
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid not null references projects(id),
  cp_code     text,
  name        text not null,
  phone       text not null,
  consent     boolean not null,
  created_at  timestamptz not null default now()
);

create index on scans (project_id, created_at);
create index on leads (project_id, created_at);
