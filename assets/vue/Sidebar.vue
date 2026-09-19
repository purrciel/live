<script setup lang="ts">
import { Link } from 'live_vue'
import { onMounted, ref } from 'vue'

interface Channel {
  id: string | number
  username: string
  avatar_url?: string
  category?: string
  viewers_count?: number
  is_live: boolean
}

const props = defineProps<{
  channels: Channel[]
}>()

// Состояние сворачивания (по умолчанию проверяем localStorage)
const isCollapsed = ref(false)

onMounted(() => {
  const saved = localStorage.getItem('sidebar_collapsed')
  if (saved !== null) {
    isCollapsed.value = JSON.parse(saved)
  }
})

function toggleSidebar() {
  isCollapsed.value = !isCollapsed.value
  localStorage.setItem('sidebar_collapsed', JSON.stringify(isCollapsed.value))
}
</script>

<template>
  <aside
    :class="[
      'bg-base-200/90 backdrop-blur-md h-full border-r border-base-300 flex flex-col justify-between p-3 transition-all duration-300 ease-in-out select-none',
      isCollapsed ? 'w-16' : 'w-64'
    ]"
  >
    <div class="space-y-4">
      <!-- Header / Toggle Button -->
      <div class="flex items-center justify-between px-1">
        <span
          v-if="!isCollapsed"
          class="text-[10px] font-bold uppercase tracking-widest text-base-content/40 transition-opacity duration-200"
        >
          For You
        </span>

        <button
          @click="toggleSidebar"
          class="btn btn-ghost btn-xs btn-square text-base-content/60 hover:text-primary ml-auto"
          :title="isCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar'"
        >
          <!-- Heroicon: Arrow Left / Right -->
          <svg v-if="!isCollapsed" class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 19l-7-7 7-7m8 14l-7-7 7-7" />
          </svg>
          <svg v-else class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 5l7 7-7 7M5 5l7 7-7 7" />
          </svg>
        </button>
      </div>

      <!-- Navigation Section -->
      <nav class="space-y-1">
        <ul class="menu menu-sm p-0 space-y-1">
          <li>
            <Link
              navigate="/"
              class="flex items-center gap-3 py-2.5 px-2.5 rounded-xl hover:bg-base-300/70 font-medium"
              :class="{ 'justify-center': isCollapsed }"
            >
              <svg class="size-5 text-primary shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
              </svg>
              <span v-if="!isCollapsed" class="text-sm truncate">Home</span>
            </Link>
          </li>
          <li>
            <Link
              navigate="/dashboard"
              class="flex items-center gap-3 py-2.5 px-2.5 rounded-xl hover:bg-base-300/70 font-medium"
              :class="{ 'justify-center': isCollapsed }"
            >
              <svg class="size-5 text-secondary shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" />
              </svg>
              <span v-if="!isCollapsed" class="text-sm truncate">Browse</span>
            </Link>
          </li>
        </ul>
      </nav>

      <div class="divider my-2 opacity-50"></div>

      <!-- Recommended Channels -->
      <div class="space-y-2">
        <div v-if="!isCollapsed" class="px-1 flex items-center justify-between">
          <span class="text-[10px] font-bold uppercase tracking-widest text-base-content/40">
            Recommended Channels
          </span>
          <span class="size-2 rounded-full bg-error animate-pulse"></span>
        </div>

        <ul class="space-y-1">
          <li v-for="user in props.channels" :key="user.id">
            <Link
              :navigate="`/c/${user.username}`"
              class="group relative flex items-center gap-3 p-2 rounded-xl hover:bg-base-300/80 transition-all duration-150"
              :class="{ 'justify-center': isCollapsed }"
            >
              <!-- Avatar with Ring -->
              <div class="relative shrink-0">
                <div
                  class="w-8 h-8 rounded-full overflow-hidden ring-2 ring-offset-2 ring-offset-base-200 transition-all"
                  :class="user.is_live ? 'ring-error' : 'ring-base-300 opacity-60'"
                >
                  <img
                    :src="user.avatar_url || `https://api.dicebear.com/7.x/bottts/svg?seed=${user.username}`"
                    :alt="user.username"
                    class="w-full h-full object-cover"
                  />
                </div>
                <span
                  v-if="user.is_live && isCollapsed"
                  class="absolute -top-0.5 -right-0.5 size-2.5 rounded-full bg-error ring-2 ring-base-200"
                ></span>
              </div>

              <!-- Channel Info (Expanded Mode) -->
              <div v-if="!isCollapsed" class="flex-1 overflow-hidden flex items-center justify-between">
                <div class="flex flex-col overflow-hidden pr-2">
                  <span class="font-semibold text-xs truncate group-hover:text-primary transition-colors">
                    {{ user.username }}
                  </span>
                  <span class="text-[11px] text-base-content/50 truncate">
                    {{ user.category || 'Just Chatting' }}
                  </span>
                </div>

                <div v-if="user.is_live" class="flex items-center gap-1 shrink-0">
                  <span class="size-1.5 rounded-full bg-error animate-pulse"></span>
                  <span class="text-[11px] font-mono text-base-content/70">
                    {{ user.viewers_count || 0 }}
                  </span>
                </div>
              </div>

              <!-- Floating Tooltip (Collapsed Mode UX) -->
              <div
                v-if="isCollapsed"
                class="absolute left-full ml-3 hidden group-hover:flex flex-col bg-base-300/95 backdrop-blur-md p-3 rounded-2xl shadow-2xl border border-base-100 z-50 w-48 pointer-events-none transition-all animate-in fade-in zoom-in-95"
              >
                <div class="flex items-center justify-between mb-1">
                  <span class="font-bold text-xs text-base-content">{{ user.username }}</span>
                  <span v-if="user.is_live" class="badge badge-error badge-xs font-semibold">LIVE</span>
                </div>
                <span class="text-[11px] text-base-content/60 mb-2">{{ user.category || 'Just Chatting' }}</span>
                <div v-if="user.is_live" class="text-[10px] text-error font-mono flex items-center gap-1">
                  <span class="size-1.5 rounded-full bg-error"></span>
                  {{ user.viewers_count || 0 }} viewers
                </div>
              </div>
            </Link>
          </li>
        </ul>
      </div>
    </div>

    <!-- Bottom Footer Status -->
    <div
      class="border-t border-base-300/60 pt-3 flex items-center text-xs text-base-content/40"
      :class="isCollapsed ? 'justify-center' : 'justify-between px-1'"
    >
      <span v-if="!isCollapsed" class="text-[11px]">OxygenLive</span>
      <div class="size-2 rounded-full bg-success" title="Server Online"></div>
    </div>
  </aside>
</template>
