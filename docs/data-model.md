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

Important fields:

- item_id
- filename
- extension
- file_kind
- expected_size_bytes
- checksum_sha256
- notes

### catalog.book_details

Book-specific metadata extending `catalog.items` where `item_type = 'book'`.

Important fields:

- item_id
- isbn_10
- isbn_13
- author_text
- editor_text
- publisher
- publication_date
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
