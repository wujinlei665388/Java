<template>
  <div class="my">
    <BgSnake />
    <div class="grid-bg"></div>

    <!-- 顶部导航（和首页同一套） -->
    <header class="nav">
      <div class="logo"><span class="dot"></span>贪吃蛇<b>SNAKE</b></div>
      <nav class="nav-links">
        <a @click.prevent="$router.push('/')">首 页</a>
        <a @click.prevent="goHome('maps')">地 图</a>
        <a @click.prevent="goHome('how')">玩 法</a>
        <a @click.prevent="goHome('rank')">排行榜</a>
      </nav>
      <div class="nav-right">
        <template v-if="user">
          <span class="who">玩家 <b>{{ user }}</b></span>
          <button class="btn ghost sm" @click="startGame">开 始 游 戏</button>
          <button class="btn ghost sm" @click="logout">退出</button>
        </template>
        <template v-else>
          <button class="btn ghost sm" @click="$router.push('/login')">登 录</button>
          <button class="btn sm" @click="$router.push('/register')">注 册</button>
        </template>
      </div>
    </header>

    <main class="wrap">
      <!-- 头部 -->
      <section class="hero">
        <div class="badge">M Y &nbsp; S P A C E</div>
        <h1>我 的 空 间</h1>
        <p class="hero-desc">
          十一款皮肤随便试，左下角这只蛇会一直跑给你看；<br>
          存下来的每一局都能像放录像一样重演一遍。
        </p>
      </section>

      <!-- 两个功能的入口 -->
      <div class="tabs">
        <button class="tab" :class="{ on: tab === 'skins' }" @click="switchTab('skins')">
          皮肤库<i>{{ skins.length }} 款</i>
        </button>
        <button class="tab" :class="{ on: tab === 'records' }" @click="switchTab('records')">
          对局回放<i>{{ user ? records.length + ' 局已存' : '需登录' }}</i>
        </button>
      </div>

      <!-- ==================== 皮肤库 ==================== -->
      <section class="sec" v-show="tab === 'skins'">
        <div class="lab">
          <!-- 左：活的试衣间 -->
          <div class="lab-view">
            <div class="lab-frame" :style="{ '--c': skinAccent, '--g': skinGlow }">
              <ReplayBoard :track="demoTrack" :mapId="previewMapId" :skinId="pickedSkin"
                           :size="400" loop />
            </div>
            <div class="lab-maps">
              <span>试衣间底板：</span>
              <button v-for="m in maps" :key="m.id" class="lab-map"
                      :class="{ on: m.id === previewMapId }"
                      :style="{ '--c': m.theme.border }"
                      @click="previewMapId = m.id">{{ m.name }}</button>
            </div>
          </div>

          <!-- 右：当前皮肤档案 -->
          <div class="lab-info" :style="{ '--c': skinAccent, '--g': skinGlow }">
            <div class="li-head">
              <h2>{{ skin.name }}</h2>
              <em>{{ skin.en }}</em>
            </div>
            <p class="li-desc">{{ skin.desc }}</p>
            <div class="chips"><span v-for="t in skin.tags" :key="t">{{ t }}</span></div>

            <div class="li-swatches">
              <div class="sw"><i :style="{ background: pal.snakeHead }"></i><span>蛇头</span></div>
              <div class="sw"><i :style="{ background: pal.snakeBody }"></i><span>蛇身</span></div>
              <div class="sw"><i :style="{ background: pal.food }"></i><span>食物</span></div>
              <div class="sw"><i :style="{ background: pal.boardBg, borderColor: pal.border }"></i><span>底板</span></div>
            </div>

            <ul class="li-facts">
              <li>底板图案：<b>{{ patternName }}</b></li>
              <li>蛇身造型：<b>{{ snakeStyleName }}</b></li>
              <li>食物造型：<b>{{ foodStyleName }}</b></li>
            </ul>

            <button class="btn block" @click="useSkinAndPlay">用这套皮肤开一局</button>
            <div class="li-note">
              皮肤只改外观，地图的障碍、穿墙、速度、分值都不受影响。
              现在这套是「{{ mapById(previewMapId).name }} + {{ skin.name }}」。
            </div>
          </div>
        </div>

        <!-- 11 款皮肤 -->
        <div class="sec-head">
          <h2>全部皮肤</h2>
          <span>S K I N S &nbsp;/&nbsp; 点哪款，上面就换成哪款</span>
        </div>
        <div class="skins-grid">
          <article v-for="s in skins" :key="s.id" class="skin-card"
                   :class="{ on: s.id === pickedSkin }"
                   :style="{ '--c': accentOf(s), '--g': glowOf(s) }"
                   @click="pickedSkin = s.id">
            <div class="skin-thumb">
              <canvas :ref="(el) => setThumb(s.id, el)" width="120" height="120"></canvas>
              <div class="badge-pick" v-if="s.id === pickedSkin">使用中</div>
            </div>
            <h3>{{ s.name }}<em>{{ s.en }}</em></h3>
            <div class="chips"><span v-for="t in s.tags" :key="t">{{ t }}</span></div>
          </article>
        </div>
      </section>

      <!-- ==================== 对局回放 ==================== -->
      <section class="sec" v-show="tab === 'records'">
        <!-- 没登录 -->
        <div class="need-login" v-if="!user">
          <div class="nl-title">还没登录</div>
          <p>对局记录是跟着玩家走的，登录之后才能看到自己存下来的对局和回放。</p>
          <button class="btn" @click="$router.push('/login')">去 登 录</button>
        </div>

        <template v-else>
          <!-- 统计 -->
          <div class="rec-stats" v-if="stats">
            <div class="rs"><b>{{ stats.games }}</b><span>已存局数</span></div>
            <div class="rs"><b>{{ stats.best }}</b><span>最高分</span></div>
            <div class="rs"><b>{{ stats.avgScore }}</b><span>平均分</span></div>
            <div class="rs"><b>{{ stats.maxLen }}</b><span>最长蛇</span></div>
            <div class="rs"><b>{{ fmtDuration(stats.totalDuration) }}</b><span>总时长</span></div>
            <div class="rs"><b>{{ stats.totalFood }}</b><span>总食物</span></div>
          </div>

          <div class="sec-head">
            <h2>我保存的对局</h2>
            <span>R E P L A Y S &nbsp;/&nbsp; 带「回放」的能看录像</span>
          </div>

          <div class="rec-msg" v-if="recMsg">{{ recMsg }}</div>

          <div class="rec-list" v-else>
            <div class="rec-row" v-for="r in records" :key="r.id">
              <div class="rr-main">
                <div class="rr-score">{{ r.score }}<i>分</i></div>
                <div class="rr-info">
                  <div class="rr-line1">
                    <span class="rr-map">{{ r.mapName }}</span>
                    <span class="rr-dot">·</span>
                    <span class="rr-skin">{{ r.skinName }}</span>
                    <span class="rr-tag" v-if="r.hasReplay">可回放 {{ r.replaySteps }} 步</span>
                    <span class="rr-tag off" v-else>仅数据</span>
                  </div>
                  <div class="rr-line2">
                    长度 {{ r.snakeLen }} · 食物 {{ r.foodCount }} · 用时 {{ fmtDuration(r.duration) }} · {{ r.createTime }}
                  </div>
                </div>
              </div>
              <div class="rr-actions">
                <button class="btn tiny" :disabled="!r.hasReplay || replayLoading === r.id"
                        @click="openReplay(r)">
                  {{ replayLoading === r.id ? '读取中…' : (r.hasReplay ? '回 放' : '无回放') }}
                </button>
                <button class="btn tiny danger" v-if="pendingDel !== r.id" @click="askDelete(r.id)">删 除</button>
                <button class="btn tiny danger on" v-else @click="doDelete(r)">确认删除</button>
              </div>
            </div>
          </div>
        </template>
      </section>
    </main>

    <footer class="foot">
      贪吃蛇 · SNAKE GAME &nbsp;|&nbsp; 我的空间：皮肤库 + 对局回放
    </footer>

    <!-- 回放弹层 -->
    <div class="replay-mask" v-show="replayOpen" @click.self="closeReplay">
      <div class="replay-box">
        <div class="rb-title">回 放</div>
        <div class="rb-sub" v-if="replayRec">
          {{ replayRec.mapName }} · {{ replayRec.skinName }} ·
          {{ replayRec.score }} 分 · {{ replayRec.createTime }}
        </div>
        <ReplayBoard :track="replayTrack" :size="400" controls :speed="1" />
        <button class="btn small" @click="closeReplay">关 闭</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import BgSnake from '../components/BgSnake.vue'
