alter type catalog.item_type add value if not exists 'magazine';
alter type catalog.item_type add value if not exists 'magazine_series';
alter type catalog.item_type add value if not exists 'book_series';

alter table catalog.book_details
  add column if not exists issn text,
  add column if not exists series_title text,
  add column if not exists volume_number text,
  add column if not exists issue_number text,
  add column if not exists issue_date date,
  add column if not exists publication_frequency text;

insert into catalog.taxonomy_terms (id, term_type, name, description)
values
  ('00000000-0000-4000-8000-000000000504', 'document_type', 'Magazine', 'Periodical issue or magazine-style publication.'),
  ('00000000-0000-4000-8000-000000000505', 'document_type', 'Magazine series', 'Recurring magazine or periodical title made up of individual issues.'),
  ('00000000-0000-4000-8000-000000000506', 'document_type', 'Book series', 'Recurring book title or collection made up of individual volumes.')
on conflict (id) do update
set
  term_type = excluded.term_type,
  name = excluded.name,
  description = excluded.description;

insert into catalog.tags (id, name, tag_type, description)
values
  ('00000000-0000-4000-8000-000000001009', 'Magazines', 'media_type', 'Magazines, periodicals, and issue-based publications.'),
  ('00000000-0000-4000-8000-000000001010', 'Magazine series', 'media_type', 'Magazine or periodical series records.'),
  ('00000000-0000-4000-8000-000000001011', 'Book series', 'media_type', 'Book series records made up of individual volume items.')
on conflict (id) do update
set
  name = excluded.name,
  tag_type = excluded.tag_type,
  description = excluded.description;
