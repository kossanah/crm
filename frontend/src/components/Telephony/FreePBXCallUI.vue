<template>
  <div>
    <!-- Minimized pill in top bar -->
    <div
      v-show="showSmallCallPopup"
      class="ml-2 flex cursor-pointer select-none items-center justify-between gap-1.5 rounded-full bg-surface-elevation-2 px-3 py-1.5 text-base text-ink-gray-8 shadow-md hover:bg-surface-gray-3 transition-colors border border-outline-elevation-2"
      @click="toggleCallPopup"
    >
      <div
        class="flex justify-center items-center size-5 rounded-full bg-surface-gray-2 border border-outline-gray-2 shrink-0 mr-1 text-ink-gray-6"
      >
        <Avatar
          v-if="contact?.image"
          :image="contact.image"
          :label="contact.full_name || contact.mobile_no || phoneNumber"
          class="!size-5"
        />
        <AvatarIcon v-else class="size-3 text-ink-gray-6" />
      </div>
      <span class="max-w-[130px] truncate font-medium text-ink-gray-9">{{ contact?.full_name ?? contact?.mobile_no ?? phoneNumber }}</span>
      <span class="text-ink-gray-4">·</span>
      <div v-if="callStatus == 'In progress'" class="text-emerald-500 dark:text-emerald-400 font-mono font-medium">
        {{ counterUp?.updatedTime }}
      </div>
      <div
        v-else-if="callStatus == 'Call ended' || callStatus == 'No answer'"
        class="blink text-rose-500 dark:text-rose-400 font-medium"
      >
        <span>{{ __(callStatus) }}</span>
        <span v-if="callStatus == 'Call ended' && callDuration">
          <span> · </span>
          <span>{{ callDuration }}</span>
        </span>
      </div>
      <div v-else-if="callStatus === 'Incoming call...'" class="text-emerald-500 dark:text-emerald-400 font-semibold animate-pulse flex items-center gap-1">
        <PhoneIcon class="size-3 animate-bounce" />
        {{ __('Incoming...') }}
      </div>
      <div v-else class="text-ink-gray-7">{{ __(callStatus) }}</div>
    </div>

    <!-- Floating call popup -->
    <div
      v-show="showCallPopup"
      class="fixed z-20 w-[320px] min-h-48 flex gap-2.5 flex-col rounded-xl bg-surface-elevation-2 p-4 pt-3.5 text-ink-gray-9 shadow-2xl border border-outline-elevation-2 transition-shadow"
      :style="style"
      @click.stop
    >
      <!-- Header bar (draggable) -->
      <div
        ref="callPopupHeader"
        class="header flex items-center justify-between gap-1 text-base cursor-move select-none pb-2 border-b border-outline-gray-2"
      >
        <div class="flex gap-2 items-center truncate">
          <div
            v-if="showNote || showTask"
            class="flex items-center gap-2.5 truncate"
          >
            <Avatar
              v-if="contact?.image"
              :image="contact.image"
              :label="contact.full_name || contact.mobile_no || phoneNumber"
              class="!size-7 shrink-0"
            />
            <div
              v-else
              class="flex justify-center items-center size-7 rounded-full bg-surface-gray-2 border border-outline-gray-2 shrink-0 text-ink-gray-6"
            >
              <AvatarIcon class="size-3.5" />
            </div>
            <div
              class="flex flex-col gap-0.5 text-base leading-4 overflow-hidden"
            >
              <div class="font-medium truncate text-sm text-ink-gray-9">
                {{ contact?.full_name ?? contact?.mobile_no ?? phoneNumber }}
              </div>
              <div class="text-ink-gray-5 text-xs font-mono">
                <div v-if="callStatus == 'In progress'" class="text-emerald-500 dark:text-emerald-400 font-medium">
                  <span>{{ contact?.mobile_no || phoneNumber }}</span>
                  <span> · </span>
                  <span>{{ counterUp?.updatedTime }}</span>
                </div>
                <div
                  v-else-if="callStatus == 'Call ended' || callStatus == 'No answer'"
                  class="blink text-rose-500 dark:text-rose-400 font-medium"
                >
                  <span>{{ __(callStatus) }}</span>
                  <span v-if="callStatus == 'Call ended'">
                    <span> · </span>
                    <span>{{ callDuration }}</span>
                  </span>
                </div>
                <div v-else class="text-ink-gray-6">{{ __(callStatus) }}</div>
              </div>
            </div>
          </div>
          <div v-else>
            <div v-if="callStatus == 'In progress'" class="text-xs text-emerald-500 dark:text-emerald-400 flex items-center font-medium font-mono">
              <span class="inline-block size-2 rounded-full bg-emerald-500 mr-1.5 animate-pulse"></span>
              Connected · {{ counterUp?.updatedTime }}
            </div>
            <div
              v-else-if="callStatus == 'Call ended' || callStatus == 'No answer'"
              class="blink text-xs font-medium text-rose-500 dark:text-rose-400"
            >
              <span>{{ __(callStatus) }}</span>
              <span v-if="callStatus == 'Call ended'">
                <span> · </span>
                <span>{{ callDuration }}</span>
              </span>
            </div>
            <div v-else-if="callStatus === 'Incoming call...'" class="text-xs text-emerald-500 dark:text-emerald-400 font-semibold flex items-center gap-1.5">
              <span class="inline-block size-2 rounded-full bg-emerald-500 animate-ping"></span>
              {{ __('Incoming call ringing...') }}
            </div>
            <div v-else class="text-xs text-blue-600 dark:text-blue-400 font-medium">
              {{ __(callStatus) }}
            </div>
          </div>
        </div>

        <div class="flex items-center gap-1">
          <Button
            variant="ghost"
            class="text-ink-gray-7 hover:text-ink-gray-9 hover:bg-surface-gray-3 shrink-0 cursor-pointer"
            :tooltip="__('Minimize')"
            :icon="MinimizeIcon"
            size="md"
            @click="toggleCallPopup"
          />
          <Button
            v-if="callStatus == 'Call ended' || callStatus == 'No answer' || callStatus == 'Failed'"
            variant="ghost"
            class="text-ink-gray-7 hover:text-ink-gray-9 hover:bg-surface-gray-3 shrink-0 cursor-pointer"
            icon="lucide-x"
            size="md"
            @click="closeCallPopup"
          />
        </div>
      </div>

      <!-- Body -->
      <div class="body flex-1 mt-1">
        <!-- Note Taking View -->
        <div v-if="showNote" class="flex flex-col gap-2">
          <div class="text-xs font-semibold text-ink-gray-7 flex items-center justify-between">
            <span class="flex items-center gap-1">
              <NoteIcon class="size-3.5 text-blue-500 dark:text-blue-400" />
              {{ __('Call Note') }}
            </span>
            <span v-if="dirty" class="text-amber-500 dark:text-amber-400 text-[11px] font-normal">{{ __('Unsaved changes') }}</span>
          </div>
          <TextEditor
            ref="content"
            variant="ghost"
            editor-class="prose-sm h-[260px] text-ink-gray-9 overflow-auto p-2.5 bg-surface-gray-2 rounded-lg border border-outline-gray-2 focus:border-outline-gray-3"
            :bubbleMenu="true"
            :content="note.content"
            :placeholder="__('Take notes during call...')"
            @change="(val) => (note.content = val)"
          />
        </div>

        <!-- Task Scheduling View -->
        <div v-else-if="showTask" class="flex flex-col gap-2">
          <div class="text-xs font-semibold text-ink-gray-7 flex items-center justify-between">
            <span class="flex items-center gap-1">
              <TaskIcon class="size-3.5 text-blue-500 dark:text-blue-400" />
              {{ __('Schedule Task') }}
            </span>
            <span v-if="dirty" class="text-amber-500 dark:text-amber-400 text-[11px] font-normal">{{ __('Unsaved changes') }}</span>
          </div>
          <TaskPanel ref="taskRef" :task="task" />
        </div>

        <!-- Incoming Call Ringing Screen-Pop (Matching Twilio UI docs.frappe.io/crm/twilio#call-pop-up) -->
        <div v-else-if="callStatus === 'Incoming call...'" class="flex flex-col items-center justify-center gap-3 py-3">
          <div class="relative flex items-center justify-center my-2">
            <div class="pulse-container relative flex items-center justify-center">
              <Avatar
                v-if="contact?.image"
                :image="contact.image"
                :label="contact.full_name || contact.mobile_no || phoneNumber"
                class="relative flex !h-20 !w-20 items-center justify-center [&>div]:text-[26px]"
              />
              <div
                v-else
                class="relative flex !h-20 !w-20 items-center justify-center rounded-full bg-surface-gray-2 border border-outline-gray-2 text-ink-gray-6 shadow-inner"
              >
                <AvatarIcon class="size-10 text-ink-gray-5" />
              </div>
            </div>
          </div>

          <div class="flex flex-col items-center justify-center gap-1 text-center px-2">
            <div class="text-xl font-bold text-ink-gray-9 leading-tight">
              {{ contact?.full_name || __('Unknown Caller') }}
            </div>
            <div class="text-sm text-ink-gray-5 font-mono font-medium">
              {{ contact?.mobile_no || phoneNumber }}
            </div>
            <div v-if="contact?.company" class="text-xs text-ink-gray-5 mt-0.5">
              {{ contact.company }}
            </div>
            <div
              v-if="contact?.lead || contact?.deal"
              class="mt-1.5 inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-blue-100 text-blue-700 dark:bg-blue-950 dark:text-blue-300 text-xs font-medium cursor-pointer hover:bg-blue-200 dark:hover:bg-blue-900 border border-blue-200 dark:border-blue-800 transition-colors"
              @click="openDealOrLead"
            >
              <span>{{ contact.deal ? __('Deal') : __('Lead') }}: {{ contact.full_name }}</span>
              <ArrowUpRightIcon class="size-3" />
            </div>
          </div>

          <!-- Accept & Reject Action Buttons -->
          <div class="flex items-center gap-3 mt-3 w-full justify-center">
            <Button
              size="md"
              variant="solid"
              theme="green"
              :label="__('Accept')"
              class="rounded-lg text-white px-5 font-semibold shadow-md shadow-green-500/20"
              :iconLeft="PhoneIcon"
              @click="acceptIncomingCall"
            />
            <Button
              size="md"
              variant="solid"
              theme="red"
              :label="__('Reject')"
              class="rounded-lg text-white px-5 font-semibold shadow-md shadow-red-500/20"
              @click="rejectIncomingCall"
            >
              <template #prefix>
                <PhoneIcon class="rotate-[135deg]" />
              </template>
            </Button>
          </div>
        </div>

        <!-- Normal Active Call View (Outgoing or Connected) -->
        <div v-else class="flex flex-col gap-2">
          <div class="flex items-center gap-3 py-1">
            <Avatar
              v-if="contact?.image"
              :image="contact.image"
              :label="contact.full_name || contact.mobile_no || phoneNumber"
              class="!size-11 shrink-0"
            />
            <div
              v-else
              class="flex justify-center items-center size-11 rounded-full bg-surface-gray-2 border border-outline-gray-2 text-ink-gray-6 shrink-0"
            >
              <AvatarIcon class="size-6 text-ink-gray-5" />
            </div>
            <div class="flex flex-col gap-0.5 overflow-hidden">
              <div class="text-base font-semibold leading-5 text-ink-gray-9 truncate">
                {{ contact?.full_name || contact?.mobile_no || phoneNumber }}
              </div>
              <div v-if="contact?.company" class="text-xs text-ink-gray-5 truncate">
                {{ contact.company }}
              </div>
              <div class="text-xs text-ink-gray-5 font-mono">
                {{ phoneNumber }}
              </div>
            </div>
          </div>

          <!-- MicroSIP Assistant Banner -->
          <div
            v-if="callStatus.startsWith('Calling extension') || callStatus.startsWith('Ringing')"
            class="rounded-lg bg-surface-gray-2 p-2.5 text-xs text-ink-gray-7 border border-outline-gray-2 mt-1 flex items-center gap-2"
          >
            <span class="text-blue-500 dark:text-blue-400 font-bold text-sm">ℹ</span>
            <span>{{ __('Please answer MicroSIP on your computer to connect.') }}</span>
          </div>
        </div>
      </div>

      <!-- Footer Bar -->
      <div
        v-if="callStatus !== 'Incoming call...'"
        class="footer flex justify-between items-center gap-2 mt-2 pt-2.5 border-t border-outline-gray-2"
      >
        <div class="flex gap-1.5">
          <Button
            variant="subtle"
            class="text-ink-gray-8 hover:text-ink-gray-9 cursor-pointer"
            :class="{ '!bg-blue-600 !text-white': showNote }"
            :tooltip="__('Take a Note')"
            size="md"
            :icon="NoteIcon"
            @click="showNoteWindow"
          />
          <Button
            variant="subtle"
            class="text-ink-gray-8 hover:text-ink-gray-9 cursor-pointer"
            :class="{ '!bg-blue-600 !text-white': showTask }"
            size="md"
            :tooltip="__('Schedule a Task')"
            :icon="TaskIcon"
            @click="showTaskWindow"
          />
          <Button
            v-if="contact?.deal || contact?.lead"
            variant="subtle"
            class="text-ink-gray-8 hover:text-ink-gray-9 cursor-pointer"
            size="md"
            :iconRight="ArrowUpRightIcon"
            :label="contact.deal ? __('Deal') : __('Lead')"
            @click="openDealOrLead"
          />
        </div>

        <div class="flex items-center gap-2">
          <!-- Save / Update note/task button -->
          <Button
            v-if="(showNote && note.name && dirty) || (showTask && task.name && dirty)"
            variant="solid"
            theme="blue"
            :label="__('Update')"
            size="md"
            @click="update"
          />
          <Button
            v-else-if="(showNote && !note.name && note?.content && note.content !== '<p></p>') || (showTask && !task.name && task.title)"
            variant="solid"
            theme="blue"
            :label="__('Save')"
            size="md"
            @click="save"
          />

          <!-- Close Editor or Dismiss call popup -->
          <Button
            v-if="showNote || showTask"
            size="md"
            variant="subtle"
            :label="__('Done')"
            @click="closeEditor"
          />
          <Button
            v-else-if="callStatus === 'In progress' || callStatus.startsWith('Calling') || callStatus.startsWith('Ringing')"
            size="md"
            variant="subtle"
            theme="red"
            :label="__('Dismiss')"
            @click="closeCallPopup"
          />
        </div>
      </div>
    </div>

    <!-- Hidden audio count-up timer -->
    <CountUpTimer ref="counterUp" />
  </div>
</template>

<script setup>
import ArrowUpRightIcon from '@/components/Icons/ArrowUpRightIcon.vue'
import AvatarIcon from '@/components/Icons/AvatarIcon.vue'
import MinimizeIcon from '@/components/Icons/MinimizeIcon.vue'
import NoteIcon from '@/components/Icons/NoteIcon.vue'
import TaskIcon from '@/components/Icons/TaskIcon.vue'
import PhoneIcon from '@/components/Icons/PhoneIcon.vue'
import TaskPanel from '@/components/Telephony/TaskPanel.vue'
import CountUpTimer from '@/components/CountUpTimer.vue'
import { globalStore } from '@/stores/global'
import { useDraggable, useWindowSize } from '@vueuse/core'
import { TextEditor, Avatar, Button, call, toast } from 'frappe-ui'
import { ref, onMounted, onBeforeUnmount, watch, nextTick } from 'vue'
import { useRouter } from 'vue-router'

const { $socket } = globalStore()

const callPopupHeader = ref(null)
const showCallPopup = ref(false)
const showSmallCallPopup = ref(false)

function toggleCallPopup() {
  showCallPopup.value = !showCallPopup.value
  showSmallCallPopup.value = !showSmallCallPopup.value
}

const { width, height } = useWindowSize()

let { style } = useDraggable(callPopupHeader, {
  initialValue: { x: width.value - 350, y: height.value - 260 },
  preventDefault: true,
})

const counterUp = ref(null)
const phoneNumber = ref('')
const callStatus = ref('')
const callDuration = ref('00:00')
const callLogId = ref('')

const contact = ref({
  name: '',
  full_name: '',
  image: '',
  mobile_no: '',
  lead: '',
  deal: '',
  company: '',
})

const showNote = ref(false)
const showTask = ref(false)
const note = ref({ name: '', content: '' })
const task = ref({
  name: '',
  title: '',
  description: '',
  assigned_to: '',
  due_date: '',
  status: 'Backlog',
  priority: 'Low',
})

const dirty = ref(false)
watch(
  [() => note.value.content, () => task.value],
  () => {
    dirty.value = true
  },
  { deep: true },
)

function updateWindowHeight(condition) {
  let callPopup = callPopupHeader.value?.parentElement
  if (!callPopup) return
  let top = parseInt(callPopup.style.top)
  if (isNaN(top)) {
    top = height.value - 260
  }
  let updatedTop = condition ? top - 240 : top + 240
  if (updatedTop < 10) {
    updatedTop = 10
  }
  callPopup.style.top = updatedTop + 'px'
}

function showNoteWindow() {
  showNote.value = !showNote.value
  if (!showTask.value) {
    updateWindowHeight(showNote.value)
  }
  if (showNote.value) {
    showTask.value = false
  }
}

function showTaskWindow() {
  showTask.value = !showTask.value
  if (!showNote.value) {
    updateWindowHeight(showTask.value)
  }
  if (showTask.value) {
    showNote.value = false
  }
}

function closeEditor() {
  if (showNote.value || showTask.value) {
    updateWindowHeight(false)
  }
  showNote.value = false
  showTask.value = false
}

// Web Audio API Ringtone Chime
let audioCtx = null
let ringtoneTimer = null

function playRingtone() {
  stopRingtone()
  try {
    const AudioContextClass = window.AudioContext || window.webkitAudioContext
    if (!AudioContextClass) return
    audioCtx = new AudioContextClass()
    if (audioCtx.state === 'suspended') {
      audioCtx.resume().catch(() => {})
    }

    function chime() {
      if (!audioCtx) return
      const now = audioCtx.currentTime
      const osc = audioCtx.createOscillator()
      const gain = audioCtx.createGain()
      osc.type = 'sine'
      osc.frequency.setValueAtTime(523.25, now) // C5
      osc.frequency.setValueAtTime(659.25, now + 0.2) // E5
      gain.gain.setValueAtTime(0.12, now)
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.9)
      osc.connect(gain)
      gain.connect(audioCtx.destination)
      osc.start(now)
      osc.stop(now + 0.9)
    }

    chime()
    ringtoneTimer = setInterval(chime, 2500)
  } catch (e) {
    console.warn('AudioContext ringtone warning:', e)
  }
}

