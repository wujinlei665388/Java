<template>
  <div class="home">
    <BgSnake />
    <div class="grid-bg"></div>

    <!-- 顶部导航 -->
    <header class="nav">
      <div class="logo"><span class="dot"></span>贪吃蛇<b>SNAKE</b></div>
      <nav class="nav-links">
        <a @click.prevent="to('maps')">地 图</a>
        <a @click.prevent="to('skins')">皮 肤</a>
        <a @click.prevent="to('how')">玩 法</a>
        <a @click.prevent="to('rank')">排行榜</a>
      </nav>
      <div class="nav-right">
        <template v-if="user">
          <span class="who">玩家 <b>{{ user }}</b></span>
          <button class="btn ghost sm" @click="logout">退出</button>
        </template>
        <template v-else>
          <button class="btn ghost sm" @click="$router.push('/login')">登 录</button>
          <button class="btn sm" @click="$router.push('/register')">注 册</button>
        </template>
      </div>
    </header>

    <main class="wrap">
      <!-- Hero -->
      <section class="hero">
        <div class="badge">VUE 3 · SPRING BOOT · MYSQL</div>
        <h1>贪 吃 蛇</h1>
        <div class="hero-en">S N A K E &nbsp; G A M E</div>
        <p class="hero-desc">
          三种风格地图 + 十一款皮肤，任意搭配。<br>
          选好地图和皮肤，吃掉食物 —— 别撞墙，也别咬到自己。
        </p>
        <div class="hero-actions">
          <button class="btn lg" @click="startGame()">{{ user ? '继 续 游 戏' : '立 即 开 始' }}</button>
          <button class="btn ghost lg" @click="to('maps')">挑 一 张 地 图</button>
        </div>
        <div class="stats">
          <div class="stat"><b>{{ maps.length }}</b><span>种地图</span></div>
          <div class="stat"><b>{{ skins.length }}</b><span>款皮肤</span></div>
          <div class="stat"><b>{{ rankList.length }}</b><span>上榜玩家</span></div>
          <div class="stat"><b>{{ topScore }}</b><span>全服最高分</span></div>
        </div>
      </section>

      <!-- 地图选择 -->
      <section id="maps" class="sec">
        <div class="sec-head">
          <h2>选择地图</h2>
          <span>M A P S &nbsp;/&nbsp; 三种风格，三种节奏</span>
        </div>

        <div class="map-grid">
          <article v-for="m in maps" :key="m.id" class="card"
                   :class="{ on: m.id === picked }"
                   :style="{ '--c': m.theme.border, '--g': m.theme.glow }"
                   @click="pick(m.id)">
            <div class="thumb">
              <canvas :ref="(el) => setThumb(m.id, el)" width="160" height="160"></canvas>
              <div class="badge-pick" v-if="m.id === picked">已选择</div>
            </div>
            <h3>{{ m.name }}<em>{{ m.en }}</em></h3>
            <p class="desc">{{ m.desc }}</p>
            <div class="chips"><span v-for="t in m.tags" :key="t">{{ t }}</span></div>
            <div class="rule">{{ m.rule }}</div>
            <button class="btn card-btn" @click.stop="startGame(m.id)">
              {{ user ? '开 始 这 张' : '选 它 开 玩' }}
            </button>
          </article>
        </div>
      </section>

      <!-- 皮肤 -->
      <section id="skins" class="sec">
        <div class="sec-head">
          <h2>选择皮肤</h2>
          <span>S K I N S &nbsp;/&nbsp; 1 款基础 + 10 款特设，随便配哪张地图</span>
        </div>
        <div class="skins-grid">
          <article v-for="s in skins" :key="s.id" class="skin-card"
                   :class="{ on: s.id === skinId }"
                   :style="{ '--c': skinAccent(s), '--g': skinGlow(s) }"
                   @click="pickSkin(s.id)">
            <div class="skin-thumb">
              <canvas :ref="(el) => setSkinThumb(s.id, el)" width="150" height="150"></canvas>
            </div>
            <h3>{{ s.name }}<em>{{ s.en }}</em></h3>
            <p class="desc">{{ s.desc }}</p>
            <div class="chips"><span v-for="t in s.tags" :key="t">{{ t }}</span></div>
          </article>
        </div>
        <div class="skin-note">
          当前组合：<b>{{ map.name }}</b> + <b>{{ skin.name }}</b><br>
          皮肤只改外观（配色 · 底板图案 · 蛇与食物的造型），地图的障碍、穿越边界、速度、分值都不受影响。
        </div>
      </section>

      <!-- 玩法 -->
      <section id="how" class="sec">
        <div class="sec-head">
          <h2>怎么玩</h2>
          <span>H O W &nbsp; T O &nbsp; P L A Y</span>
        </div>
        <div class="how-grid">
          <div class="how-card">
            <h4>操作</h4>
            <ul>
              <li><kbd>↑</kbd><kbd>↓</kbd><kbd>←</kbd><kbd>→</kbd> 或 <kbd>W</kbd><kbd>A</kbd><kbd>S</kbd><kbd>D</kbd> 控制方向</li>
              <li><kbd>空格</kbd> 暂停 / 继续</li>
              <li>撞墙、撞障碍、咬到自己 → 本局结束</li>
            </ul>
          </div>
          <div class="how-card">
            <h4>计分</h4>
            <ul>
              <li>吃一个食物得分，三张地图分值不同（10 / 15 / 12）</li>
              <li>吃得越多蛇越长、速度越快（最快 70ms 一步）</li>
              <li>只有超过历史最高分才会写进数据库</li>
            </ul>
          </div>
          <div class="how-card">
            <h4>小技巧</h4>
            <ul>
              <li>贴着障碍物走，比绕远路省步数</li>
              <li>极地冰川能穿边界，被围住就往边上跑</li>
              <li>蛇变长后别贴着墙走，转身容易把自己堵死</li>
              <li>皮肤只改外观，游戏里随时能换，不影响本局</li>
            </ul>
          </div>
        </div>
      </section>

      <!-- 排行榜 -->
      <section id="rank" class="sec">
        <div class="sec-head">
          <h2>排行榜</h2>
          <span>T O P &nbsp; 5</span>
        </div>
        <div class="rank-card">
          <div class="rank-msg" v-if="rankMsg">{{ rankMsg }}</div>
          <table class="rank-table" v-else>
            <thead>
              <tr><th>名次</th><th>玩家</th><th>最高分</th></tr>
            </thead>
            <tbody>
              <tr v-for="(r, i) in rankList" :key="r.id" :class="{ me: r.username === user }">
                <td class="no">{{ String(i + 1).padStart(2, '0') }}</td>
                <td>{{ r.username }}</td>
                <td class="sc">{{ r.score }}</td>
              </tr>
            </tbody>
          </table>
          <div class="rank-foot">完整榜单在游戏页右上角「排行榜」里</div>
        </div>
      </section>
    </main>

    <footer class="foot">
      贪吃蛇 · SNAKE GAME &nbsp;|&nbsp; Vue 3 + Spring Boot + MySQL &nbsp;|&nbsp; 方向键移动 · 空格暂停
    </footer>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import BgSnake from '../components/BgSnake.vue'