import ReplayBoard from '../components/ReplayBoard.vue'
import { MAPS, GRID, getMap, loadMapId, saveMapId } from '../game/maps'
import { SKINS, getSkin, resolveTheme, loadSkinId, saveSkinId } from '../game/skins'
import { paintPreview } from '../game/render'
import { buildDemoTrack } from '../game/replay'
import { getMyRecords, getRecordStats, deleteRecord, getRecordReplay } from '../api/record'

const route = useRoute()
const router = useRouter()

const maps = MAPS
const skins = SKINS

const user = ref(sessionStorage.getItem('snake_user') || '')
const userId = sessionStorage.getItem('snake_uid') || ''

/* ---------------- 标签页 ---------------- */
// 支持 /my?tab=records 直接落到对局那一栏（游戏页的「我的对局」就是这么跳的）
const tab = ref(route.query.tab === 'records' ? 'records' : 'skins')
function switchTab(t) {
  tab.value = t
  // 把状态同步到地址栏，刷新后还停在这一栏
  const q = { ...route.query }
  if (t === 'skins') delete q.tab
  else q.tab = t
  router.replace({ path: '/my', query: q })
}

const mapById = (id) => getMap(id)

/* ---------------- 皮肤库 ---------------- */
// 进来默认用"玩家上次选的那款"，换过就立刻记住
const pickedSkin = ref(getSkin(loadSkinId()).id)
const previewMapId = ref(loadMapId())

