<template>
  <div class="page" :style="themeVars">
    <div class="topbar">
      <span class="user">玩家：<b>{{ user }}</b></span>
      <span class="topbar-right">
        <a class="home-link" @click.prevent="$router.push('/')">首页</a>
        <a class="skin-link" @click.prevent="showSkin = true">皮肤：{{ skin.name }}</a>
        <a class="record-link" @click.prevent="$router.push('/my?tab=records')">我的对局</a>
        <a class="space-link" @click.prevent="$router.push('/my')">我的空间</a>
        <a class="rank-link" @click.prevent="openRank">排行榜</a>
        <a class="logout" @click.prevent="logout">退出登录 &gt;&gt;</a>
      </span>
    </div>

    <h1>贪吃蛇</h1>
    <div class="sub">S N A K E &nbsp; G A M E</div>

    <!-- 地图切换（三张地图随时换，换图即重开一局） -->
    <div class="map-tabs">
      <button v-for="m in maps" :key="m.id" class="map-tab"
              :class="{ on: m.id === mapId }"
              :style="{ '--c': m.theme.border, '--g': m.theme.glow }"
              @click="switchMap(m.id)">
        {{ m.name }}
      </button>
    </div>

    <div class="hud">
      <span>得分：<b>{{ score }}</b></span>
      <span>最高分：<b>{{ bestShow }}</b></span>
      <span>长度：<b>{{ snakeLen }}</b></span>
    </div>

    <div class="board-wrap">
      <canvas ref="game" width="400" height="400"></canvas>
      <div class="overlay" v-show="!running || paused || gameOver">
        <h2 :class="overlayClass">{{ overlayTitle }}</h2>
        <p v-html="overlayText"></p>

        <!-- 本局结束：要不要把这局存下来，由玩家自己决定 -->
        <div class="overlay-btns" v-if="gameOver">
          <button class="btn" :disabled="saving || saved" @click="saveCurrentRecord">
            {{ saved ? '已保存 ✓' : (saving ? '保存中…' : '保 存 本 局') }}
          </button>
          <button class="btn ghost" @click="start">
            {{ saved ? '再 来 一 局' : '不保存 · 再来一局' }}
          </button>
        </div>
        <button class="btn" v-else @click="start">{{ paused ? '继续游戏' : '开始游戏' }}</button>

        <div class="overlay-tip" v-if="overlayTip" :class="{ err: !saved && saveMsg }">{{ overlayTip }}</div>
      </div>
    </div>

    <div class="tips">{{ map.rule }} · ↑↓←→ / WASD 移动 · 空格暂停 · 撞墙或咬到自己游戏结束</div>

    <!-- 皮肤弹层：11 款皮肤，点一下就换，不影响正在进行的这一局 -->
    <div class="skin-mask" v-show="showSkin" @click.self="showSkin = false">
      <div class="skin-box">
        <div class="skin-title">皮 肤</div>
        <div class="skin-sub">{{ skins.length }} 款 · 换肤只改外观，本局继续</div>
        <div class="skin-grid">
          <button v-for="s in skins" :key="s.id" class="skin-item"
                  :class="{ on: s.id === skinId }"
                  @click="applySkin(s.id)">
            <span class="skin-dots">
              <i v-for="(c, i) in swatch(s)" :key="i" :style="{ background: c }"></i>
            </span>
            <span class="skin-name">{{ s.name }}</span>
          </button>
        </div>
        <div class="skin-desc">{{ skin.desc }}</div>
        <button class="btn small" @click="showSkin = false">关 闭</button>
      </div>
    </div>

    <!-- 排行榜弹层 -->
    <div class="rank-mask" v-show="showRank" @click.self="showRank = false">
      <div class="rank-box">
        <div class="rank-title">排 行 榜</div>
        <div class="rank-sub">T O P &nbsp; 1 0</div>
        <div class="rank-msg" v-if="rankMsg">{{ rankMsg }}</div>
        <table class="rank-table" v-else>
          <thead>
            <tr><th>名次</th><th>玩家</th><th>最高分</th></tr>
          </thead>
          <tbody>
            <tr v-for="(r, i) in rankList" :key="r.id" :class="{ me: r.username === user }">
              <td>{{ i + 1 }}</td>
              <td>{{ r.username }}</td>
              <td class="sc">{{ r.score }}</td>
            </tr>
          </tbody>
        </table>
        <button class="btn small" @click="showRank = false">关 闭</button>
      </div>
    </div>

  </div>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { saveScore, getRank } from '../api/user'
