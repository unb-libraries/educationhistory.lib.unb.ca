import { defineCollection, defineContentConfig, z } from '@nuxt/content'

export default defineContentConfig({
  collections: {
    book: defineCollection({
      type: 'page',
      source: 'book/*.md',
      schema: z.object({
        title: z.string(),
        oldPath: z.string(),
      }),
    }),
  },
})
