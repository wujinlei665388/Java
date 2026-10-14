<template>
  <div class="rb">
    <div class="rb-stage" :style="{ maxWidth: size + 'px' }">
      <canvas ref="cv" :width="size" :height="size"></canvas>
      <div class="rb-badge" v-if="truncated">轨迹过长，只录了前 5 万步</div>
      <div class="rb-empty" v-if="!ready">这局没有回放数据</div>
    </div>

    <div class="rb-bar" v-if="controls && ready">
      <button class="rb-btn primary" @click="toggle">{{ playing ? '⏸ 暂停' : '▶ 播放' }}</button>
      <button class="rb-btn" @click="restart">↺ 重播</button>

      <input class="rb-range" type="range" min="0" :max="total" step="1"
             :value="cur" @input="onSeek" />

      <span class="rb-count">{{ cur }}<i>/{{ total }}</i> 步</span>

      <span class="rb-speeds">
        <button v-for="s in SPEEDS" :key="s" class="rb-sp"
                :class="{ on: s === speed }" @click="setSpeed(s)">{{ s }}×</button>
      </span>
    </div>
  </div>
</template>

<script setup>
/**
 * 回放播放器（画布）
 * ------------------------------------------------------------------
 * 一个组件两个用场：
 *   1. 皮肤库的"活预览" —— 传一段演示轨迹，loop 打开、不显示控制条
 *   2. 对局回放 —— 传后端存下来的真实轨迹，带进度条 / 倍速 / 重播
 *
 * 注意回放时用的是**轨迹里记着的那张地图 + 那款皮肤**（而不是现在选的），
 * 这样看到的就是当时那一局的真实画面。
 */
import { ref, computed, watch, onMounted, onBeforeUnmount, nextTick } from 'vue'
import { GRID, getMap } from '../game/maps'
import { getSkin, resolveTheme } from '../game/skins'
import { paintBoard, drawFood, drawSnake } from '../game/render'
import { decodeTrack, stateAt } from '../game/replay'

const props = defineProps({
  /** 后端返回的轨迹文本，或者演示轨迹对象 */
  track: { type: [String, Object], default: null },
  /** 可选：强制用某张地图 / 某款皮肤（不传就用轨迹里记的） */
  mapId: { type: String, default: '' },
  skinId: { type: String, default: '' },
  /** 画布边长（像素） */
  size: { type: Number, default: 400 },
  /** 是否显示播放条 */
  controls: { type: Boolean, default: false },
  /** 循环播放（预览用） */
  loop: { type: Boolean, default: false },
  /** 初始倍速 */
  speed: { type: Number, default: 1 },
  /** 是否挂载后自动开始 */
  autoplay: { type: Boolean, default: true }
})

const SPEEDS = [0.5, 1, 2, 4]

const cv = ref(null)
const tr = ref(null)
const cur = ref(0)
const playing = ref(false)
const speed = ref(props.speed)
const ready = ref(false)
let ctx = null
let timer = null
let frame = 0

const total = computed(() => (tr.value ? tr.value.steps : 0))
const truncated = computed(() => !!(tr.value && tr.value.overflow))

/** 渲染主题：优先用外部指定的地图/皮肤，其次用轨迹里记的 */
const view = computed(() => {
  const mid = props.mapId || (tr.value && tr.value.mapId) || ''
  const sid = props.skinId || (tr.value && tr.value.skinId) || ''
  return resolveTheme(getMap(mid), getSkin(sid))
})

const CELL = computed(() => props.size / GRID)

function draw() {
  if (!ctx || !tr.value) return
  const v = view.value
  const st = stateAt(tr.value, cur.value)
  frame++
  paintBoard(ctx, v, props.size, GRID)
  if (st && st.food) drawFood(ctx, v, st.food, CELL.value)
  if (st && st.snake) drawSnake(ctx, v, st.snake, st.dir, CELL.value, frame)
}

function clearTimer() {
  if (timer) {
    clearInterval(timer)
    timer = null
  }
}

/** 按当前倍速重新排定"下一步"的节奏 */
function schedule() {
  clearTimer()
  if (!playing.value || !tr.value) return
  const base = Math.max(30, tr.value.stepMs || 150)
  timer = setInterval(step, Math.max(16, Math.round(base / speed.value)))
}

