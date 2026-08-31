create policy "Authenticated users can create taxonomy terms"
on catalog.taxonomy_terms
for insert
to authenticated
with check (term_type in ('historical_period', 'conflict', 'theatre', 'faction', 'document_type'));

insert into catalog.taxonomy_terms (id, term_type, name, description)
values
  ('00000000-0000-4000-8000-000000000104', 'historical_period', 'Generic', 'General or non-period-specific material.'),
  ('00000000-0000-4000-8000-000000000203', 'conflict', 'Generic', 'General or non-conflict-specific material.')
on conflict (term_type, name) do update
set description = excluded.description;
