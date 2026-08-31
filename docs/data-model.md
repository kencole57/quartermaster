# Initial Data Model

Use dedicated schemas where practical:

- `catalog`: shared or reusable item metadata.
- `library`: user-specific ownership, locations, status, and notes.
- `public`: Supabase auth-facing profile records.

## Catalog

### catalog.creators

People, companies, studios, publishers, archives, or organizations that create or release material.

### catalog.items

Top-level reusable catalog entity. This intentionally supports both packages and standalone assets.

Example item types:

- package
- book
- book_series
- magazine
- magazine_series
- document
- stl_model
- cad_model
- map
- photo
- video
- audio
- rules
- scenario
- reference
- note
- other

Important fields:

- parent_item_id
- creator_id
- title
- subtitle
- item_type
- description
- historical_period_id
- conflict_id
- theatre_id
- faction_id
- date_start
- date_end
- source_url
- publication_date
- visibility
- created_by

### catalog.files

File metadata only. Stage 1 stores expected file information and identity, not the actual binary file.

STL packages should be represented as parent `catalog.items` records with `item_type = 'package'`.
Individual printable models inside the package should be represented as child `catalog.items` records
with `item_type = 'stl_model'`. Each model can have one or more `catalog.files` records, because a
single model may include unsupported, supported, presupported, base, variant, or source/project files.

Use `catalog.items.source_url` at the package or model level, not the file level. For a package,
`source_url` should point to the creator store, Kickstarter, campaign, bundle, or product page. For a
standalone model purchased directly, `source_url` should live on the `stl_model` item and point to the
model's own product page.

Important fields:

- item_id
- filename
- extension
- file_kind
- expected_size_bytes
- checksum_sha256
- notes

### catalog.book_details

Publication-specific metadata extending `catalog.items` for books and magazine issues.

Magazine series should be represented as a `catalog.items` record with `item_type = 'magazine_series'`.
Individual issues should be represented as child `catalog.items` records with `item_type = 'magazine'`
and `parent_item_id` pointing to the series record. This keeps series-level metadata, issue-level
metadata, files, ownership, and locations independently trackable.

Book series should follow the same parent/child pattern. Represent the series as a parent
`catalog.items` record with `item_type = 'book_series'`, and represent each individual volume as a
child `catalog.items` record with `item_type = 'book'` and `parent_item_id` pointing to the series
record. Child books should keep their own title and ISBN metadata, while defaulting `series_title`,
period, and conflict from the parent series where appropriate.

Important fields:

- item_id
- isbn_10
- isbn_13
- issn
- author_text
- editor_text
- publisher
- publication_date
- series_title
- volume_number
- issue_number
- issue_date
- publication_frequency
- edition
- printing
- language
- page_count
- format
- oclc_number
- lccn
- dewey_decimal

### catalog.tags

Shared tags and controlled vocabulary terms.

### catalog.item_tags

Many-to-many tags for catalog items.

### catalog.file_tags

Many-to-many tags for catalog files.

## Library

### library.user_items

A user's relationship to a catalog item.

Important fields:

- user_id
- item_id
- ownership_status
- acquired_date
- acquired_from
- price_paid
- condition
- personal_rating
- personal_notes

### library.user_item_locations

Where a user's copy of an item lives.

Important fields:

- user_item_id
- location_type
- location_label
- path_or_detail
- verified_at
- missing_at
- notes

### library.location_types

Location type vocabulary shared by item and file locations. Initial seed values are shared defaults
covering common broad categories such as local drive, external drive, NAS, cloud, archive ZIP,
bookshelf, box, office, storage, and other. Users can add their own location types when the default
list does not fit; user-created location types are visible to that user, not globally shared.

Location labels are also user-specific because they are stored on `library.user_item_locations` or
`library.user_file_locations`, not on shared catalog records.

Important fields:

- name
- description
- created_by

### library.location_roots

Reusable user-specific shortcuts for common storage roots. A root can represent a drive, NAS share,
cloud folder, bookshelf, storage box, or other repeated location. Selecting a root in an item or file
location form pre-fills location type, label, and base path while still saving ordinary location text
on the final location record.

Important fields:

- user_id
- location_type_id
- label
- base_path
- notes

### library.user_file_locations

Where a user's copy of a specific file lives.

Important fields:

- user_id
- file_id
- location_type
- root_label
- path_text
- verified_at
- missing_at
- notes

### library.notes

User notes or comments on items/files.

Important fields:

- user_id
- entity_type
- entity_id
- body
- visibility
