# Security

## Supabase Keys

Only publishable/anon keys belong in frontend code.

Never commit:

- Supabase secret keys.
- Supabase service-role keys.
- Database passwords.
- Personal access tokens.

If a secret is exposed, rotate it in Supabase immediately.

## Row Level Security

Quartermaster uses Supabase Row Level Security as a core part of the design.

Expected defaults:

- User library records are only visible to their owner.
- Private catalog records are only visible to their creator.
- Shared catalog records may be visible to other authenticated users.
- Public or community catalog workflows should be explicitly designed before enabling broad edits.

Every new table in app-controlled schemas should have RLS enabled and policies defined in a migration.
