insert into catalog.taxonomy_terms (id, term_type, name, description)
values
  ('00000000-0000-4000-8000-000000000101', 'historical_period', 'Second World War', 'Global conflict from 1939 to 1945.'),
  ('00000000-0000-4000-8000-000000000102', 'historical_period', 'Cold War', 'Post-Second World War geopolitical and military period.'),
  ('00000000-0000-4000-8000-000000000103', 'historical_period', 'Vietnam War', 'Conflict in Vietnam, Laos, and Cambodia.'),
  ('00000000-0000-4000-8000-000000000201', 'conflict', 'Vietnam War', 'Conflict in Vietnam, Laos, and Cambodia.'),
  ('00000000-0000-4000-8000-000000000202', 'conflict', 'Second World War', 'Global conflict from 1939 to 1945.'),
  ('00000000-0000-4000-8000-000000000301', 'theatre', 'Phuoc Tuy Province', 'Province in South Vietnam relevant to Australian operations.'),
  ('00000000-0000-4000-8000-000000000302', 'theatre', 'Western Europe', 'European theatre and Cold War central front context.'),
  ('00000000-0000-4000-8000-000000000401', 'faction', 'Australian Army', 'Australian land forces.'),
  ('00000000-0000-4000-8000-000000000402', 'faction', 'West Germany', 'Federal Republic of Germany forces and subjects.'),
  ('00000000-0000-4000-8000-000000000403', 'faction', 'Germany', 'German forces and subjects.'),
  ('00000000-0000-4000-8000-000000000501', 'document_type', 'Battle report', 'After action or battle-specific report.'),
  ('00000000-0000-4000-8000-000000000502', 'document_type', 'Book', 'Published monograph or book-length work.'),
  ('00000000-0000-4000-8000-000000000503', 'document_type', 'STL package', 'Collection of 3D printable model files.')
on conflict (id) do update
set
  term_type = excluded.term_type,
  name = excluded.name,
  description = excluded.description;

insert into catalog.tags (id, name, tag_type, description)
values
  ('00000000-0000-4000-8000-000000001001', 'Vietnam War', 'period', 'Vietnam War material.'),
  ('00000000-0000-4000-8000-000000001002', 'Battle reports', 'document', 'After action and battle reports.'),
  ('00000000-0000-4000-8000-000000001003', 'Cold War', 'period', 'Cold War material.'),
  ('00000000-0000-4000-8000-000000001004', 'STL', 'file_type', '3D printable STL material.'),
  ('00000000-0000-4000-8000-000000001005', 'Books', 'media_type', 'Books and monographs.'),
  ('00000000-0000-4000-8000-000000001006', 'Maps', 'media_type', 'Maps and geographic references.'),
  ('00000000-0000-4000-8000-000000001007', 'Kickstarter', 'source', 'Kickstarter-sourced packages.'),
  ('00000000-0000-4000-8000-000000001008', 'Australian Army', 'faction', 'Australian Army related material.')
on conflict (id) do update
set
  name = excluded.name,
  tag_type = excluded.tag_type,
  description = excluded.description;