function stopRingtone() {
  if (ringtoneTimer) {
    clearInterval(ringtoneTimer)
    ringtoneTimer = null
  }
  if (audioCtx) {
    try {
      audioCtx.close()
    } catch (e) {}
    audioCtx = null
  }
}

function acceptIncomingCall() {
  stopRingtone()
  stopPolling()
  callStatus.value = 'In progress'
  if (counterUp.value) counterUp.value.start()
  toast.success(__('Call accepted. Connected on MicroSIP.'))
}

function rejectIncomingCall() {
  stopRingtone()
  closeCallPopup()
}

async function makeOutgoingCall(number) {
  if (!number) {
    toast.error(__('Please provide a valid phone number'))
    return
  }
  phoneNumber.value = number
  callStatus.value = __('Initiating call...')
  showCallPopup.value = true
  showSmallCallPopup.value = false

  fetchContactInfo(number)

  try {
    const res = await call('bridge_telephony.api.freepbx.make_call', {
      to_number: number,
    })
    if (res && res.success) {
      callLogId.value = res.call_log || res.call_id || ''
      const ext = res.agent_extension || '1001'
      callStatus.value = `Calling extension ${ext}...`
      toast.success(res.message || __('Ringing your extension...'))
    } else {
      callStatus.value = __('Call Failed')
      toast.error(res?.error || res?.message || __('Failed to initiate call on FreePBX'))
    }
  } catch (err) {
    callStatus.value = __('Call Failed')
    toast.error(
      err.messages ? err.messages[0] : (err.message || __('Error initiating call'))
    )
  }
}