import { MAPS, GRID, getMap, loadMapId, saveMapId } from '../game/maps'
import { SKINS, getSkin, resolveTheme, loadSkinId, saveSkinId } from '../game/skins'
import { paintPreview } from '../game/render'
import { getRank } from '../api/user'

const router = useRouter()
const maps = MAPS
const skins = SKINS
const picked = ref(loadMapId())
const skinId = ref(getSkin(loadSkinId()).id)
const map = computed(() => getMap(picked.value))
const skin = computed(() => getSkin(skinId.value))
const user = ref(sessionStorage.getItem('snake_user') || '')
const rankList = ref([])
const rankMsg = ref('')
const topScore = ref(0)

/* 缩略图：地图卡跟着所选皮肤画，皮肤卡跟着所选地图画，都是同一套绘制函数 */
const mapThumbs = {}
const skinThumbs = {}
function setThumb(id, el) {
  if (el) mapThumbs[id] = el
}
function setSkinThumb(id, el) {
  if (el) skinThumbs[id] = el
}

function paintMapThumbs() {
  for (const m of MAPS) {
    const cv = mapThumbs[m.id]
    if (cv) paintPreview(cv.getContext('2d'), resolveTheme(m, skin.value), 160, GRID)
  }
}

function paintSkinThumbs() {
  for (const s of SKINS) {
    const cv = skinThumbs[s.id]
    if (cv) paintPreview(cv.getContext('2d'), resolveTheme(map.value, s), 150, GRID)
  }
}

/** 卡片描边色：特设皮肤用自己的主色，基础皮肤用地图主色 */
function skinAccent(s) {
  return (s.palette || map.value.theme).border
}
function skinGlow(s) {
  return (s.palette || map.value.theme).glow
}

function pick(id) {
  picked.value = id
  saveMapId(id)
  // 地图换了，地图卡和皮肤卡都要重画
  paintMapThumbs()
  paintSkinThumbs()
}

