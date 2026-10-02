import { onMounted, onUnmounted } from 'vue'

const STORAGE_KEY = 'app_broadcasts'
const bus = {
  send(event, payload) {
    window.dispatchEvent(new CustomEvent(event, { detail: payload }))

    // Real-time call events are transient in-memory signals and should not be persisted or replayed
    if (event.startsWith('crm_call_')) return

    try {
      const broadcasts = JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]')
      broadcasts.push({ event, payload, timestamp: Date.now() })
      localStorage.setItem(STORAGE_KEY, JSON.stringify(broadcasts))
    } catch (e) {}
  },
  on(event, handler) {
    window.addEventListener(event, (e) => handler(e.detail))
  },
  off(event, handler) {
    window.removeEventListener(event, handler)
  },
}

export function useBroadcast() {
  const listeners = []

  function on(event, handler) {
    bus.on(event, handler)
    listeners.push({ event, handler })

    // check localStorage for missed non-call broadcasts on init
    onMounted(() => {
      try {
        const broadcasts = JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]')
        // Clean out any transient call events or stale events older than 30s
        const now = Date.now()
        const cleaned = broadcasts.filter(
          (b) => !b.event?.startsWith('crm_call_') && now - (b.timestamp || 0) < 30000,
        )
        localStorage.setItem(STORAGE_KEY, JSON.stringify(cleaned))

        if (event.startsWith('crm_call_')) return

        const missed = cleaned.filter((b) => b.event === event)
        if (missed.length) {
          missed.forEach((b) => handler(b.payload))
          const remaining = cleaned.filter((b) => b.event !== event)
          localStorage.setItem(STORAGE_KEY, JSON.stringify(remaining))
        }
      } catch (e) {
        localStorage.removeItem(STORAGE_KEY)
      }
    })
  }

  onUnmounted(() => {
    listeners.forEach(({ event, handler }) => bus.off(event, handler))
  })

  return { on, send: bus.send }
}