import { saveRecord } from '../api/record'
import {
  MAPS, GRID, getMap, wallSet, loadMapId, saveMapId
} from '../game/maps'
import {
  SKINS, getSkin, resolveTheme, loadSkinId, saveSkinId
} from '../game/skins'
import { paintBoard, drawFood, drawSnake } from '../game/render'
import { createRecorder, encodeTrack } from '../game/replay'

const route = useRoute()
const router = useRouter()
const user = sessionStorage.getItem('snake_user') || 'player'
const userId = sessionStorage.getItem('snake_uid') || ''

const maps = MAPS
const skins = SKINS
// 地图来源优先级：地址栏 ?map=  >  首页选过的（localStorage）  >  默认第一张
const mapId = ref(getMap(route.query.map || loadMapId()).id)
const map = computed(() => getMap(mapId.value))
// 障碍格子集合，碰撞判断用；换图时重新展开
let walls = wallSet(map.value)
saveMapId(mapId.value)

// 皮肤：只管外观，和地图机制互不影响
const skinId = ref(getSkin(loadSkinId()).id)
const skin = computed(() => getSkin(skinId.value))
// 地图 + 皮肤 → 渲染层要的 view（配色 / 图案 / 蛇与食物的造型）
const view = computed(() => resolveTheme(map.value, skin.value))

/** 把当前配色注入成 CSS 变量，模板里所有颜色都跟着地图+皮肤走 */
const themeVars = computed(() => {
  const p = view.value.palette
  return {
    '--bd': p.border,
    '--glow': p.glow,
    '--board': p.boardBg,
    '--body': p.snakeBody,
    '--head': p.snakeHead,
    '--accent': p.accent,
    '--text': p.text,
    '--muted': p.muted,
    '--page': p.pageBg
  }
})

const game = ref(null)
const score = ref(0)
const snakeLen = ref(3)
const running = ref(false)
const paused = ref(false)
const gameOver = ref(false)
const overlayTitle = ref('READY?')
const overlayText = ref('')

const overlayClass = computed(() => {
  if (gameOver.value) return 'red'
  if (paused.value) return 'yellow'
  return 'green'
})

// 最高分以后端数据库为准
let best = parseInt(sessionStorage.getItem('snake_best') || '0', 10)
const bestShow = ref(best)

// 排行榜面板
const showRank = ref(false)
const rankList = ref([])
const rankMsg = ref('')

// 皮肤面板
const showSkin = ref(false)
let frame = 0 // 帧计数，彩虹皮肤的色相靠它流动

// 本局是否已经存下来：saved 之后按钮锁住，防止同一局重复保存
const saved = ref(false)
const saving = ref(false)
const saveMsg = ref('')
// 本局有没有录到轨迹（录到了，存完就能在「我的空间 · 对局回放」里重放）
const hasReplayData = ref(false)

const overlayTip = computed(() => {
  if (!gameOver.value) return ''
  if (saved.value) {
    return saveMsg.value || (hasReplayData.value
      ? '本局已保存 ✓ 在「我的空间 · 对局回放」里能重放这一局'
      : '本局已保存 ✓')
  }
  return saveMsg.value || '存下来的对局可以在「我的空间 · 对局回放」里重放'
})

const SIZE = 400
const CELL = SIZE / GRID
let ctx, snake, dir, nextDir, food, speed, timer = null

