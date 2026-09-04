import defineConfig from '@antfu/eslint-config'

export default defineConfig({
  type: 'app',
  ignores: [
    './.husky',
  ],
  typescript: true,
}, {
  rules: {
    'import/consistent-type-specifier-style': ['error', 'prefer-top-level'],
    'ts/consistent-type-definitions': ['off'],
  },
})
