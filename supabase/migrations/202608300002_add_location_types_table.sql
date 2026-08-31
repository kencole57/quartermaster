create table if not exists library.location_types (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint location_types_name_not_blank check (length(btrim(name)) > 0)
);

create unique index if not exists location_types_shared_name_idx
  on library.location_types (lower(name))
  where created_by is null;

create unique index if not exists location_types_user_name_idx
  on library.location_types (created_by, lower(name))
  where created_by is not null;

insert into library.location_types (id, name, description)
values
  ('00000000-0000-4000-8000-000000002001', 'Local drive', 'Files or items kept on the current computer.'),
  ('00000000-0000-4000-8000-000000002002', 'External drive', 'Files or items kept on a removable drive.'),
  ('00000000-0000-4000-8000-000000002003', 'NAS', 'Files or items kept on network attached storage.'),
  ('00000000-0000-4000-8000-000000002004', 'Cloud', 'Files or items kept in cloud storage.'),
  ('00000000-0000-4000-8000-000000002005', 'Archive ZIP', 'Files kept inside an archive file.'),
  ('00000000-0000-4000-8000-000000002006', 'Bookshelf', 'Physical items kept on a shelf.'),
  ('00000000-0000-4000-8000-000000002007', 'Box', 'Physical items kept in a box or tub.'),
  ('00000000-0000-4000-8000-000000002008', 'Office', 'Physical or digital items kept in an office workspace.'),
  ('00000000-0000-4000-8000-000000002009', 'Storage', 'Physical items kept in storage.'),
  ('00000000-0000-4000-8000-000000002010', 'Other', 'Location type not covered by another value.')
on conflict (id) do update
set
  name = excluded.name,
  description = excluded.description;

alter table library.user_item_locations
  add column if not exists location_type_id uuid references library.location_types(id) on delete set null;

alter table library.user_file_locations
  add column if not exists location_type_id uuid references library.location_types(id) on delete set null;

update library.user_item_locations
set location_type_id = location_types.id
from library.location_types
where user_item_locations.location_type_id is null
  and location_types.name = case user_item_locations.location_type::text
    when 'local_drive' then 'Local drive'
    when 'external_drive' then 'External drive'
    when 'nas' then 'NAS'
    when 'cloud' then 'Cloud'
    when 'archive_zip' then 'Archive ZIP'
    when 'bookshelf' then 'Bookshelf'
    when 'box' then 'Box'
    when 'office' then 'Office'
    when 'storage' then 'Storage'
    else 'Other'
  end;

update library.user_file_locations
set location_type_id = location_types.id
from library.location_types
where user_file_locations.location_type_id is null
  and location_types.name = case user_file_locations.location_type::text
    when 'local_drive' then 'Local drive'
    when 'external_drive' then 'External drive'
    when 'nas' then 'NAS'
    when 'cloud' then 'Cloud'
    when 'archive_zip' then 'Archive ZIP'
    when 'bookshelf' then 'Bookshelf'
    when 'box' then 'Box'
    when 'office' then 'Office'
    when 'storage' then 'Storage'
    else 'Other'
  end;

create index if not exists user_item_locations_location_type_id_idx on library.user_item_locations (location_type_id);
create index if not exists user_file_locations_location_type_id_idx on library.user_file_locations (location_type_id);

alter table library.location_types enable row level security;

create policy "Location types are readable when shared or owned" on library.location_types for select to authenticated using (created_by is null or created_by = auth.uid());
create policy "Users can create location types" on library.location_types for insert to authenticated with check (created_by = auth.uid());
create policy "Users can update own location types" on library.location_types for update to authenticated using (created_by = auth.uid()) with check (created_by = auth.uid());
create policy "Users can delete own location types" on library.location_types for delete to authenticated using (created_by = auth.uid());

grant select, insert, update, delete on table library.location_types to authenticated;
