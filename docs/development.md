# Development

## Prerequisites

- Node.js 20 or later.
- npm.
- A Supabase project for remote development.

Docker is only required when running the full local Supabase stack.

## Local Setup

Install dependencies:

```sh
npm install
```

Create a local `.env` file from `.env.example`:

```sh
cp .env.example .env
```

Set:

```text
VITE_SUPABASE_URL=
VITE_SUPABASE_PUBLISHABLE_KEY=
```

Never put Supabase secret/service-role keys in `.env` files used by the frontend.

## Run The App

```sh
npm run dev
```

Default local URL:

```text
http://localhost:5173/
```

## Build Check

```sh
npm run check
```

This currently runs the production Vite build.

## Supabase

Supabase project:

```text
vollglfitpbllbwbaulx
```

Schema changes should be made through migration files in:

```text
supabase/migrations/
```

Avoid making schema changes directly in the dashboard once migrations are active, otherwise the remote database can drift away from the repo.

The Supabase CLI is installed as a project dev dependency. Use it through npm scripts:

```sh
npm run supabase -- --version
npm run db:push
```

If the project is not linked yet, link it before pushing migrations:

```sh
npm run supabase -- link --project-ref vollglfitpbllbwbaulx
```

## Responsive Checks

Use Chrome DevTools device mode and follow:

```text
docs/responsive-testing.md
```

At minimum, check one phone viewport, one tablet or Surface-width viewport, and one desktop viewport before merging meaningful UI changes.