function pickSkin(id) {
  skinId.value = id
  saveSkinId(id)
  // 皮肤换了，地图卡跟着变（皮肤卡本身只高亮，不用重画）
  paintMapThumbs()
}

/** 开始游戏：未登录先去登录页（地图通过 ?map= 带过去，登录后自动进入） */
function startGame(id) {
  const mid = id || picked.value
  pick(mid)
  if (!user.value) {
    router.push({ path: '/login', query: { map: mid } })
    return
  }
  router.push({ path: '/game', query: { map: mid } })
}

function to(id) {
  const el = document.getElementById(id)
  if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' })
}

function logout() {
  sessionStorage.removeItem('snake_user')
  sessionStorage.removeItem('snake_uid')
  sessionStorage.removeItem('snake_best')
  user.value = ''
}

onMounted(async () => {
  await nextTick()
  paintMapThumbs()
  paintSkinThumbs()

  const res = await getRank(5)
  if (res.code === 200) {
    rankList.value = res.data || []
    topScore.value = rankList.value.length ? rankList.value[0].score : 0
    rankMsg.value = rankList.value.length ? '' : '还没有任何记录，快去当第一个上榜的人'
  } else {
    rankMsg.value = `${res.msg || '排行榜加载失败'}`
  }
})
</script>

<style scoped>
.home {
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

/* ---------------- 顶部导航 ---------------- */
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

.btn:hover {
  background: #facc15;
  border-color: #facc15;
  box-shadow: 0 0 16px rgba(250, 204, 21, 0.7);
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

.btn.lg {
  padding: 13px 34px;
  font-size: 15px;
  letter-spacing: 3px;
}

/* ---------------- Hero ---------------- */
.wrap {
  position: relative;
  z-index: 10;
  max-width: 1080px;
  margin: 0 auto;
  padding: 34px 28px 60px;
}

.hero {
  text-align: center;
  padding: 26px 0 58px;
}

.badge {
  display: inline-block;
  font-size: 11px;
  letter-spacing: 2px;
  color: #a3e635;
  border: 1px solid #166534;
  padding: 5px 14px;
  margin-bottom: 24px;
}

.hero h1 {
  font-size: 54px;
  letter-spacing: 16px;
  padding-left: 16px;
  text-shadow: 0 0 26px rgba(74, 222, 128, 0.55);
}

.hero-en {
  color: #14532d;
  font-size: 13px;
  letter-spacing: 6px;
  margin-top: 12px;
}

.hero-desc {
  color: #a3e635;
  font-size: 14px;
  line-height: 2;
  margin: 24px auto 0;
  max-width: 560px;
  opacity: 0.85;
}

.hero-actions {
  display: flex;
  gap: 16px;
  justify-content: center;
  margin-top: 30px;
}

.stats {
  display: flex;
  justify-content: center;
  gap: 46px;
  margin-top: 48px;
}

.stat b {
  display: block;
  font-size: 28px;
  color: #facc15;
  text-shadow: 0 0 14px rgba(250, 204, 21, 0.45);
}

.stat span {
  display: block;
  margin-top: 6px;
  font-size: 11px;
  letter-spacing: 2px;
  color: #14532d;
}

/* ---------------- 区块标题 ---------------- */
.sec {
  margin-bottom: 72px;
  scroll-margin-top: 78px;
}

.sec-head {
  display: flex;
  align-items: baseline;
  gap: 16px;
  margin-bottom: 26px;
  border-left: 4px solid #4ade80;
  padding-left: 14px;
}

.sec-head h2 {
  font-size: 22px;
  letter-spacing: 5px;
  text-shadow: 0 0 10px rgba(74, 222, 128, 0.5);
}

.sec-head span {
  font-size: 11px;
  letter-spacing: 2px;
  color: #14532d;
}

/* ---------------- 地图卡片 ---------------- */
.map-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 22px;
}

.card {
  --c: #4ade80;
  --g: rgba(74, 222, 128, 0.35);
  position: relative;
  display: flex;
  flex-direction: column;
  padding: 16px 16px 20px;
  background: rgba(7, 19, 10, 0.9);
  border: 2px solid #166534;
  cursor: pointer;
  transition: transform 0.18s, border-color 0.18s, box-shadow 0.18s;
}

.card:hover {
  transform: translateY(-4px);
  border-color: var(--c);
  box-shadow: 0 0 24px var(--g);
}

.card.on {
  border-color: var(--c);
  box-shadow: 0 0 26px var(--g);
}

.thumb {
  position: relative;
  border: 2px solid #14532d;
  background: #07130a;
  line-height: 0;
}

.card.on .thumb {
  border-color: var(--c);
}

.thumb canvas {
  display: block;
  width: 100%;
  height: auto;
}

.badge-pick {
  position: absolute;
  top: 8px;
  right: 8px;
  padding: 2px 9px;
  font-size: 11px;
  font-weight: bold;
  letter-spacing: 1px;
  line-height: 1.7;
  color: #07130a;
  background: var(--c);
}

.card h3 {
  margin-top: 16px;
  font-size: 17px;
  letter-spacing: 3px;
  color: var(--c);
}

.card h3 em {
  display: block;
  margin-top: 5px;
  font-style: normal;
  font-size: 10px;
  letter-spacing: 2px;
  color: #14532d;
}

.card .desc {
  flex: 1;
  margin: 12px 0;
  font-size: 12.5px;
  line-height: 1.9;
  color: #4ade80;
  opacity: 0.8;
}

.chips {
  display: flex;
  flex-wrap: wrap;
  gap: 7px;
  margin-bottom: 12px;
}

.chips span {
  font-size: 11px;
  letter-spacing: 1px;
  color: #a3e635;
  border: 1px solid #166534;
  padding: 2px 8px;
}

.rule {
  margin-bottom: 14px;
  font-size: 11.5px;
  letter-spacing: 1px;
  color: var(--c);
  opacity: 0.9;
}

.card-btn {
  width: 100%;
}

/* ---------------- 皮肤卡 ---------------- */
.skins-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(190px, 1fr));
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
  width: 150px;
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