/* ---------- 本局计时与计数（保存对局时要一起带上） ---------- */
let playStartAt = 0   // 本局开始的时间戳（每次开局重置）
let pauseStartAt = 0  // 当前这一次暂停开始的时间戳，0 表示没在暂停
let pausedMs = 0      // 本局累计暂停了多久，算时长时要扣掉
let lastDuration = 0  // 本局结束时的净时长（秒）
let foodsEaten = 0    // 本局吃掉的食物个数

/* ---------- 回放录制 ----------
 * 每开一局就新建一个录制器，tick() 里记一步。
 * 存的时候才编码成字符串发给后端；不存的话这些数据随页面一起丢掉。
 * 注意只记"蛇头走过的格子 + 食物顺序"，整条蛇靠这些就能重建出来。
 */
let recorder = null

/** 皮肤面板里那三个小色块：蛇身 / 蛇头 / 食物 */
function swatch(s) {
  const p = s.palette || map.value.theme
  return [p.snakeBody, p.snakeHead, p.food]
}

/** 换肤：只重绘，不重开一局 */
function applySkin(id) {
  skinId.value = id
  saveSkinId(id)
  frame = 0
  draw()
}

async function loadRank() {
  const res = await getRank(10)
  if (res.code === 200) {
    rankList.value = res.data || []
    rankMsg.value = rankList.value.length ? '' : '还没有记录，快去创造第一个高分！'
  } else {
    rankMsg.value = res.msg || '排行榜加载失败'
  }
}

async function openRank() {
  showRank.value = true
  rankMsg.value = '加载中...'
  await loadRank()
}

/* ---------------- 对局保存与「我的对局」 ---------------- */

/** 秒数转成人话：95 秒 / 3 分 20 秒 / 1 时 05 分 */
function fmtDuration(sec) {
  const v = Number(sec) || 0
  if (v < 60) return v + ' 秒'
  const m = Math.floor(v / 60)
  const s = v % 60
  if (m < 60) return s ? `${m} 分 ${s} 秒` : `${m} 分`
  return `${Math.floor(m / 60)} 时 ${m % 60} 分`
}

/** 本局净时长（秒）：把暂停的那段时间扣掉 */
function playedSeconds() {
  if (!playStartAt) return 0
  const pausedNow = pauseStartAt ? Date.now() - pauseStartAt : 0
  return Math.max(0, Math.round((Date.now() - playStartAt - pausedMs - pausedNow) / 1000))
}

/**
 * 保存本局 —— 只有玩家点了「保存本局」才会走到这里，不点就什么都不写库
 * 顺便把这一局的走位轨迹一起送上去，之后在「我的空间 · 对局回放」里能重看
 */
async function saveCurrentRecord() {
  if (saving.value || saved.value) return
  saving.value = true
  saveMsg.value = ''

  const track = recorder ? recorder.build() : null
  const replay = track ? encodeTrack(track) : ''
  hasReplayData.value = !!replay

  const res = await saveRecord({
    userId: userId || null,
    username: user,
    score: score.value,
    snakeLen: snakeLen.value,
    foodCount: foodsEaten,
    mapId: mapId.value,
    mapName: map.value.name,
    skinId: skinId.value,
    skinName: skin.value.name,
    duration: lastDuration,
    replay,
    replaySteps: track ? track.steps : 0
  })
  saving.value = false
  if (res.code === 200) {
    saved.value = true
    saveMsg.value = hasReplayData.value
      ? '本局已保存 ✓ 去「我的空间 · 对局回放」就能重看这一局'
      : '本局已保存 ✓'
  } else {
    saveMsg.value = res.msg || '保存失败，请确认后端已启动'
  }
}

/* 把本局分数同步到后端数据库（后端只在更大时才更新） */
async function pushScore() {
  if (!userId) return
  const res = await saveScore(userId, score.value)
  if (res.code === 200) {
    best = res.data.score || 0
    bestShow.value = best
  }
}

