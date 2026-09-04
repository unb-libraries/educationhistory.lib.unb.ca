import type { UserConfig } from '@commitlint/types'

export default {
  // Team format is "JIRA-123 subject", not Conventional Commits.
  // "type" below captures the Jira ticket key so the stock type-empty/subject-empty
  // rules can validate it without a custom rule implementation.
  parserPreset: {
    parserOpts: {
      headerPattern: /^([A-Z][A-Z0-9]+-\d+)\s+(\S.*)$/,
      headerCorrespondence: ['type', 'subject'],
    },
  },
  rules: {
    'type-empty': [2, 'never'],
    'subject-empty': [2, 'never'],
  },
} satisfies UserConfig
