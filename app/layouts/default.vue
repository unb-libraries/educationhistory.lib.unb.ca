<script setup>
const route = useRoute()
const isHome = computed(() => route.path === '/')
</script>

<template>
  <div class="min-h-screen bg-page">
    <NuxtRouteAnnouncer />
    <div class="mx-auto max-w-5xl">
      <div class="bg-header">
        <header class="px-6 pt-[98px] pb-8 mb-10 min-h-[174px] flex items-start bg-[url('/images/zen_master_logo_0.png')] bg-no-repeat [background-position:left_4rem]">
          <h1 v-if="isHome" class="text-3xl font-normal font-header mb-0 ml-[200px]">
            <NuxtLink to="/">
              History of Education in New Brunswick
            </NuxtLink>
          </h1>
          <NuxtLink v-else to="/" class="text-3xl font-normal font-header ml-[200px]">
            History of Education in New Brunswick
          </NuxtLink>
        </header>
        <nav class="flex gap-4 px-6 py-4 font-header">
          <NuxtLink to="/">
            Home
          </NuxtLink>
          <NuxtLink to="/credits">
            Credits
          </NuxtLink>
          <NuxtLink to="/biography">
            Biography
          </NuxtLink>
        </nav>
      </div>
      <div class="bg-content p-6">
        <slot />
      </div>
    </div>
  </div>
</template>