async function fetchContactInfo(number) {
  if (!number) return
  try {
    const data = await call('crm.integrations.api.get_contact_by_phone_number', {
      phone_number: number,
    })
    if (data && (data.name || data.full_name)) {
      contact.value = {
        name: data.name,
        full_name: data.full_name,
        image: data.image,
        mobile_no: data.mobile_no || number,
        lead: data.lead,
        deal: data.deal,
        company: data.company || '',
      }
    } else {
      contact.value = {
        name: '',
        full_name: '',
        image: '',
        mobile_no: number,
        lead: '',
        deal: '',
        company: '',
      }
    }
  } catch (e) {
    console.warn('Error fetching contact info:', e)
  }
}

function handleIncomingCall(data) {
  if (!data || !data.caller) return
  console.log('FreePBX incoming call received:', data)

  phoneNumber.value = data.caller
  callLogId.value = data.call_id || data.call_log || ''
  callStatus.value = 'Incoming call...'
  showCallPopup.value = true
  showSmallCallPopup.value = false

  if (data.lead) {
    contact.value = {
      name: data.lead.name,
      full_name: data.lead.title,
      image: '',
      mobile_no: data.caller,
      lead: data.lead.doctype === 'CRM Lead' ? data.lead.name : null,
      deal: data.lead.doctype === 'CRM Deal' ? data.lead.name : null,
      company: data.lead.company || '',
    }
  } else {
    fetchContactInfo(data.caller)
  }

  playRingtone()
}