const skin = computed(() => getSkin(pickedSkin.value))
const pal = computed(() => resolveTheme(getMap(previewMapId.value), skin.value).palette)

function accentOf(s) {
  return (s.palette || getMap(previewMapId.value).theme).border
}
function glowOf(s) {
  return (s.palette || getMap(previewMapId.value).theme).glow
}
const skinAccent = computed(() => accentOf(skin.value))
const skinGlow = computed(() => glowOf(skin.value))

// 试衣间里的演示轨迹：只跟"预览地图"有关（走位避障），皮肤由 ReplayBoard 的 skinId 决定，
// 所以换皮肤时动画不会被打断重来
const demoTrack = computed(() => buildDemoTrack(getMap(previewMapId.value), null))

const PATTERN_NAMES = {
  grid: '网格', dots: '点阵', scan: '扫描线', stars: '星点',
  frost: '冰纹斜线', circuit: '电路走线', petal: '飘落花瓣', none: '纯色'
}
const SNAKE_NAMES = {
  solid: '实心方块', rainbow: '七彩流动', gradient: '渐变', outline: '霓虹描边',
  pixel: '像素硬边', glass: '半透明高光', ghost: '幽影渐隐'
}
const FOOD_NAMES = {
  square: '方块', circle: '圆点', star: '五角星', diamond: '菱形',
  crystal: '六棱冰晶', coin: '金币', petal: '花瓣', pixel: '像素块'
}
const patternName = computed(() => PATTERN_NAMES[skin.value.pattern] || skin.value.pattern)
const snakeStyleName = computed(() => SNAKE_NAMES[skin.value.snakeStyle] || skin.value.snakeStyle)
const foodStyleName = computed(() => FOOD_NAMES[skin.value.foodStyle] || skin.value.foodStyle)

// 皮肤卡片的小缩略图（静态画一帧就行，11 个画布一起跑动画太费）
const thumbs = {}
function setThumb(id, el) {
  if (el) thumbs[id] = el
}
function paintThumbs() {
  for (const s of SKINS) {
    const cv = thumbs[s.id]
    if (cv) paintPreview(cv.getContext('2d'), resolveTheme(getMap(previewMapId.value), s), 120, GRID)
  }
}

function useSkinAndPlay() {
  saveSkinId(pickedSkin.value)
  saveMapId(previewMapId.value)
  if (!user.value) {
    router.push({ path: '/login', query: { map: previewMapId.value } })
    return
  }
  router.push({ path: '/game', query: { map: previewMapId.value } })
}

function startGame() {
  if (!user.value) {
    router.push('/login')
    return
  }
  router.push({ path: '/game', query: { map: loadMapId() } })
}

/* ---------------- 对局列表 ---------------- */
const records = ref([])
const stats = ref(null)
const recMsg = ref('')
const replayLoading = ref(null)

function fmtDuration(sec) {
  const v = Number(sec) || 0
  if (v < 60) return v + ' 秒'
  const m = Math.floor(v / 60)
  const s = v % 60
  if (m < 60) return s ? `${m} 分 ${s} 秒` : `${m} 分`
  return `${Math.floor(m / 60)} 时 ${m % 60} 分`
}

