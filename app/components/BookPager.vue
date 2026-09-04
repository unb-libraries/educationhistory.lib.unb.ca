<script setup>
const props = defineProps({
  path: {
    type: String,
    required: true,
  },
})

const { data: surroundings } = await useAsyncData(`book-pager-${props.path}`, () =>
  queryCollectionItemSurroundings('book', props.path, { before: 1, after: 1 }))

const { data: firstPage } = await useAsyncData('book-first-page', () =>
  queryCollection('book').order('stem', 'ASC').first())

const previous = computed(() => surroundings.value?.[0] ?? null)
const next = computed(() => surroundings.value?.[1] ?? null)
const up = computed(() => (firstPage.value && firstPage.value.path !== props.path) ? firstPage.value : null)
</script>

<template>
  <ul class="book-pager">
    <li v-if="previous" class="book-pager__item book-pager__item--previous">
      <NuxtLink :to="previous.path">
        ‹ {{ previous.title }}
      </NuxtLink>
    </li>
    <li v-if="up" class="book-pager__item book-pager__item--center">
      <NuxtLink :to="up.path">
        Up
      </NuxtLink>
    </li>
    <li v-if="next" class="book-pager__item book-pager__item--next">
      <NuxtLink :to="next.path">
        {{ next.title }} ›
      </NuxtLink>
    </li>
  </ul>
</template>
