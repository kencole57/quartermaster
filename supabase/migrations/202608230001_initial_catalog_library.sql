create extension if not exists pgcrypto;

create schema if not exists catalog;
create schema if not exists library;

create type catalog.item_type as enum (
  'package',
  'book',
  'document',
  'stl_model',
  'cad_model',
  'map',
  'photo',
  'video',
  'audio',
  'rules',
  'scenario',
  'reference',
  'note',
  'other'
);

create type catalog.visibility as enum ('private', 'shared', 'public_candidate');
create type library.ownership_status as enum ('owned', 'wishlist', 'borrowed', 'lent_out', 'sold', 'archived');
create type library.location_type as enum ('local_drive', 'external_drive', 'nas', 'cloud', 'archive_zip', 'bookshelf', 'box', 'office', 'storage', 'other');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table catalog.creators (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  website_url text,
  notes text,
  visibility catalog.visibility not null default 'private',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint creators_name_not_blank check (length(btrim(name)) > 0)
);

create table catalog.taxonomy_terms (
  id uuid primary key default gen_random_uuid(),
  term_type text not null,
  name text not null,
  parent_id uuid references catalog.taxonomy_terms(id) on delete set null,
  description text,
  created_at timestamptz not null default now(),
  unique (term_type, name)
);

create table catalog.items (
  id uuid primary key default gen_random_uuid(),
  parent_item_id uuid references catalog.items(id) on delete set null,
  creator_id uuid references catalog.creators(id) on delete set null,
  title text not null,
  subtitle text,
  item_type catalog.item_type not null default 'other',
  description text,
  historical_period_id uuid references catalog.taxonomy_terms(id) on delete set null,
  conflict_id uuid references catalog.taxonomy_terms(id) on delete set null,
  theatre_id uuid references catalog.taxonomy_terms(id) on delete set null,
  faction_id uuid references catalog.taxonomy_terms(id) on delete set null,
  date_start date,
  date_end date,
  source_url text,
  publication_date date,
  visibility catalog.visibility not null default 'private',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  search_vector tsvector generated always as (
    setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
    setweight(to_tsvector('english', coalesce(subtitle, '')), 'B') ||
    setweight(to_tsvector('english', coalesce(description, '')), 'C')
  ) stored,
  constraint items_title_not_blank check (length(btrim(title)) > 0)
);

create table catalog.files (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references catalog.items(id) on delete cascade,
  filename text not null,
  extension text,
  file_kind text,
  expected_size_bytes bigint,
  checksum_sha256 text,
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint files_filename_not_blank check (length(btrim(filename)) > 0),
  constraint files_checksum_sha256_format check (checksum_sha256 is null or checksum_sha256 ~ '^[a-fA-F0-9]{64}$')
);

create table catalog.book_details (
  item_id uuid primary key references catalog.items(id) on delete cascade,
  isbn_10 text,
  isbn_13 text,
  author_text text,
  editor_text text,
  publisher text,
  publication_date date,
  edition text,
  printing text,
  language text,
  page_count integer,
  format text,
  oclc_number text,
  lccn text,
  dewey_decimal text
);

create table catalog.tags (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  tag_type text,
  description text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint tags_name_not_blank check (length(btrim(name)) > 0)
);

create table catalog.item_tags (
  item_id uuid not null references catalog.items(id) on delete cascade,
  tag_id uuid not null references catalog.tags(id) on delete cascade,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  primary key (item_id, tag_id)
);

create table catalog.file_tags (
  file_id uuid not null references catalog.files(id) on delete cascade,
  tag_id uuid not null references catalog.tags(id) on delete cascade,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  primary key (file_id, tag_id)
);

create table library.user_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  item_id uuid not null references catalog.items(id) on delete cascade,
  ownership_status library.ownership_status not null default 'owned',
  acquired_date date,
  acquired_from text,
  price_paid numeric(12,2),
  condition text,
  personal_rating integer,
  personal_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, item_id),
  constraint user_items_personal_rating_range check (personal_rating is null or personal_rating between 1 and 5)
);

create table library.user_item_locations (
  id uuid primary key default gen_random_uuid(),
  user_item_id uuid not null references library.user_items(id) on delete cascade,
  location_type library.location_type not null default 'other',
  location_label text not null,
  path_or_detail text,
  verified_at timestamptz,
  missing_at timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_item_locations_label_not_blank check (length(btrim(location_label)) > 0)
);

create table library.user_file_locations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  file_id uuid not null references catalog.files(id) on delete cascade,
  location_type library.location_type not null default 'other',
  root_label text not null,
  path_text text not null,
  verified_at timestamptz,
  missing_at timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_file_locations_root_not_blank check (length(btrim(root_label)) > 0),
  constraint user_file_locations_path_not_blank check (length(btrim(path_text)) > 0)
);

create table library.notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  entity_type text not null,
  entity_id uuid not null,
  body text not null,
  visibility catalog.visibility not null default 'private',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint notes_body_not_blank check (length(btrim(body)) > 0)
);