async function loadRecords() {
  if (!user.value) return
  recMsg.value = '加载中…'
  const uid = userId || null
  const [list, st] = await Promise.all([
    getMyRecords(uid, user.value, 50),
    getRecordStats(uid, user.value)
  ])
  if (list.code === 200) {
    records.value = list.data || []
    recMsg.value = records.value.length
      ? ''
      : '还没有保存过对局。玩一局，结束时点「保 存 本 局」就会出现在这里。'
  } else {
    recMsg.value = list.msg || '加载失败，确认后端已启动'
  }
  stats.value = st.code === 200 ? st.data : null
}

/* ---------------- 回放 ---------------- */
const replayOpen = ref(false)
const replayTrack = ref('')
const replayRec = ref(null)

async function openReplay(r) {
  if (!r.hasReplay || replayLoading.value) return
  replayLoading.value = r.id
  const res = await getRecordReplay(r.id, userId || null, user.value)
  replayLoading.value = null
  if (res.code === 200) {
    replayRec.value = res.data.record
    replayTrack.value = res.data.replay
    replayOpen.value = true
  } else {
    recMsg.value = res.msg || '这一局读不到回放'
    await loadRecords()
  }
}

function closeReplay() {
  replayOpen.value = false
  replayTrack.value = ''
}

/* ---------------- 删除（内联二次确认，不用弹窗） ---------------- */
const pendingDel = ref(null)
let delTimer = null

function askDelete(id) {
  pendingDel.value = id
  clearTimeout(delTimer)
  delTimer = setTimeout(() => { pendingDel.value = null }, 4000)
}

async function doDelete(r) {
  clearTimeout(delTimer)
  pendingDel.value = null
  const res = await deleteRecord(r.id, userId || null, user.value)
  if (res.code === 200) {
    await loadRecords()
  } else {
    recMsg.value = res.msg || '删除失败'
  }
}

/* ---------------- 杂项 ---------------- */
function goHome(id) {
  router.push({ path: '/', query: { to: id } })
}

function logout() {
  sessionStorage.removeItem('snake_user')
  sessionStorage.removeItem('snake_uid')
  sessionStorage.removeItem('snake_best')
  user.value = ''
  records.value = []
  stats.value = null
  tab.value = 'skins'
  router.replace({ path: '/my' })
}

onMounted(async () => {
  await nextTick()
  paintThumbs()
  // 已登录就顺手把对局和统计一起拉回来，切到那一栏时不用再等
  if (user.value) {
    await loadRecords()
  }
})

// 换预览地图：缩略图要跟着重画（皮肤卡也是跟着地图配色走的）
watch(previewMapId, async () => {
  saveMapId(previewMapId.value)
  await nextTick()
  paintThumbs()
})

// 选中的皮肤立刻记住，去游戏页就是它
watch(pickedSkin, (id) => saveSkinId(id))
</script>

<style scoped>
.my {
  position: relative;
  height: 100%;
  overflow-y: auto;
  overflow-x: hidden;
}

.grid-bg {
  position: fixed;
  inset: 0;
  pointer-events: none;
  background-image:
    linear-gradient(rgba(74, 222, 128, 0.05) 1px, transparent 1px),
    linear-gradient(90deg, rgba(74, 222, 128, 0.05) 1px, transparent 1px);
  background-size: 20px 20px;
}

/* ---------------- 导航 ---------------- */
.nav {
  position: sticky;
  top: 0;
  z-index: 20;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
  padding: 13px 28px;
  background: rgba(11, 26, 15, 0.84);
  backdrop-filter: blur(8px);
  border-bottom: 1px solid #14532d;
}

.logo {
  display: flex;
  align-items: center;
  gap: 9px;
  font-size: 15px;
  letter-spacing: 3px;
  color: #4ade80;
}

.logo b {
  color: #facc15;
  letter-spacing: 2px;
}

.logo .dot {
  width: 10px;
  height: 10px;
  background: #4ade80;
  box-shadow: 0 0 10px #4ade80;
}

.nav-links {
  display: flex;
  gap: 22px;
  font-size: 13px;
  letter-spacing: 2px;
}

.nav-links a {
  cursor: pointer;
  color: #4ade80;
  transition: color 0.15s;
}

.nav-links a:hover {
  color: #facc15;
  text-shadow: 0 0 8px rgba(250, 204, 21, 0.7);
}