function readyText() {
  const m = map.value
  return `${m.name} · ${m.rule}<br>方向键 / WASD 移动 · 空格暂停<br>吃掉食物 ${m.rules.foodScore} 分，会变长加速`
}

/** 随机放食物：既不能压在蛇身上，也不能落在障碍块里 */
function placeFood() {
  let guard = 0
  do {
    food = { x: Math.floor(Math.random() * GRID), y: Math.floor(Math.random() * GRID) }
    guard++
  } while (
    guard < 500 &&
    (walls.has(food.x + ',' + food.y) || snake.some((s) => s.x === food.x && s.y === food.y))
  )
}

function reset() {
  snake = [{ x: 10, y: 10 }, { x: 9, y: 10 }, { x: 8, y: 10 }]
  dir = { x: 1, y: 0 }
  nextDir = dir
  speed = map.value.rules.speed
  gameOver.value = false
  paused.value = false
  overlayTitle.value = 'READY?'
  overlayText.value = readyText()
  // 新的一局：清空上一局的"存/不存"状态，否则按钮会一直是灰的
  saved.value = false
  saving.value = false
  saveMsg.value = ''
  foodsEaten = 0
  lastDuration = 0
  // 计时归零；真正开局时 start() 会用当前时间戳重新开始计时
  playStartAt = 0
  pauseStartAt = 0
  pausedMs = 0
  placeFood()
  // 录制器要在食物就位之后再建：开局那个食物也是轨迹的一部分
  recorder = createRecorder({
    grid: GRID,
    mapId: mapId.value,
    skinId: skinId.value,
    snake,
    food,
    stepMs: map.value.rules.speed
  })
  hasReplayData.value = false
  updateHud()
  draw()
}

function updateHud() {
  snakeLen.value = snake.length
  bestShow.value = best
}

function die() {
  gameOver.value = true
  running.value = false
  clearInterval(timer)
  if (score.value > best) {
    best = score.value
    bestShow.value = best
  }
  pushScore()
  updateHud()
  draw()
  // 定格本局时长，后面点「保存本局」时直接用这个值
  lastDuration = playedSeconds()
  pauseStartAt = 0
  overlayTitle.value = 'GAME OVER'
  overlayText.value = `${map.value.name} · 本局得分：${score.value}<br>`
    + `吃掉 ${foodsEaten} 个食物 · 用时 ${fmtDuration(lastDuration)}<br>历史最高分：${best}`
}

function tick() {
  if (gameOver.value || paused.value) return
  dir = nextDir
  const head = { x: snake[0].x + dir.x, y: snake[0].y + dir.y }

  if (map.value.rules.wrap) {
    // 极地冰川：穿墙，从对面出来
    head.x = (head.x + GRID) % GRID
    head.y = (head.y + GRID) % GRID
  } else if (head.x < 0 || head.y < 0 || head.x >= GRID || head.y >= GRID) {
    return die()
  }

  if (walls.has(head.x + ',' + head.y)) return die()
  if (snake.some((s) => s.x === head.x && s.y === head.y)) return die()

  snake.unshift(head)

  if (head.x === food.x && head.y === food.y) {
    score.value += map.value.rules.foodScore
    foodsEaten++
    placeFood()
    const r = map.value.rules
    if (speed > r.minSpeed) {
      speed -= r.step
      clearInterval(timer)
      timer = setInterval(tick, speed)
    }
  } else {
    snake.pop()
  }
  // 记一步回放：走到了哪一格 + 此刻食物在哪（吃到的话这里已经是新食物了）
  if (recorder) recorder.push(head, food)
  updateHud()
  draw()
}

function draw() {
  const v = view.value
  frame++
  // 底板 + 图案 + 障碍 + 可穿越虚线边
  paintBoard(ctx, v, SIZE, GRID)
  // 食物（造型跟皮肤走）
  drawFood(ctx, v, food, CELL)
  // 蛇（造型跟皮肤走，frame 供彩虹皮肤流动）
  drawSnake(ctx, v, snake, dir, CELL, frame)
}

