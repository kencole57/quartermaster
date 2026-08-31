create table if not exists library.location_roots (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  location_type_id uuid references library.location_types(id) on delete set null,
  label text not null,
  base_path text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint location_roots_label_not_blank check (length(btrim(label)) > 0),
  unique (user_id, label)
);

create index if not exists location_roots_user_id_idx on library.location_roots (user_id);
create index if not exists location_roots_location_type_id_idx on library.location_roots (location_type_id);

alter table library.location_roots enable row level security;

create policy "Users manage own location roots" on library.location_roots for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

grant select, insert, update, delete on table library.location_roots to authenticated;