.nav-right {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 12px;
}

.who {
  color: #a3e635;
  letter-spacing: 1px;
}

.who b {
  color: #facc15;
}

/* ---------------- 按钮 ---------------- */
.btn {
  font-family: inherit;
  background: #4ade80;
  color: #07130a;
  border: 2px solid #4ade80;
  padding: 10px 22px;
  font-size: 14px;
  font-weight: bold;
  letter-spacing: 2px;
  cursor: pointer;
  box-shadow: 0 0 12px rgba(74, 222, 128, 0.45);
  transition: all 0.15s;
}

.btn:hover:not(:disabled) {
  background: #facc15;
  border-color: #facc15;
  box-shadow: 0 0 16px rgba(250, 204, 21, 0.7);
}

.btn:disabled {
  opacity: 0.45;
  cursor: not-allowed;
  box-shadow: none;
}

.btn.ghost {
  background: transparent;
  color: #4ade80;
  border: 2px solid #166534;
  box-shadow: none;
}

.btn.ghost:hover {
  color: #facc15;
  border-color: #facc15;
  box-shadow: 0 0 12px rgba(250, 204, 21, 0.35);
}

.btn.sm {
  padding: 7px 14px;
  font-size: 12px;
  letter-spacing: 1px;
}

.btn.small {
  padding: 8px 22px;
  font-size: 13px;
}

.btn.tiny {
  padding: 6px 14px;
  font-size: 12px;
  letter-spacing: 1px;
  box-shadow: none;
}

.btn.block {
  width: 100%;
}

.btn.danger {
  background: transparent;
  color: #f87171;
  border: 2px solid #7f1d1d;
  box-shadow: none;
}

.btn.danger:hover,
.btn.danger.on {
  color: #fff;
  background: #dc2626;
  border-color: #dc2626;
}

/* ---------------- 头部 ---------------- */
.wrap {
  position: relative;
  z-index: 10;
  max-width: 1080px;
  margin: 0 auto;
  padding: 34px 28px 60px;
}

.hero {
  text-align: center;
  padding: 18px 0 34px;
}

.badge {
  display: inline-block;
  font-size: 11px;
  letter-spacing: 3px;
  color: #a3e635;
  border: 1px solid #166534;
  padding: 5px 14px;
  margin-bottom: 22px;
}

.hero h1 {
  font-size: 42px;
  letter-spacing: 14px;
  padding-left: 14px;
  text-shadow: 0 0 26px rgba(74, 222, 128, 0.55);
}

.hero-desc {
  color: #a3e635;
  font-size: 13.5px;
  line-height: 2;
  margin: 20px auto 0;
  max-width: 620px;
  opacity: 0.85;
}

/* ---------------- 标签页 ---------------- */
.tabs {
  display: flex;
  gap: 12px;
  justify-content: center;
  margin-bottom: 38px;
}

.tab {
  font-family: inherit;
  font-size: 14px;
  letter-spacing: 3px;
  padding: 11px 30px;
  color: #4ade80;
  background: rgba(7, 19, 10, 0.85);
  border: 2px solid #166534;
  cursor: pointer;
  transition: all 0.15s;
}

.tab i {
  display: block;
  margin-top: 4px;
  font-style: normal;
  font-size: 10px;
  letter-spacing: 1px;
  color: #14532d;
}

.tab:hover {
  border-color: #4ade80;
}

.tab.on {
  color: #07130a;
  background: #4ade80;
  border-color: #4ade80;
  box-shadow: 0 0 18px rgba(74, 222, 128, 0.5);
}

.tab.on i {
  color: rgba(7, 19, 10, 0.6);
}

/* ---------------- 皮肤库：试衣间 ---------------- */
.lab {
  display: grid;
  grid-template-columns: minmax(280px, 1fr) minmax(280px, 1fr);
  gap: 26px;
  align-items: start;
  margin-bottom: 56px;
}

.lab-frame {
  --c: #4ade80;
  --g: rgba(74, 222, 128, 0.35);
  padding: 10px;
  background: rgba(7, 19, 10, 0.9);
  border: 2px solid var(--c);
  box-shadow: 0 0 26px var(--g);
}

.lab-maps {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 14px;
  font-size: 11.5px;
  color: #14532d;
  flex-wrap: wrap;
}

.lab-map {
  font-family: inherit;
  --c: #4ade80;
  font-size: 11.5px;
  letter-spacing: 1px;
  padding: 5px 12px;
  color: #4ade80;
  background: transparent;
  border: 1px solid #166534;
  cursor: pointer;
}