function step() {
  if (cur.value >= total.value) {
    if (props.loop) {
      cur.value = 0
    } else {
      playing.value = false
      clearTimer()
      draw()
      return
    }
  } else {
    cur.value++
  }
  draw()
}

function play() {
  if (!tr.value) return
  if (cur.value >= total.value) cur.value = 0   // 播完了再点播放 = 从头来
  playing.value = true
  schedule()
}

function pause() {
  playing.value = false
  clearTimer()
}

function toggle() {
  playing.value ? pause() : play()
}

function restart() {
  cur.value = 0
  draw()
  if (!playing.value) play()
}

function onSeek(e) {
  cur.value = Number(e.target.value) || 0
  draw()
}

function setSpeed(s) {
  speed.value = s
  if (playing.value) schedule()
}

/** 载入轨迹：解码 → 归零 → 画第一帧 → 按需自动播放 */
function load() {
  clearTimer()
  playing.value = false
  cur.value = 0
  frame = 0
  tr.value = decodeTrack(props.track)
  ready.value = !!tr.value
  if (!ready.value) return
  draw()
  if (props.autoplay) play()
}

onMounted(async () => {
  await nextTick()
  ctx = cv.value ? cv.value.getContext('2d') : null
  load()
})

// 换了轨迹（比如在列表里点了另一局）就从头放
watch(() => props.track, () => load())
// 换了地图/皮肤要重画当前这一帧
watch([() => props.mapId, () => props.skinId], () => draw())

onBeforeUnmount(clearTimer)

defineExpose({ play, pause, restart })
</script>

<style scoped>
.rb {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.rb-stage {
  position: relative;
  width: 100%;
  margin: 0 auto;
  border: 2px solid #14532d;
  background: #07130a;
  line-height: 0;
}

.rb-stage canvas {
  display: block;
  width: 100%;
  height: auto;
}

.rb-badge {
  position: absolute;
  left: 8px;
  bottom: 8px;
  padding: 3px 9px;
  font-size: 10.5px;
  letter-spacing: 1px;
  color: #07130a;
  background: #facc15;
}

.rb-empty {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 13px;
  line-height: 1.6;
  color: #a3e635;
  background: rgba(7, 19, 10, 0.86);
}

/* ---------------- 播放条 ---------------- */
.rb-bar {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 12px;
  background: rgba(7, 19, 10, 0.9);
  border: 2px solid #14532d;
  flex-wrap: wrap;
}

.rb-btn {
  font-family: inherit;
  font-size: 12px;
  letter-spacing: 1px;
  padding: 6px 12px;
  color: #4ade80;
  background: transparent;
  border: 1px solid #166534;
  cursor: pointer;
  transition: all 0.15s;
}

.rb-btn:hover {
  color: #facc15;
  border-color: #facc15;
}

.rb-btn.primary {
  color: #07130a;
  background: #4ade80;
  border-color: #4ade80;
  font-weight: bold;
}

.rb-btn.primary:hover {
  background: #facc15;
  border-color: #facc15;
  color: #07130a;
}

.rb-range {
  flex: 1;
  min-width: 120px;
  height: 4px;
  -webkit-appearance: none;
  appearance: none;
  background: #166534;
  cursor: pointer;
}

.rb-range::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 14px;
  height: 14px;
  background: #facc15;
  border: none;
  cursor: pointer;
}

.rb-count {
  font-size: 11.5px;
  letter-spacing: 1px;
  color: #a3e635;
  white-space: nowrap;
}

.rb-count i {
  font-style: normal;
  color: #14532d;
}

.rb-speeds {
  display: flex;
  gap: 4px;
}

.rb-sp {
  font-family: inherit;
  font-size: 11px;
  padding: 4px 8px;
  color: #4ade80;
  background: transparent;
  border: 1px solid #166534;
  cursor: pointer;
}

.rb-sp.on {
  color: #07130a;
  background: #4ade80;
  border-color: #4ade80;
}

@media (max-width: 620px) {
  .rb-count {
    display: none;
  }
}
</style>