function handleStatusUpdate(data) {
  if (!data) return
  console.log('FreePBX call status update:', data)
  stopRingtone()

  if (data.call_id) {
    callLogId.value = data.call_id
  }

  if (data.status === 'Completed') {
    callStatus.value = 'Call ended'
    if (counterUp.value) counterUp.value.stop()
    const d = data.duration || 0
    const mins = Math.floor(d / 60).toString().padStart(2, '0')
    const secs = (d % 60).toString().padStart(2, '0')
    callDuration.value = `${mins}:${secs}`
  } else if (data.status === 'No Answer') {
    callStatus.value = 'No answer'
    if (counterUp.value) counterUp.value.stop()
  } else if (data.status === 'Busy') {
    callStatus.value = 'Busy'
    if (counterUp.value) counterUp.value.stop()
  } else if (data.status === 'In progress' || data.status === 'Connected') {
    callStatus.value = 'In progress'
    if (counterUp.value) counterUp.value.start()
  }
}

let isSetup = false
let pollTimer = null

async function pollActiveIncomingCall() {
  if (
    showCallPopup.value ||
    showSmallCallPopup.value ||
    callStatus.value === 'In progress' ||
    callStatus.value === 'Incoming call...'
  ) {
    return
  }
  try {
    const res = await call('bridge_telephony.api.freepbx.check_active_call')
    if (res && res.caller) {
      handleIncomingCall(res)
    }
  } catch (e) {
    // Ignore polling failures
  }
}

