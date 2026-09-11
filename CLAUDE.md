# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A static Nuxt 4 site presenting Katherine MacNaughton's 1947 thesis "The Development of the Theory and Practice of Education in New Brunswick, 1784-1900" for the UNB Libraries Electronic Text Centre. Three standalone pages (home, biography, credits), the thesis as an 18-page HTML edition under `/book/`, and the PDF/ePub source documents in `public/files/`. There is no backend, API, database, or state management — this is content, not an application.

## Commands

Package manager is pnpm (`packageManager: pnpm@11.10.0`).

- `pnpm dev` — start dev server, using `NUXT_SITE_URI`/`NUXT_PORT` from `.env` for the public URL and allowed host (defaults to `localhost:3000` if unset)
- `pnpm build` — production build (SSR output)
- `pnpm generate` — static site generation (this is what the Docker production image uses)
- `pnpm preview` — preview a production build locally
- `pnpm lint` / `pnpm lint:fix` — ESLint (`@antfu/eslint-config`) over the whole repo
- `pnpm install` runs `nuxt prepare` via `postinstall` (`scripts/postinstall.mjs`), which skips itself when `CI=true` or `NODE_ENV=production`. That guard lets the Dockerfile install dependencies from the manifests alone, before copying `app/` and `content/`, so a content edit does not reinstall `node_modules`.

There is no test setup configured in this repo. The Husky hooks are **not installed** here: `commitlint.config.ts` enforces a `JIRA-123 subject` header, which rejects the Conventional Commits this repo actually uses, so running `pnpm install` without `HUSKY=0` would leave you unable to commit.

## Architecture

- **Nuxt 4 app directory layout**: source lives under `app/` (`app/layouts/`, `app/pages/`, `app/assets/`), not the Nuxt 3-style root layout. There is no `app/app.vue` — the default layout is the shell.
- **Content model** (`@nuxt/content` v3, `content.config.ts`): one `book` collection, `content/book/NN.<slug>.md`, route `/book/<slug>`. The numeric filename prefix carries reading order and is stripped from the route — it is what `queryCollectionItemSurroundings` sorts on, so renaming a file reorders the book.
- **Routing**: file-based via `app/pages/` — `index.vue`, `biography.vue`, `credits.vue`, and `book/[slug].vue` for the HTML edition.
- **Layout**: `app/layouts/default.vue` is the single shell — header/logo, nav, `<slot />`. The only component is `app/components/BookPager.vue` (previous/next/up).
- **Styling**: Tailwind CSS v4 via the `@tailwindcss/vite` plugin (no `tailwind.config.js` — v4 uses CSS-based config). Theme tokens (colors, fonts) are defined in `app/assets/css/main.css` under `@theme` and consumed as Tailwind utility classes (e.g. `bg-page`, `text-link`, `font-heading`). Global element styling (headings, links, lists) also lives in that file rather than in component-level classes.
- **Static assets**: source documents (`MacN1947.pdf`, `education_history.epub`) and images live in `public/` and are referenced by absolute path (e.g. `/files/MacN1947.pdf`).
- **Analytics**: stock GA4 gtag snippet inlined in `app.head.script` in `nuxt.config.ts` (property `G-DV1EVLKR95`, carried over from Drupal). See README's Analytics section.

## Local development

- Copy `.env` values as needed — `NUXT_PORT` and `NUXT_SITE_URI` drive the dev server's host/port, public URL, and the Vite HMR websocket (which listens on `NUXT_PORT * 10`).
- `docker-compose.yml` runs the `development` target of the `Dockerfile` (bind-mounting `app/`, `public/`, config, and `.nuxt`) and runs `pnpm dev` inside the container, exposing `NUXT_PORT` (3084 by default) and its HMR websocket port (30840) — use `pnpm container:start` for this. This is separate from the production image below.

## Deployment

- **CI**: `.github/workflows/deployment-workflow.yaml` calls `unb-libraries/github-workflows/.github/workflows/build-push-deploy-notify.yaml@1.x` — build → push to GHCR → `kubectl set image` → prune → Slack. Two tags per build: the immutable `<short-sha>-<timestamp>` that the deploy pins, and the mutable `:dev` the Helm chart names for a cold start.
- **`Dockerfile`**: `base` is pure toolchain (no `COPY`, so it stays cached); `build` installs from the manifests *before* copying the rest, so editing `content/` does not reinstall `node_modules`; the final stage is `ghcr.io/unb-libraries/nuxt-ssg:3.23.x`, which carries the nginx config — `try_files`, the `/health` endpoint the chart's probes require, gzip, and the asset cache. There is no per-repo nginx config.
- **`scripts/verify-generate.mjs`** runs in the build stage and fails the build if any page implied by `content/` was not prerendered. `nuxt generate` discovers routes by crawling links, so a lost link in the contents list would otherwise ship a partial site with a green build.
- **Kubernetes**: `unb-libraries/kubernetes-metadata`, `services/educationhistory.lib.unb.ca/02_frontend_nuxt/`, chart `unblib-daemon-nuxt-ssg`, serving `dev-educationhistory.lib.unb.ca`. The `prod` branch still holds the Drupal build and deploys the `unblib-daemon-drupal` component.
- Because the site is generated statically, any change to pages/content requires a rebuild to take effect — there is no server-side rendering at runtime.