.lab-map.on {
  color: #07130a;
  background: var(--c);
  border-color: var(--c);
}

.lab-info {
  --c: #4ade80;
  --g: rgba(74, 222, 128, 0.35);
  padding: 24px 26px;
  background: rgba(7, 19, 10, 0.9);
  border: 2px solid #166534;
}

.li-head {
  display: flex;
  align-items: baseline;
  gap: 12px;
  border-left: 4px solid var(--c);
  padding-left: 12px;
}

.li-head h2 {
  font-size: 22px;
  letter-spacing: 4px;
  color: var(--c);
}

.li-head em {
  font-style: normal;
  font-size: 10px;
  letter-spacing: 2px;
  color: #14532d;
}

.li-desc {
  margin: 18px 0 14px;
  font-size: 13px;
  line-height: 2;
  color: #4ade80;
  opacity: 0.85;
}

.chips {
  display: flex;
  flex-wrap: wrap;
  gap: 7px;
  margin-bottom: 14px;
}

.chips span {
  font-size: 11px;
  letter-spacing: 1px;
  color: #a3e635;
  border: 1px solid #166534;
  padding: 2px 8px;
}

.li-swatches {
  display: flex;
  gap: 16px;
  margin: 20px 0;
}

.sw {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 7px;
}

.sw i {
  display: block;
  width: 30px;
  height: 30px;
  border: 2px solid #14532d;
}

.sw span {
  font-size: 10px;
  letter-spacing: 1px;
  color: #14532d;
}

.li-facts {
  list-style: none;
  margin-bottom: 22px;
}

.li-facts li {
  font-size: 12px;
  line-height: 2.2;
  color: #4ade80;
  opacity: 0.85;
}

.li-facts b {
  color: #facc15;
  font-weight: normal;
}

.li-note {
  margin-top: 16px;
  padding: 11px 14px;
  font-size: 11.5px;
  line-height: 1.95;
  color: #4ade80;
  background: rgba(74, 222, 128, 0.06);
  border-left: 3px solid #166534;
}

/* ---------------- 区块标题 ---------------- */
.sec {
  margin-bottom: 60px;
}

.sec-head {
  display: flex;
  align-items: baseline;
  gap: 16px;
  margin-bottom: 22px;
  border-left: 4px solid #4ade80;
  padding-left: 14px;
}

.sec-head h2 {
  font-size: 20px;
  letter-spacing: 4px;
  text-shadow: 0 0 10px rgba(74, 222, 128, 0.5);
}

.sec-head span {
  font-size: 11px;
  letter-spacing: 2px;
  color: #14532d;
}

/* ---------------- 皮肤卡 ---------------- */
.skins-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(168px, 1fr));
  gap: 16px;
}

.skin-card {
  --c: #4ade80;
  --g: rgba(74, 222, 128, 0.35);
  display: flex;
  flex-direction: column;
  padding: 12px 12px 16px;
  background: rgba(7, 19, 10, 0.9);
  border: 2px solid #166534;
  cursor: pointer;
  transition: transform 0.18s, border-color 0.18s, box-shadow 0.18s;
}

.skin-card:hover {
  transform: translateY(-3px);
  border-color: var(--c);
  box-shadow: 0 0 20px var(--g);
}

.skin-card.on {
  border-color: var(--c);
  box-shadow: 0 0 22px var(--g);
}

.skin-thumb {
  position: relative;
  width: 120px;
  margin: 0 auto;
  border: 2px solid #14532d;
  background: #07130a;
  line-height: 0;
}

.skin-card.on .skin-thumb {
  border-color: var(--c);
}

.skin-thumb canvas {
  display: block;
  width: 100%;
  height: auto;
}

.badge-pick {
  position: absolute;
  top: 4px;
  right: 4px;
  padding: 1px 7px;
  font-size: 10px;
  font-weight: bold;
  letter-spacing: 1px;
  line-height: 1.8;
  color: #07130a;
  background: var(--c);
}

.skin-card h3 {
  margin-top: 12px;
  font-size: 13.5px;
  letter-spacing: 2px;
  color: var(--c);
  text-align: center;
}

.skin-card h3 em {
  display: block;
  margin-top: 4px;
  font-style: normal;
  font-size: 9px;
  letter-spacing: 1.5px;
  color: #14532d;
}