function startPolling() {
  if (pollTimer) return
  pollTimer = setInterval(pollActiveIncomingCall, 2500)
}

function stopPolling() {
  if (pollTimer) {
    clearInterval(pollTimer)
    pollTimer = null
  }
}

function setup() {
  if (isSetup) return
  isSetup = true

  if ($socket) {
    $socket.on('crm_incoming_call', handleIncomingCall)
    $socket.on('incoming_call', handleIncomingCall)
    $socket.on('call_status_update', handleStatusUpdate)
  }
  startPolling()
}

onMounted(() => {
  setup()
})

onBeforeUnmount(() => {
  stopRingtone()
  stopPolling()
  if ($socket) {
    $socket.off('crm_incoming_call', handleIncomingCall)
    $socket.off('incoming_call', handleIncomingCall)
    $socket.off('call_status_update', handleStatusUpdate)
  }
  isSetup = false
})

const router = useRouter()

function openDealOrLead() {
  if (contact.value.deal) {
    router.push({
      name: 'Deal',
      params: { dealId: contact.value.deal },
    })
  } else if (contact.value.lead) {
    router.push({
      name: 'Lead',
      params: { leadId: contact.value.lead },
    })
  }
}

function closeCallPopup() {
  stopRingtone()
  if (showNote.value || showTask.value) {
    updateWindowHeight(false)
  }
  showCallPopup.value = false
  showSmallCallPopup.value = false
  showNote.value = false
  showTask.value = false
  dirty.value = false
  callStatus.value = ''
  if (counterUp.value) counterUp.value.stop()
  note.value = { name: '', content: '' }
  task.value = {
    name: '',
    title: '',
    description: '',
    assigned_to: '',
    due_date: '',
    status: 'Backlog',
    priority: 'Low',
  }
  startPolling()
}

