create policy "Users can remove tags from own items" on catalog.item_tags for delete to authenticated using (
  exists (
    select 1
    from catalog.items
    where items.id = item_tags.item_id
      and items.created_by = auth.uid()
  )
);
