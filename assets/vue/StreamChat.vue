<script setup>
import { useLiveVue } from 'live_vue'
import { nextTick, ref, watch } from 'vue'

const props = defineProps({
  messages: { type: Array, default: () => [] },
  currentUser: { type: String, default: 'Anonymous' },
  // live_vue автоматически передает $liveViewContext при использовании v-socket
  pushEvent: { type: Function, required: true }
})

const live = useLiveVue() // <-- вот так получаем доступ к хуку

const newMessage = ref('')
const chatContainer = ref(null)

const scrollToBottom = () => {
  nextTick(() => {
    if (chatContainer.value) {
      chatContainer.value.scrollTop = chatContainer.value.scrollHeight
    }
  })
}

watch(() => props.messages, () => {
  scrollToBottom()
}, { deep: true })

const sendMessage = () => {
  if (!newMessage.value.trim()) return

  // Отправляем событие прямо в ChannelLive!
  live.pushEvent('send_chat_message', {
    text: newMessage.value.trim(),
    username: props.currentUser
  })

  newMessage.value = ''
}
</script>

<template>
  <div class="flex flex-col h-full bg-base-200 border border-base-300 rounded-2xl overflow-hidden shadow-sm">
    <div class="p-4 border-b border-base-300 bg-base-300/50 flex items-center justify-between">
      <h3 class="font-bold text-sm tracking-wide uppercase opacity-80">Stream Chat</h3>
      <span class="badge badge-sm badge-primary">Live</span>
    </div>

    <div ref="chatContainer" class="flex-1 p-4 overflow-y-auto space-y-3 font-sans text-sm">
      <div v-if="messages.length === 0" class="text-center text-base-content/40 py-8 text-xs">
        Welcome to the chat! Say hi 👋
      </div>

      <div v-for="msg in messages" :key="msg.id" class="leading-relaxed break-words">
        <span class="font-bold text-primary mr-2">{{ msg.username }}:</span>
        <span class="text-base-content/90">{{ msg.text }}</span>
      </div>
    </div>

    <form @submit.prevent="sendMessage" class="p-3 border-t border-base-300 bg-base-300/30 flex gap-2">
      <input
        v-model="newMessage"
        type="text"
        placeholder="Send a message..."
        class="input input-sm input-bordered w-full focus:outline-none"
      />
      <button type="submit" class="btn btn-sm btn-primary">Send</button>
    </form>
  </div>
</template>
