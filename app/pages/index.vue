<script setup>
const { data: bookPages } = await useAsyncData('book-toc', () =>
  queryCollection('book').order('stem', 'ASC').all())

useHead({ title: 'Home' })
</script>

<template>
  <main>
    <h2>The Development of the Theory and Practice of Education in New Brunswick, 1784-1900: A Study in Historical Background</h2>
    <p>Katherine F.C. MacNaughton, M.A. University of New Brunswick Fredericton, New Brunswick, 1947</p>
    <embed src="/files/MacN1947.pdf#view=FitV&amp;zoom=page-height" width="100%" height="600" type="application/pdf">
    <h3>Downloads</h3>
    <ul class="download-list">
      <li><a href="/book/title-page">HTML</a></li>
      <li><a href="/files/MacN1947.pdf">PDF</a></li>
      <li><a href="/files/education_history.epub">ePub (for e-readers)</a></li>
    </ul>
    <h3>Contents</h3>
    <ul>
      <li v-for="entry in bookPages" :key="entry.path">
        <NuxtLink :to="entry.path">
          {{ entry.title }}
        </NuxtLink>
      </li>
    </ul>
  </main>
</template>
