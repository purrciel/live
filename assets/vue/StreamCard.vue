<script setup lang="ts">
import { Link } from 'live_vue'
import { ref } from 'vue'
import VideoPlayer from './VideoPlayer.vue'; // Ваш плеер на hls.js

interface Channel {
  username: string
  avatar_url?: string
  stream_title?: string
  category?: string
  is_live: boolean
  stream_url?: string // Ссылка на playlist.m3u8
}

const props = defineProps<{
  channel: Channel
}>()

const isHovered = ref(false)
let hoverTimeout: any = null

// Небольшая задержка перед запуском плеера (200мс),
// чтобы не грузить поток, если пользователь просто быстро скроллит
function handleMouseEnter() {
  if (!props.channel.is_live || !props.channel.stream_url) return
  hoverTimeout = setTimeout(() => {
    isHovered.value = true
  }, 250)
}

function handleMouseLeave() {
  if (hoverTimeout) clearTimeout(hoverTimeout)
  isHovered.value = false
}
</script>

<template>
  <Link
    :navigate="`/c/${channel.username}`"
    class="group bg-base-200 rounded-2xl overflow-hidden border border-base-300 hover:border-primary transition-all duration-200 hover:shadow-2xl flex flex-col"
    @mouseenter="handleMouseEnter"
    @mouseleave="handleMouseLeave"
  >
    <!-- Video Preview Area -->
    <div class="aspect-video bg-base-300 relative overflow-hidden flex items-center justify-center">
      <!-- Live Badge -->
      <span
        v-if="channel.is_live"
        class="absolute top-3 left-3 badge badge-error text-white font-semibold text-xs z-20 shadow-md"
      >
        LIVE
      </span>
      <span
        v-else
        class="absolute top-3 left-3 badge badge-neutral text-xs z-20"
      >
        OFFLINE
      </span>

      <!-- Live Stream Preview (запускается при hover) -->
      <template v-if="channel.is_live">
        <div v-if="isHovered && channel.stream_url" class="absolute inset-0 z-10 animate-in fade-in duration-300">
          <!-- Наш HLS плеер без контролов и с muted=true для превью -->
          <VideoPlayer
            :stream-url="channel.stream_url"
            :autoplay="true"
            class="w-full h-full pointer-events-none object-cover"
          />
          <span class="absolute bottom-2 right-2 badge badge-xs bg-black/60 text-white border-none z-20">
            Live Preview
          </span>
        </div>

        <!-- Static Fallback (пока мышка не навелась) -->
        <div v-else class="flex flex-col items-center justify-center gap-2">
          <div class="w-16 h-16 rounded-full bg-primary/10 flex items-center justify-center group-hover:scale-110 transition-transform">
            <svg class="size-8 text-primary opacity-80" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z" />
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
        </div>
      </template>

      <!-- Offline Placeholder -->
      <template v-else>
        <svg class="size-10 text-base-content/30" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636" />
        </svg>
      </template>
    </div>

    <!-- Info Section -->
    <div class="p-4 flex gap-3">
      <div class="avatar flex-none">
        <div class="w-10 h-10 rounded-full ring-2 ring-primary/20 group-hover:ring-primary transition-all overflow-hidden">
          <img
            :src="channel.avatar_url || `https://api.dicebear.com/7.x/bottts/svg?seed=${channel.username}`"
            :alt="channel.username"
          />
        </div>
      </div>

      <div class="flex-1 min-w-0">
        <h3 class="font-bold text-base truncate group-hover:text-primary transition-colors">
          {{ channel.username }}
        </h3>
        <p class="text-xs text-base-content/70 truncate">
          {{ channel.stream_title || "No stream title" }}
        </p>
        <div class="mt-2">
          <span class="badge badge-sm badge-outline text-[10px]">
            {{ channel.category || "Just Chatting" }}
          </span>
        </div>
      </div>
    </div>
  </Link>
</template>
