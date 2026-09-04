# educationhistory.lib.unb.ca

UNB Libraries' Electronic Text Centre presentation of Katherine MacNaughton's 1947 thesis
*The Development of the Theory and Practice of Education in New Brunswick, 1784-1900* — a
small, static Nuxt 4 site with no backend, API, or database.

## Getting started

Copy `.env` values as needed first — `NUXT_PORT` and `NUXT_SITE_URI` drive the dev server's
host/port, public URL, and Vite HMR websocket (defaults to `localhost:3000` if unset).

### Run with Docker

Requires only [Docker](https://www.docker.com) — the container brings its own Node and pnpm.

```bash
docker compose up
```

This bind-mounts `app/`, `public/`, `nuxt.config.ts`, `package.json`, and `pnpm-lock.yaml`
into the container and runs `pnpm dev` inside it, exposing `NUXT_PORT` (3084 by default) and
its HMR websocket on `NUXT_PORT * 10` (30840). Once you have pnpm on the host,
`pnpm container:start` is the same command.

### Run locally

Requires [Node.js](https://nodejs.org) `^20.19 || >=22.12` (Vite 7's floor — the Docker
images use Node 26) and [pnpm](https://pnpm.io) 11.10.0.

```bash
pnpm install
pnpm dev
```

pnpm is most easily installed through Corepack, which picks up the version pinned by
`packageManager` in `package.json`:

```bash
corepack enable pnpm
```

If the Node.js your system provides is older than the range above, install a current
release with a version manager such as [fnm](https://github.com/Schniz/fnm),
[nvm](https://github.com/nvm-sh/nvm), [Volta](https://volta.sh), or
[mise](https://mise.jdx.dev) rather than replacing the system package.

### Configuration

Settings are defined in `nuxt.config.ts`. `NUXT_PORT` and `NUXT_SITE_URI` are read from
`.env` for local development; in production they're set directly as container environment
variables in the `Dockerfile`.

## Development

| Command | Description |
| --- | --- |
| `pnpm dev` | Start the dev server |
| `pnpm build` | Production build (SSR output) |
| `pnpm generate` | Static site generation — this is what the production Docker image uses |
| `pnpm preview` | Preview a production build locally |
| `pnpm lint` / `pnpm lint:fix` | ESLint (`@antfu/eslint-config`) over the whole repo |

Husky git hooks enforce code quality on commit: `pre-commit` runs `lint-staged` (ESLint
`--fix` on staged files), `commit-msg` runs `commitlint` against Conventional Commits,
restricted to the types in `commitlint.config.ts` (`feat`, `fix`, `perf`, `refactor`,
`test`, `ops`, `docs`).

There is no test setup configured in this repo.

### Structure

- `app/pages/*.vue` — file-based routes: `index.vue`, `biography.vue`, `credits.vue`, plus
  `book/[slug].vue` for the HTML edition. Each sets its own title via
  `useHead({ title: '...' })`; the global title template is set in `nuxt.config.ts`.
- `app/layouts/default.vue` — the single shell (header/logo, nav, `<slot />`). The only
  component is `app/components/BookPager.vue` (previous/next/up links).
- `content/book/` — the thesis as 18 Markdown pages (front matter, chapters 1–10,
  bibliography), read through `@nuxt/content`'s `book` collection (`content.config.ts`). The
  numeric filename prefix carries reading order and is stripped from the route.
- `app/assets/css/main.css` — Tailwind CSS v4 theme tokens (`@theme`) and global element
  styling (headings, links, lists), consumed as utility classes (e.g. `bg-page`,
  `text-link`, `font-heading`). Book-specific rules are scoped under `.book-body` so they
  don't leak into the other pages. No `tailwind.config.js` — v4 uses CSS-based config.
- `public/files/` — source documents (`MacN1947.pdf`, `education_history.epub`), referenced
  by absolute path (e.g. `/files/MacN1947.pdf`).

### Adding or changing book content

Add a `content/book/NN.<slug>.md` file with the numeric prefix at the right position — the
pager and the home page's contents list both derive from that order, so nothing else needs
editing. `nuxt generate` discovers book routes by crawling the links rendered on `/`, so a
page nothing links to will not be prerendered; `scripts/verify-generate.mjs` fails the build
if that happens.

## Deployment

`.github/workflows/deployment-workflow.yaml` calls the shared pipeline in
[`unb-libraries/github-workflows`](https://github.com/unb-libraries/github-workflows): build
the image, push it to GHCR, then `kubectl set image` on the Kubernetes deployment. A push to
`dev` deploys to the `dev` namespace as `dev-educationhistory.lib.unb.ca`; the `prod` branch
still holds the Drupal build and deploys prod on its own workflow.

The `Dockerfile` runs `pnpm generate` in a throw-away stage and serves the result from
[`ghcr.io/unb-libraries/nuxt-ssg`](https://github.com/unb-libraries/docker-nuxt-ssg), which
carries the nginx configuration for a generated Nuxt site. The build fails if the site is
incomplete: `scripts/verify-generate.mjs` derives the expected routes from `content/` and
asserts every page was prerendered.

Because the site is generated statically, any change to pages or content requires a
rebuild — there is no server-side rendering at runtime.

## Entry points

- `/` — home page: embedded PDF, download links, and the table of contents.
- `/biography` — biography of Katherine MacNaughton.
- `/credits` — credits page.
- `/book/<slug>` — the HTML edition, one route per manifest entry (e.g. `/book/title-page`,
  `/book/chapter-1`, `/book/bibliography`). Page-number anchors (`#p85`) are stable and used
  for cross-references; `.pagenum` markers also deep-link into the PDF.
- `/files/MacN1947.pdf`, `/files/education_history.epub` — the thesis source documents.