function start() {
  if (paused.value && !gameOver.value) {
    // 从暂停回到游戏：把这段暂停的时间记下来，最后算时长时扣掉
    paused.value = false
    if (pauseStartAt) {
      pausedMs += Date.now() - pauseStartAt
      pauseStartAt = 0
    }
    return
  }
  score.value = 0
  reset()
  running.value = true
  // 重置本局计时器
  playStartAt = Date.now()
  pauseStartAt = 0
  pausedMs = 0
  clearInterval(timer)
  timer = setInterval(tick, speed)
}

/** 换地图：记住选择 + 重开一局（分数清零，最高分不动） */
function switchMap(id) {
  if (id === mapId.value) return
  mapId.value = id
  saveMapId(id)
  walls = wallSet(map.value)
  clearInterval(timer)
  running.value = false
  gameOver.value = false
  score.value = 0
  reset()
}

function onKey(e) {
  if (e.key === ' ') {
    e.preventDefault()
    if (!running.value) return
    paused.value = !paused.value
    if (paused.value) {
      pauseStartAt = Date.now()
      overlayTitle.value = 'PAUSED'
      overlayText.value = '按 空格键 继续'
    } else if (pauseStartAt) {
      pausedMs += Date.now() - pauseStartAt
      pauseStartAt = 0
    }
    return
  }
  let nd = null
  if (e.key === 'ArrowUp' || e.key === 'w' || e.key === 'W') nd = { x: 0, y: -1 }
  else if (e.key === 'ArrowDown' || e.key === 's' || e.key === 'S') nd = { x: 0, y: 1 }
  else if (e.key === 'ArrowLeft' || e.key === 'a' || e.key === 'A') nd = { x: -1, y: 0 }
  else if (e.key === 'ArrowRight' || e.key === 'd' || e.key === 'D') nd = { x: 1, y: 0 }
  if (nd && !(nd.x === -dir.x && nd.y === -dir.y)) {
    nextDir = nd
    e.preventDefault()
  }
}

function logout() {
  sessionStorage.removeItem('snake_user')
  router.push('/login')
}

onMounted(() => {
  ctx = game.value.getContext('2d')
  reset()
  document.addEventListener('keydown', onKey)
  // 老链接可能还带着 ?panel=records（那会儿对局面板还挂在游戏页上）。
  // 现在对局统一收到「我的空间」了，遇到这种地址直接把人送过去。
  if (route.query.panel === 'records') {
    router.replace({ path: '/my', query: { tab: 'records' } })
  }
})

onBeforeUnmount(() => {
  clearInterval(timer)
  document.removeEventListener('keydown', onKey)
})
</script>

