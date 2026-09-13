<script setup>
import Hls from 'hls.js'
import { onMounted, onUnmounted, ref, watch } from 'vue'

const props = defineProps({
  streamUrl: {
    type: String,
    required: true
  },
  autoplay: {
    type: Boolean,
    default: true
  }
})

const videoRef = ref(null)
let hlsInstance = null

const initPlayer = () => {
  if (!videoRef.value || !props.streamUrl) return

  // Очищаем прошлый экземпляр Hls при смене streamUrl
  if (hlsInstance) {
    hlsInstance.destroy()
    hlsInstance = null
  }

  // 1. Проверяем поддержку Hls.js
  if (Hls.isSupported()) {
    hlsInstance = new Hls({
      enableWorker: true,
      lowLatencyMode: true,
      backBufferLength: 90
    })

    hlsInstance.loadSource(props.streamUrl)
    hlsInstance.attachMedia(videoRef.value)

    hlsInstance.on(Hls.Events.MANIFEST_PARSED, () => {
      if (props.autoplay) {
        videoRef.value.play().catch(() => {
          // Если браузер заблокировал автовоспроизведение со звуком, включаем mute
          videoRef.value.muted = true
          videoRef.value.play()
        })
      }
    })

    hlsInstance.on(Hls.Events.ERROR, (_event, data) => {
      if (data.fatal) {
        switch (data.type) {
          case Hls.ErrorTypes.NETWORK_ERROR:
            hlsInstance.startLoad()
            break
          case Hls.ErrorTypes.MEDIA_ERROR:
            hlsInstance.recoverMediaError()
            break
          default:
            initPlayer()
            break
        }
      }
    })
  }
  // 2. Native HLS support (Safari / iOS)
  else if (videoRef.value.canPlayType('application/vnd.apple.mpegurl')) {
    videoRef.value.src = props.streamUrl
    videoRef.value.addEventListener('loadedmetadata', () => {
      if (props.autoplay) {
        videoRef.value.play()
      }
    })
  }
}

onMounted(() => {
  initPlayer()
})

watch(() => props.streamUrl, () => {
  initPlayer()
})

onUnmounted(() => {
  if (hlsInstance) {
    hlsInstance.destroy()
  }
})
</script>

<template>
  <div class="relative w-full h-full bg-black rounded-xl overflow-hidden flex items-center justify-center">
    <video
      ref="videoRef"
      controls
      playsinline
      class="w-full h-full object-contain"
    ></video>
  </div>
</template>
