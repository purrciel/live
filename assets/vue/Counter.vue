<script setup lang="ts">
import { ref } from "vue";

const props = defineProps<{ count: number }>()
const diff = ref(1)
</script>

<template>
  <div class="flex flex-col items-center justify-center min-h-[300px] p-6 text-base-content">
    <div class="card bg-base-200 shadow-xl w-full max-w-md p-6 space-y-6 text-center">
      <!-- Title / Counter Display -->
      <div>
        <span class="text-sm uppercase tracking-wider text-base-content/60 font-semibold">Current Count</span>
        <div class="text-6xl font-extrabold text-primary mt-2">
          {{ props.count }}
        </div>
      </div>

      <div class="divider my-0"></div>

      <!-- Controls -->
      <div class="space-y-4">
        <div class="flex items-center justify-between text-sm font-medium">
          <span>Step (Diff): <strong class="text-primary">{{ diff }}</strong></span>
        </div>

        <input
          v-model.number="diff"
          type="range"
          min="1"
          max="10"
          class="range range-primary range-sm"
        />

        <button
          phx-click="inc"
          :phx-value-diff="diff"
          class="btn btn-primary w-full shadow-md"
        >
          Increase counter by {{ diff }}
        </button>
      </div>
    </div>
  </div>
</template>