<style scoped>
.page {
  height: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background-color: var(--page, #0b1a0f);
  background-image:
    linear-gradient(rgba(255, 255, 255, 0.03) 1px, transparent 1px),
    linear-gradient(90deg, rgba(255, 255, 255, 0.03) 1px, transparent 1px);
  background-size: 20px 20px;
  overflow: auto;
  color: var(--text, #4ade80);
}

.topbar {
  position: fixed;
  top: 0;
  right: 0;
  left: 0;
  padding: 10px 16px;
  display: flex;
  justify-content: space-between;
  font-size: 13px;
  color: var(--text, #4ade80);
}

.topbar .user b {
  color: #facc15;
}

.topbar .logout {
  color: var(--text, #4ade80);
  cursor: pointer;
}

.topbar .logout:hover {
  text-shadow: 0 0 8px var(--glow, rgba(74, 222, 128, 0.8));
}

.topbar-right {
  display: flex;
  gap: 18px;
}

.topbar .rank-link,
.topbar .home-link {
  color: #a3e635;
  cursor: pointer;
}

.topbar .rank-link:hover,
.topbar .home-link:hover {
  text-shadow: 0 0 8px rgba(163, 230, 53, 0.8);
}

.topbar .skin-link {
  color: #facc15;
  cursor: pointer;
}

.topbar .skin-link:hover {
  text-shadow: 0 0 8px rgba(250, 204, 21, 0.8);
}

.topbar .record-link {
  color: #38bdf8;
  cursor: pointer;
}

.topbar .record-link:hover {
  text-shadow: 0 0 8px rgba(56, 189, 248, 0.8);
}

.topbar .space-link {
  color: #a78bfa;
  cursor: pointer;
}

.topbar .space-link:hover {
  text-shadow: 0 0 8px rgba(167, 139, 250, 0.8);
}

/* ---- 皮肤弹层 ---- */
.skin-mask {
  position: fixed;
  inset: 0;
  z-index: 110;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(7, 19, 10, 0.88);
}

.skin-box {
  width: 440px;
  max-height: 88vh;
  overflow-y: auto;
  padding: 26px 24px 20px;
  text-align: center;
  background: rgba(7, 19, 10, 0.98);
  border: 4px solid var(--bd, #4ade80);
  box-shadow: 0 0 30px var(--glow, rgba(74, 222, 128, 0.35));
}

.skin-title {
  font-size: 20px;
  letter-spacing: 6px;
  color: var(--text, #4ade80);
  text-shadow: 0 0 12px var(--glow, rgba(74, 222, 128, 0.7));
}

.skin-sub {
  margin: 5px 0 16px;
  font-size: 11px;
  letter-spacing: 2px;
  color: var(--muted, #14532d);
}

.skin-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
}

.skin-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  padding: 9px 4px;
  font-family: inherit;
  font-size: 12px;
  color: var(--text, #4ade80);
  background: transparent;
  border: 2px solid var(--muted, #166534);
  cursor: pointer;
  transition: all 0.15s;
}

.skin-item:hover {
  border-color: var(--bd, #4ade80);
  box-shadow: 0 0 10px var(--glow, rgba(74, 222, 128, 0.35));
}

.skin-item.on {
  border-color: var(--bd, #4ade80);
  background: rgba(255, 255, 255, 0.07);
  box-shadow: 0 0 12px var(--glow, rgba(74, 222, 128, 0.5));
}

.skin-dots {
  display: flex;
  gap: 3px;
}

.skin-dots i {
  display: block;
  width: 11px;
  height: 11px;
  border: 1px solid rgba(255, 255, 255, 0.25);
}

.skin-name {
  letter-spacing: 1px;
}

.skin-desc {
  min-height: 34px;
  margin: 16px 0 14px;
  font-size: 12px;
  line-height: 1.9;
  color: #a3e635;
}

/* ---- 排行榜弹层 ---- */
.rank-mask {
  position: fixed;
  inset: 0;
  z-index: 100;
  background: rgba(7, 19, 10, 0.88);
  display: flex;
  align-items: center;
  justify-content: center;
}

.rank-box {
  width: 340px;
  padding: 28px 26px 22px;
  background: rgba(7, 19, 10, 0.98);
  border: 4px solid var(--bd, #4ade80);
  box-shadow: 0 0 30px var(--glow, rgba(74, 222, 128, 0.35));
  text-align: center;
}

.rank-title {
  font-size: 22px;
  letter-spacing: 6px;
  color: var(--text, #4ade80);
  text-shadow: 0 0 12px var(--glow, rgba(74, 222, 128, 0.7));
}

.rank-sub {
  color: var(--muted, #14532d);
  font-size: 11px;
  letter-spacing: 3px;
  margin: 4px 0 18px;
}

.rank-msg {
  color: #a3e635;
  font-size: 13px;
  padding: 18px 0;
}

.rank-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 14px;
  margin-bottom: 18px;
}

.rank-table th {
  color: #a3e635;
  font-size: 12px;
  letter-spacing: 2px;
  padding: 6px 4px;
  border-bottom: 2px solid var(--muted, #166534);
}

.rank-table td {
  padding: 7px 4px;
  border-bottom: 1px solid var(--muted, #14532d);
  color: var(--text, #4ade80);
}

.rank-table td.sc {
  color: #facc15;
}

.rank-table tr.me td {
  background: rgba(74, 222, 128, 0.12);
}

.btn.small {
  padding: 8px 22px;
  font-size: 13px;
}

/* ---- 游戏结束时的「保存本局 / 不保存」按钮组 ---- */
.overlay-btns {
  display: flex;
  gap: 12px;
}

.btn.ghost {
  background: transparent;
  color: var(--text, #4ade80);
  border: 2px solid var(--muted, #166534);
  box-shadow: none;
}

.btn.ghost:hover {
  background: transparent;
  color: #facc15;
  border-color: #facc15;
  box-shadow: 0 0 12px rgba(250, 204, 21, 0.35);
}

.btn:disabled {
  cursor: default;
  opacity: 0.75;
  background: #a3e635;
  box-shadow: 0 0 10px rgba(163, 230, 53, 0.5);
}

.overlay-tip {
  max-width: 320px;
  font-size: 12px;
  line-height: 1.8;
  color: #38bdf8;
}

.overlay-tip.err {
  color: #f87171;
}


h1 {
  letter-spacing: 6px;
  margin-bottom: 6px;
  text-shadow: 0 0 10px var(--glow, rgba(74, 222, 128, 0.6));
}

.sub {
  color: var(--muted, #14532d);
  margin-bottom: 16px;
  letter-spacing: 2px;
  font-size: 13px;
}

/* ---- 地图切换 tab ---- */
.map-tabs {
  display: flex;
  gap: 8px;
  margin-bottom: 14px;
}

.map-tab {
  --c: #4ade80;
  --g: rgba(74, 222, 128, 0.35);
  font-family: inherit;
  font-size: 12.5px;
  letter-spacing: 2px;
  padding: 7px 16px;
  cursor: pointer;
  color: var(--c);
  background: transparent;
  border: 2px solid var(--muted, #166534);
  transition: all 0.15s;
}

.map-tab:hover {
  border-color: var(--c);
  box-shadow: 0 0 10px var(--g);
}

.map-tab.on {
  color: #07130a;
  background: var(--c);
  border-color: var(--c);
  box-shadow: 0 0 14px var(--g);
}

.hud {
  width: 408px;
  display: flex;
  justify-content: space-between;
  margin-bottom: 10px;
  font-size: 15px;
}

.hud b {
  color: #facc15;
}

.board-wrap {
  position: relative;
  border: 4px solid var(--bd, #4ade80);
  box-shadow: 0 0 24px var(--glow, rgba(74, 222, 128, 0.35));
  background: var(--board, #07130a);
}

canvas {
  display: block;
}

.overlay {
  position: absolute;
  inset: 0;
  background: rgba(7, 19, 10, 0.85);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 14px;
  text-align: center;
}

.overlay h2 {
  letter-spacing: 4px;
}

.overlay h2.green {
  color: var(--text, #4ade80);
  text-shadow: 0 0 10px var(--glow, rgba(74, 222, 128, 0.6));
}

.overlay h2.yellow {
  color: #facc15;
  text-shadow: 0 0 10px rgba(250, 204, 21, 0.7);
}

.overlay h2.red {
  color: #ef4444;
  text-shadow: 0 0 10px rgba(239, 68, 68, 0.7);
}

.overlay p {
  color: #a3e635;
  font-size: 13px;
  line-height: 1.9;
}

.btn {
  font-family: inherit;
  background: var(--bd, #4ade80);
  color: #07130a;
  border: none;
  padding: 10px 26px;
  font-size: 15px;
  font-weight: bold;
  letter-spacing: 2px;
  cursor: pointer;
  box-shadow: 0 0 12px var(--glow, rgba(74, 222, 128, 0.6));
}

.btn:hover {
  background: #facc15;
  box-shadow: 0 0 14px rgba(250, 204, 21, 0.7);
}

.tips {
  margin-top: 14px;
  color: var(--muted, #14532d);
  font-size: 12px;
  letter-spacing: 1px;
}
</style>
