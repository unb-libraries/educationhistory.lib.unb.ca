<script setup>
import BookPager from '~/components/BookPager.vue'

const route = useRoute()

const { data: page } = await useAsyncData(`book-${route.params.slug}`, () =>
  queryCollection('book').path(route.path).first())

if (!page.value) {
  throw createError({ statusCode: 404, statusMessage: 'Page not found' })
}

useHead({ title: page.value.title })
</script>

<template>
  <main class="book-body">
    <ContentRenderer :value="page" />
    <BookPager :path="page.path" />
  </main>
</template>
