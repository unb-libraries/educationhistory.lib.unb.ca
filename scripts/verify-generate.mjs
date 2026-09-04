#!/usr/bin/env node
// Assert `nuxt generate` produced every page content/ implies. Nitro finds routes by
// crawling links, so a lost link in the contents page would silently ship a partial site.

import { existsSync, readdirSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import process from 'node:process'
import { fileURLToPath } from 'node:url'

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const OUT = join(ROOT, '.output', 'public')

const BOOK_FILE = /^\d+\.(.+)\.md$/

const bookSlugs = readdirSync(join(ROOT, 'content', 'book'))
  .map(f => f.match(BOOK_FILE))
  .filter(Boolean)
  .map(m => m[1])

const expected = ['/', '/biography', '/credits', ...bookSlugs.map(s => `/book/${s}`)]

// From nitro.prerender.routes; app.conf serves it via error_page.
const files = ['404.html', ...expected.map(r => (r === '/' ? 'index.html' : r.slice(1)))]

const missing = files.filter((f) => {
  if (f.endsWith('.html'))
    return !existsSync(join(OUT, f))
  // try_files serves either shape.
  return !existsSync(join(OUT, f, 'index.html')) && !existsSync(join(OUT, `${f}.html`))
})

if (missing.length) {
  console.error(`\nnuxt generate did not produce ${missing.length} of ${files.length} expected pages:`)
  for (const f of missing) console.error(`  - /${f}`)
  console.error('\nCheck that every route is reachable by a server-rendered link, or add it')
  console.error('to nitro.prerender.routes in nuxt.config.ts.\n')
  process.exit(1)
}

console.log(`verify-generate: ${files.length} expected pages present in .output/public`)