create index creators_name_idx on catalog.creators using btree (lower(name));
create index items_type_idx on catalog.items (item_type);
create index items_visibility_idx on catalog.items (visibility);
create index items_created_by_idx on catalog.items (created_by);
create index items_search_idx on catalog.items using gin (search_vector);
create index files_item_id_idx on catalog.files (item_id);
create index files_checksum_idx on catalog.files (checksum_sha256) where checksum_sha256 is not null;
create index tags_name_idx on catalog.tags using btree (lower(name));
create index user_items_user_id_idx on library.user_items (user_id);
create index user_file_locations_user_id_idx on library.user_file_locations (user_id);
create index notes_user_entity_idx on library.notes (user_id, entity_type, entity_id);

alter table public.profiles enable row level security;
alter table catalog.creators enable row level security;
alter table catalog.taxonomy_terms enable row level security;
alter table catalog.items enable row level security;
alter table catalog.files enable row level security;
alter table catalog.book_details enable row level security;
alter table catalog.tags enable row level security;
alter table catalog.item_tags enable row level security;
alter table catalog.file_tags enable row level security;
alter table library.user_items enable row level security;
alter table library.user_item_locations enable row level security;
alter table library.user_file_locations enable row level security;
alter table library.notes enable row level security;

create policy "Profiles are visible to their owner" on public.profiles for select using (auth.uid() = id);
create policy "Users can insert their own profile" on public.profiles for insert with check (auth.uid() = id);
create policy "Users can update their own profile" on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);

create policy "Creators are readable when shared or owned" on catalog.creators for select using (visibility <> 'private' or created_by = auth.uid());
create policy "Users can create creators" on catalog.creators for insert to authenticated with check (created_by = auth.uid());
create policy "Users can update own private creators" on catalog.creators for update to authenticated using (created_by = auth.uid() and visibility = 'private') with check (created_by = auth.uid());
create policy "Users can delete own private creators" on catalog.creators for delete to authenticated using (created_by = auth.uid() and visibility = 'private');

create policy "Taxonomy is readable by authenticated users" on catalog.taxonomy_terms for select to authenticated using (true);

create policy "Items are readable when shared or owned" on catalog.items for select using (visibility <> 'private' or created_by = auth.uid());
create policy "Users can create items" on catalog.items for insert to authenticated with check (created_by = auth.uid());
create policy "Users can update own private items" on catalog.items for update to authenticated using (created_by = auth.uid() and visibility = 'private') with check (created_by = auth.uid());
create policy "Users can delete own private items" on catalog.items for delete to authenticated using (created_by = auth.uid() and visibility = 'private');

create policy "Files inherit item readability" on catalog.files for select using (
  exists (
    select 1 from catalog.items
    where items.id = files.item_id
      and (items.visibility <> 'private' or items.created_by = auth.uid())
  )
);
create policy "Users can create files for own items" on catalog.files for insert to authenticated with check (
  created_by = auth.uid()
  and exists (select 1 from catalog.items where items.id = files.item_id and items.created_by = auth.uid())
);
create policy "Users can update own files" on catalog.files for update to authenticated using (created_by = auth.uid()) with check (created_by = auth.uid());
create policy "Users can delete own files" on catalog.files for delete to authenticated using (created_by = auth.uid());

create policy "Book details inherit item readability" on catalog.book_details for select using (
  exists (
    select 1 from catalog.items
    where items.id = book_details.item_id
      and (items.visibility <> 'private' or items.created_by = auth.uid())
  )
);
create policy "Users can create book details for own items" on catalog.book_details for insert to authenticated with check (
  exists (select 1 from catalog.items where items.id = book_details.item_id and items.created_by = auth.uid())
);
create policy "Users can update book details for own private items" on catalog.book_details for update to authenticated using (
  exists (select 1 from catalog.items where items.id = book_details.item_id and items.created_by = auth.uid() and items.visibility = 'private')
);

create policy "Tags are readable by authenticated users" on catalog.tags for select to authenticated using (true);
create policy "Users can create tags" on catalog.tags for insert to authenticated with check (created_by = auth.uid());

create policy "Item tags inherit item readability" on catalog.item_tags for select using (
  exists (
    select 1 from catalog.items
    where items.id = item_tags.item_id
      and (items.visibility <> 'private' or items.created_by = auth.uid())
  )
);
create policy "Users can tag own items" on catalog.item_tags for insert to authenticated with check (
  created_by = auth.uid()
  and exists (select 1 from catalog.items where items.id = item_tags.item_id and items.created_by = auth.uid())
);

create policy "File tags inherit file readability" on catalog.file_tags for select using (
  exists (
    select 1
    from catalog.files
    join catalog.items on items.id = files.item_id
    where files.id = file_tags.file_id
      and (items.visibility <> 'private' or items.created_by = auth.uid())
  )
);
create policy "Users can tag own files" on catalog.file_tags for insert to authenticated with check (
  created_by = auth.uid()
  and exists (select 1 from catalog.files where files.id = file_tags.file_id and files.created_by = auth.uid())
);

create policy "Users manage own library items" on library.user_items for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "Users manage own item locations" on library.user_item_locations for all to authenticated using (
  exists (select 1 from library.user_items where user_items.id = user_item_locations.user_item_id and user_items.user_id = auth.uid())
) with check (
  exists (select 1 from library.user_items where user_items.id = user_item_locations.user_item_id and user_items.user_id = auth.uid())
);
create policy "Users manage own file locations" on library.user_file_locations for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "Users manage own notes" on library.notes for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
