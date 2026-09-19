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
  },
  muted: {
    type: Boolean,
    default: true // По умолчанию выключаем звук для превью
  },
  controls: {
    type: Boolean,
    default: false // Для превью контролы не нужны
  }
})

const videoRef = ref(null)
let hlsInstance = null

const initPlayer = () => {
  if (!videoRef.value || !props.streamUrl) return

  if (hlsInstance) {
    hlsInstance.destroy()
    hlsInstance = null
  }

  if (Hls.isSupported()) {
    hlsInstance = new Hls({
      enableWorker: true,
      lowLatencyMode: true,
      backBufferLength: 30
    })

    hlsInstance.loadSource(props.streamUrl)
    hlsInstance.attachMedia(videoRef.value)

    hlsInstance.on(Hls.Events.MANIFEST_PARSED, () => {
      if (props.autoplay) {
        videoRef.value.play().catch(() => {
          videoRef.value.muted = true
          videoRef.value.play()
        })
      }
    })
  } else if (videoRef.value.canPlayType('application/vnd.apple.mpegurl')) {
    videoRef.value.src = props.streamUrl
    videoRef.value.addEventListener('loadedmetadata', () => {
      if (props.autoplay) videoRef.value.play()
    })
  }
}

onMounted(() => initPlayer())
watch(() => props.streamUrl, () => initPlayer())
onUnmounted(() => { if (hlsInstance) hlsInstance.destroy() })
</script>

<template>
  <div class="relative w-full h-full bg-black overflow-hidden flex items-center justify-center">
    <video
      ref="videoRef"
      :controls="controls"
      :muted="muted"
      playsinline
      class="w-full h-full object-cover"
    ></video>
  </div>
</template>
