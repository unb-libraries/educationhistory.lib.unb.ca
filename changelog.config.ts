import type { ChangelogConfig } from 'changelogen'

export default {
  hideAuthorEmail: true,
  types: {
    feat: { title: '🚀 Enhancements', semver: 'minor' },
    perf: { title: '🔥 Performance', semver: 'patch' },
    fix: { title: '🩹 Fixes', semver: 'patch' },
    refactor: { title: '💅 Refactors', semver: 'patch' },
    docs: { title: '📖 Documentation', semver: 'patch' },
    ops: { title: '🏡 Ops' },
    test: { title: '✅ Tests' },
  },
  templates: {
    commitMessage: 'ops(release): v{{newVersion}}',
    tagMessage: 'v{{newVersion}}',
    tagBody: 'v{{newVersion}}',
  },
} satisfies Partial<ChangelogConfig>
