// Skipped in CI and in the Docker build so the image can install from the manifests
// alone, before app/ and content/ are copied. `nuxt build`/`generate` prepare themselves.
// Mirrors .husky/install.mjs.

import { spawnSync } from 'node:child_process'
import process from 'node:process'

if (process.env.CI === 'true' || process.env.NODE_ENV === 'production')
  process.exit(0)

const { status } = spawnSync('nuxt', ['prepare'], { stdio: 'inherit', shell: true })
process.exit(status ?? 1)