function save() {
  if (showNote.value && note.value.content && note.value.content !== '<p></p>') {
    createUpdateNote()
  }
  if (showTask.value && task.value.title) {
    createUpdateTask()
  }
}

function update() {
  if (showNote.value && note.value.content) {
    createUpdateNote()
  }
  if (showTask.value && task.value.title) {
    createUpdateTask()
  }
}

async function ensureCallLog() {
  if (callLogId.value) return callLogId.value
  try {
    const res = await call('bridge_telephony.api.freepbx.get_or_create_call_log', {
      caller: phoneNumber.value,
      call_type: callStatus.value === 'Incoming call...' ? 'Incoming' : 'Outgoing',
      reference_doctype: contact.value.lead ? 'CRM Lead' : contact.value.deal ? 'CRM Deal' : (contact.value.name ? 'Contact' : null),
      reference_name: contact.value.lead || contact.value.deal || contact.value.name || null,
    })
    if (res && (res.call_log || res.call_id)) {
      callLogId.value = res.call_log || res.call_id
      return callLogId.value
    }
  } catch (e) {
    console.error('Failed to get or create call log:', e)
  }
  return null
}

async function createUpdateNote() {
  if (!callLogId.value) {
    await ensureCallLog()
  }
  if (!callLogId.value) {
    toast.error(__('No active call log found to attach note'))
    return
  }
  try {
    const res = await call('crm.integrations.api.add_note_to_call_log', {
      call_sid: callLogId.value,
      note: note.value,
    })
    note.value['name'] = res.name
    nextTick(() => {
      dirty.value = false
    })
    toast.success(__('Note saved successfully'))
  } catch (err) {
    toast.error(err.messages ? err.messages[0] : (err.message || __('Failed to save note')))
  }
}

