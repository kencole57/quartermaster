# Contributing

Quartermaster is early-stage. The immediate goal is to keep the data model, UX direction, and Supabase security model easy to reason about.

## Working Agreements

- Keep catalog data separate from user library data.
- Treat Supabase RLS as required, not optional.
- Do not commit secrets.
- Prefer small, focused changes.
- Update `docs/next-steps.md` when completing tracked work.
- Check mobile and Surface/tablet layouts for UI changes.

## Before Committing

Run:

```sh
npm run check
```

For database changes, add or update migration files under:

```text
supabase/migrations/
```

## UX Direction

Quartermaster should support both:

- Dense table-oriented workflows for desktop and Surface use.
- Touch-friendly list/capture workflows for phone use.

When a screen is data-heavy, consider whether it needs both table mode and list mode.