.skin-card .chips {
  justify-content: center;
  margin: 10px 0 0;
}

/* ---------------- 对局列表 ---------------- */
.need-login {
  padding: 34px 30px;
  text-align: center;
  background: rgba(7, 19, 10, 0.9);
  border: 2px solid #166534;
}

.nl-title {
  font-size: 18px;
  letter-spacing: 4px;
  color: #facc15;
  margin-bottom: 14px;
}

.need-login p {
  font-size: 13px;
  line-height: 2;
  color: #4ade80;
  opacity: 0.85;
  margin-bottom: 22px;
}

.rec-stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(110px, 1fr));
  gap: 12px;
  margin-bottom: 34px;
}

.rs {
  padding: 16px 10px;
  text-align: center;
  background: rgba(7, 19, 10, 0.9);
  border: 2px solid #14532d;
}

.rs b {
  display: block;
  font-size: 22px;
  color: #facc15;
  text-shadow: 0 0 12px rgba(250, 204, 21, 0.4);
}

.rs span {
  display: block;
  margin-top: 7px;
  font-size: 10.5px;
  letter-spacing: 1px;
  color: #14532d;
}

.rec-msg {
  padding: 22px 24px;
  font-size: 13px;
  line-height: 1.9;
  color: #a3e635;
  background: rgba(7, 19, 10, 0.9);
  border: 2px solid #14532d;
}

.rec-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  max-height: 620px;
  overflow-y: auto;
  padding-right: 4px;
}

.rec-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 15px 18px;
  background: rgba(7, 19, 10, 0.9);
  border: 2px solid #14532d;
  transition: border-color 0.15s, box-shadow 0.15s;
}

.rec-row:hover {
  border-color: #4ade80;
  box-shadow: 0 0 18px rgba(74, 222, 128, 0.22);
}

.rr-main {
  display: flex;
  align-items: center;
  gap: 18px;
  min-width: 0;
}

.rr-score {
  font-size: 24px;
  color: #facc15;
  white-space: nowrap;
}

.rr-score i {
  font-style: normal;
  font-size: 11px;
  color: #14532d;
  margin-left: 3px;
}

.rr-info {
  min-width: 0;
}

.rr-line1 {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: #4ade80;
  flex-wrap: wrap;
}

.rr-map {
  color: #a3e635;
  font-weight: bold;
}

.rr-dot {
  color: #14532d;
}

.rr-tag {
  font-size: 10.5px;
  letter-spacing: 1px;
  padding: 2px 8px;
  color: #07130a;
  background: #4ade80;
}

.rr-tag.off {
  color: #14532d;
  background: rgba(20, 83, 45, 0.35);
}

.rr-line2 {
  margin-top: 7px;
  font-size: 11.5px;
  letter-spacing: 0.5px;
  color: #14532d;
}

.rr-actions {
  display: flex;
  gap: 8px;
  flex-shrink: 0;
}

/* ---------------- 回放弹层 ---------------- */
.replay-mask {
  position: fixed;
  inset: 0;
  z-index: 60;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
  background: rgba(3, 10, 5, 0.86);
  backdrop-filter: blur(3px);
}

.replay-box {
  width: 100%;
  max-width: 470px;
  max-height: 92vh;
  overflow-y: auto;
  padding: 26px 26px 22px;
  text-align: center;
  background: #07130a;
  border: 2px solid #4ade80;
  box-shadow: 0 0 40px rgba(74, 222, 128, 0.35);
}

.rb-title {
  font-size: 19px;
  letter-spacing: 8px;
  padding-left: 8px;
  color: #4ade80;
}

.rb-sub {
  margin: 10px 0 20px;
  font-size: 11.5px;
  letter-spacing: 1px;
  color: #a3e635;
}

.replay-box .btn.small {
  margin-top: 20px;
}

/* ---------------- 页脚 ---------------- */
.foot {
  position: relative;
  z-index: 10;
  padding: 24px;
  text-align: center;
  font-size: 11px;
  letter-spacing: 1px;
  color: #14532d;
  border-top: 1px solid #14532d;
}

@media (max-width: 820px) {
  .lab {
    grid-template-columns: 1fr;
  }

  .nav-links {
    display: none;
  }

  .hero h1 {
    font-size: 30px;
    letter-spacing: 8px;
  }

  .rr-main {
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
  }

  .rec-row {
    flex-direction: column;
    align-items: stretch;
  }
}
</style>