async function createUpdateTask() {
  if (!callLogId.value) {
    await ensureCallLog()
  }
  if (!callLogId.value) {
    toast.error(__('No active call log found to attach task'))
    return
  }
  try {
    const res = await call('crm.integrations.api.add_task_to_call_log', {
      call_sid: callLogId.value,
      task: task.value,
    })
    task.value['name'] = res.name
    nextTick(() => {
      dirty.value = false
    })
    toast.success(__('Task saved successfully'))
  } catch (err) {
    toast.error(err.messages ? err.messages[0] : (err.message || __('Failed to save task')))
  }
}

defineExpose({
  makeOutgoingCall,
  setup,
})
</script>

<style scoped>
@keyframes blink {
  0% {
    opacity: 1;
  }
  50% {
    opacity: 0;
  }
  100% {
    opacity: 1;
  }
}

.blink {
  animation: blink 1s ease-in-out 6;
}

:deep(.ProseMirror) {
  caret-color: var(--text-ink-gray-9, currentColor);
  color: var(--text-ink-gray-9, currentColor);
}

.pulse-container::before {
  content: '';
  position: absolute;
  border: 2px solid #22c55e;
  width: calc(100% + 20px);
  height: calc(100% + 20px);
  border-radius: 50%;
  animation: pulse-ring 1.3s cubic-bezier(0, 0.2, 0.8, 1) infinite;
}

.pulse-container::after {
  content: '';
  position: absolute;
  border: 2px solid #22c55e;
  width: calc(100% + 20px);
  height: calc(100% + 20px);
  border-radius: 50%;
  animation: pulse-ring 1.3s cubic-bezier(0, 0.2, 0.8, 1) infinite;
  animation-delay: 0.4s;
}

@keyframes pulse-ring {
  0% {
    transform: scale(0.6);
    opacity: 0.9;
  }
  50% {
    transform: scale(1.15);
    opacity: 0.5;
  }
  100% {
    transform: scale(1.45);
    opacity: 0;
  }
}
</style>