.skin-card h3 {
  margin-top: 12px;
  font-size: 14px;
  letter-spacing: 2px;
  color: var(--c);
  text-align: center;
}

.skin-card h3 em {
  display: block;
  margin-top: 4px;
  font-style: normal;
  font-size: 9.5px;
  letter-spacing: 1.5px;
  color: #14532d;
}

.skin-card .desc {
  flex: 1;
  margin: 10px 0;
  font-size: 11.5px;
  line-height: 1.85;
  color: #4ade80;
  opacity: 0.8;
}

.skin-card .chips {
  justify-content: center;
}

.skin-note {
  margin-top: 18px;
  padding: 12px 16px;
  font-size: 12px;
  line-height: 2;
  letter-spacing: 0.5px;
  color: #4ade80;
  background: rgba(74, 222, 128, 0.06);
  border-left: 3px solid #166534;
}

.skin-note b {
  color: #facc15;
  font-weight: normal;
}

/* ---------------- 玩法 ---------------- */
.how-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
  gap: 22px;
}

.how-card {
  padding: 20px 22px;
  background: rgba(7, 19, 10, 0.88);
  border: 2px solid #14532d;
}

.how-card h4 {
  margin-bottom: 14px;
  font-size: 14px;
  letter-spacing: 3px;
  color: #facc15;
}

.how-card ul {
  list-style: none;
}

.how-card li {
  position: relative;
  padding-left: 14px;
  font-size: 12.5px;
  line-height: 2.1;
  color: #4ade80;
}

.how-card li::before {
  content: '▸';
  position: absolute;
  left: 0;
  color: #166534;
}

kbd {
  display: inline-block;
  margin: 0 1px;
  padding: 1px 6px;
  font-family: inherit;
  font-size: 11px;
  color: #a3e635;
  background: #0b1a0f;
  border: 1px solid #166534;
}

/* ---------------- 排行榜 ---------------- */
.rank-card {
  max-width: 560px;
  padding: 22px 26px;
  background: rgba(7, 19, 10, 0.9);
  border: 2px solid #166534;
}

.rank-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
}

.rank-table th {
  padding: 8px 6px;
  text-align: left;
  font-size: 11px;
  letter-spacing: 2px;
  color: #a3e635;
  border-bottom: 2px solid #166534;
}

.rank-table th:last-child,
.rank-table td:last-child {
  text-align: right;
}

.rank-table td {
  padding: 9px 6px;
  color: #4ade80;
  border-bottom: 1px solid #14532d;
}

.rank-table td.no {
  width: 60px;
  color: #14532d;
}

.rank-table td.sc {
  color: #facc15;
}

.rank-table tr.me td {
  background: rgba(74, 222, 128, 0.12);
}

.rank-msg {
  padding: 16px 0;
  font-size: 13px;
  color: #a3e635;
}

.rank-foot {
  margin-top: 16px;
  font-size: 11px;
  letter-spacing: 1px;
  color: #14532d;
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

@media (max-width: 720px) {
  .nav-links {
    display: none;
  }

  .hero h1 {
    font-size: 36px;
    letter-spacing: 10px;
    padding-left: 10px;
  }

  .stats {
    gap: 28px;
  }

  .wrap {
    padding: 20px 18px 40px;
  }
}
</style>
