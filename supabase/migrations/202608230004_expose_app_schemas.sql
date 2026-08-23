grant usage on schema catalog to authenticated;
grant usage on schema library to authenticated;

grant select, insert, update, delete on table catalog.creators to authenticated;
grant select on table catalog.taxonomy_terms to authenticated;
grant select, insert, update, delete on table catalog.items to authenticated;
grant select, insert, update, delete on table catalog.files to authenticated;
grant select, insert, update, delete on table catalog.book_details to authenticated;
grant select, insert, update, delete on table catalog.tags to authenticated;
grant select, insert, update, delete on table catalog.item_tags to authenticated;
grant select, insert, update, delete on table catalog.file_tags to authenticated;

grant select, insert, update, delete on table library.user_items to authenticated;
grant select, insert, update, delete on table library.user_item_locations to authenticated;
grant select, insert, update, delete on table library.user_file_locations to authenticated;
grant select, insert, update, delete on table library.notes to authenticated;
