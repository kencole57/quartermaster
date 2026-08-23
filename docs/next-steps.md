# Next Steps

This checklist is the working project tracker for Quartermaster. Keep it practical and update it as tasks are completed.

## Foundation

- [x] Choose working app name: Quartermaster.
- [x] Create public GitHub repository.
- [x] Create local project folder and git repository.
- [x] Push initial project notes.
- [x] Create Supabase project.
- [x] Add Vue, Vite, Vuetify, and Supabase app scaffold.
- [x] Add responsive app shell.
- [x] Add mobile/table view-mode pattern.
- [x] Document responsive testing targets.
- [x] Add development setup notes.
- [x] Add contribution and security notes.
- [x] Pin Supabase CLI as a project dev dependency.

## Supabase Setup

- [x] Add local Supabase project config.
- [x] Add initial `catalog` and `library` schema migration.
- [x] Add initial RLS policies.
- [ ] Confirm Supabase GitHub integration settings.
- [ ] Apply initial migration to the remote Supabase project.
- [ ] Confirm generated tables, schemas, and policies in Supabase.
- [ ] Add seed data for development examples.

## Auth And User Shell

- [ ] Add sign-in/sign-out UI.
- [ ] Add profile bootstrap flow.
- [ ] Add authenticated route guard.
- [ ] Show current user/account state in the app shell.

## Catalog MVP

- [ ] Create catalog item list view.
- [ ] Create catalog item detail view.
- [ ] Create add/edit catalog item form.
- [ ] Support item types: package, book, document, STL model, map, photo, reference, other.
- [ ] Add creator list and creator CRUD.
- [ ] Add file metadata list for an item.
- [ ] Add book details fields.
- [ ] Add tags and item tag assignment.

## Library MVP

- [ ] Add user ownership record for catalog items.
- [ ] Add user item locations.
- [ ] Add user file locations.
- [ ] Add personal notes.
- [ ] Add ownership/status fields: owned, wishlist, borrowed, lent out, sold, archived.

## Search And Filtering

- [ ] Add text search against catalog item title, subtitle, and description.
- [ ] Add filters for item type, creator, period, conflict, theatre, faction, and tag.
- [ ] Add mobile-friendly search results list mode.
- [ ] Add table mode for desktop and Surface use.

## Data Modeling Follow-Ups

- [ ] Revisit whether `catalog.visibility` should include `public` separately from `shared`.
- [ ] Define moderation/contribution model for shared catalog records.
- [ ] Decide how private user-created catalog records become shared records.
- [ ] Add taxonomy seed terms for periods, conflicts, theatres, factions, and document types.
- [ ] Decide how to represent battles and operations.

## Responsive UX Checks

Before each meaningful UI milestone, check the targets listed in `docs/responsive-testing.md`.

- [ ] Narrow phone check.
- [ ] Standard phone check.
- [ ] Landscape phone check.
- [ ] Small tablet check.
- [ ] Surface Pro / large tablet check.
- [ ] Desktop check.

## Stage 2 Candidates

- [ ] Folder scan/import workflow.
- [ ] Checksum duplicate detection.
- [ ] ISBN lookup for books.
- [ ] PDF text extraction.
- [ ] STL preview and thumbnail metadata.
- [ ] Optional managed storage.
- [ ] Google Drive, Dropbox, OneDrive, or NAS integrations.
- [ ] Semantic search.
