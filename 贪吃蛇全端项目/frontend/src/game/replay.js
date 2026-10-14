/**
 * 回放轨迹：录制 → 编码 → 解码 → 按步重建
 * ==================================================================
 * 「回放」要能像放录像一样重演一局，就得把**蛇怎么走的**记下来。
 * 但整条蛇每帧都存太浪费，这里用的是最省的一套：
 *
 *   1. 初始蛇身 snake0（尾→头共 3 格，只有开局那一次）
 *   2. 之后每一步的**蛇头位置** heads（蛇身是"头走过的路径"，不必重复存）
 *   3. 食物出现顺序 foods（开局那个 + 每吃掉一个后新生成的）
 *
 * 有了这三样就能完整重建：第 s 步的蛇 = 路径末尾 lenAt[s] 个格子；
 * 第 s 步的食物 = 第 foodAt[s] 个。
 * lenAt / foodAt 在解码时一趟 O(n) 预计算好，播放时直接查表。
 *
 * 编码成字符串时用 "x,y;x,y" 这种紧凑写法，比 JSON 数组省一半以上：
 * 一局 3000 步大约 20KB，放数据库里毫无压力。
 * ==================================================================
 */

/** 轨迹格式版本，将来改结构靠它做兼容 */
export const TRACK_VERSION = 1

/** 最多录多少步（约 1 小时的高速局，够用了）；超了就不再录，避免极端情况下撑爆请求体 */
export const MAX_RECORD_STEPS = 50000

/* ------------------------------ 录制 ------------------------------ */

/**
 * 录制器：游戏里每次移动调一次 push，结束时调 build()
 *
 * 用法（Game.vue 里就是这么用的）：
 *   const rec = createRecorder({ grid, mapId, skinId, snake, food, stepMs })
 *   rec.push(head, food)   // 每一步
 *   const track = rec.build()
 */
export function createRecorder({ grid = 20, mapId, skinId, snake, food, stepMs = 150 }) {
  // 初始蛇身要拷一份快照：游戏里 snake 数组会被反复 unshift/pop 改动
  const snake0 = snake.map((p) => [p.x, p.y])
  const heads = []
  const foods = food ? [[food.x, food.y]] : []
  let overflow = false

  return {
    /** 记录一步：head 是这一步蛇头到达的格子；food 是"这一步之后"的食物位置 */
    push(head, food) {
      if (heads.length >= MAX_RECORD_STEPS) {
        overflow = true
        return
      }
      heads.push([head.x, head.y])
      // 吃到食物时调用方会传入新生成的食物（没吃就传同一个，判断一下去重）
      if (food) {
        const last = foods[foods.length - 1]
        if (!last || last[0] !== food.x || last[1] !== food.y) {
          foods.push([food.x, food.y])
        }
      }
    },
    /** 收工，产出可以直接存库的轨迹对象；一步都没走就返回 null */
    build() {
      if (!heads.length) return null
      return {
        v: TRACK_VERSION,
        grid,
        mapId,
        skinId,
        snake0: pointsToStr(snake0),
        heads: pointsToStr(heads),
        foods: pointsToStr(foods),
        steps: heads.length,
        stepMs,
        overflow
      }
    }
  }
}

/* ------------------------------ 编码 ------------------------------ */

/** 轨迹对象 → 存库用的字符串（其实是 JSON，只是里面的大数组都压成了字符串） */
export function encodeTrack(track) {
  if (!track) return ''
  return JSON.stringify({
    v: track.v || TRACK_VERSION,
    grid: track.grid || 20,
    mapId: track.mapId || '',
    skinId: track.skinId || '',
    snake0: pointsToStr(track.snake0 || []),
    heads: pointsToStr(track.heads || []),
    foods: pointsToStr(track.foods || []),
    steps: track.steps || (track.heads ? track.heads.length : 0),
    stepMs: track.stepMs || 150,
    overflow: !!track.overflow
  })
}

/* ------------------------------ 解码 ------------------------------ */

/**
 * 存库字符串 → 可播放的轨迹
 * 返回的对象多带了三个"查表用"的预计算结果：path / lenAt / foodAt
 */
export function decodeTrack(raw) {
  if (!raw) return null
  let o = raw
  if (typeof raw === 'string') {
    try {
      o = JSON.parse(raw)
    } catch (e) {
      return null
    }
  }
  if (!o || !o.snake0 || !o.heads) return null

  const snake0 = strToPoints(o.snake0)
  const heads = strToPoints(o.heads)
  const foods = strToPoints(o.foods)
  if (snake0.length < 2 || !heads.length) return null

  const length0 = snake0.length
  // 路径：尾 → 头（初始蛇身反过来，再按步把蛇头走过的格子接上）
  const path = []
  for (let i = length0 - 1; i >= 0; i--) path.push(snake0[i])
  for (let i = 0; i < heads.length; i++) path.push(heads[i])

  const steps = heads.length
  const lenAt = new Array(steps + 1)
  const foodAt = new Array(steps + 1)
  lenAt[0] = length0
  foodAt[0] = 0

  let eaten = 0
  let len = length0
  for (let s = 1; s <= steps; s++) {
    const h = heads[s - 1]
    const next = foods[eaten]
    // 蛇头正好踩在"当前该出现的食物"上 = 这一步吃到了，蛇变长
    if (next && next[0] === h[0] && next[1] === h[1]) {
      eaten++
      len++
    }
    lenAt[s] = len
    foodAt[s] = eaten
  }

  return {
    v: o.v || TRACK_VERSION,
    grid: o.grid || 20,
    mapId: o.mapId || '',
    skinId: o.skinId || '',
    stepMs: o.stepMs || 150,
    overflow: !!o.overflow,
    steps,
    length0,
    foods,
    path,
    lenAt,
    foodAt
  }
}

/**
 * 取第 s 步的画面状态（s=0 是开局那一刻，s=steps 是最后一帧）
 * @returns {{snake: Array<{x:number,y:number}>, dir: {x:number,y:number}, food: {x:number,y:number}|null}}
 */
export function stateAt(tr, s) {
  if (!tr) return null
  const step = Math.max(0, Math.min(Math.floor(s), tr.steps))
  const end = tr.length0 + step        // path 里"当前蛇头"的位置（不含）
  const len = tr.lenAt[step]
  const start = Math.max(0, end - len)

  // 从蛇头往蛇尾取，正好是绘制层要的顺序（头在前）
  const snake = []
  for (let i = end - 1; i >= start; i--) {
    const p = tr.path[i]
    snake.push({ x: p[0], y: p[1] })
  }

  // 方向由路径最后两格推出来；穿墙时坐标会突变，夹回单位方向
  const b = tr.path[end - 1] || tr.path[0]
  const a = tr.path[end - 2] || b
  let dx = b[0] - a[0]
  let dy = b[1] - a[1]
  if (dx > 1) dx = -1
  else if (dx < -1) dx = 1
  if (dy > 1) dy = -1
  else if (dy < -1) dy = 1
  if (!dx && !dy) dx = 1

  const f = tr.foods[tr.foodAt[step]]
  return {
    snake,
    dir: { x: dx, y: dy },
    food: f ? { x: f[0], y: f[1] } : null
  }
}

/* --------------------------- 演示用轨迹 --------------------------- */
/**
 * 造一段"看起来在玩"的轨迹，给皮肤预览当活演示：
 * 让蛇沿棋盘内圈的一个矩形环一直绕，每隔几格吃一个食物，
 * 所以预览里蛇会越绕越长，能直观看出这款皮肤的蛇身造型和食物造型。
 *
 * 环的位置会避开当前地图的障碍（霓虹赛博那张有墙），
 * 所以预览出来的效果和真在这张地图上玩是一致的。
 */
export function buildDemoTrack(map, skin, laps = 2) {
  const grid = 20
  const walls = new Set()
  const rules = (map && map.rules) || {}
  for (const r of rules.walls || []) {
    for (let x = r.x; x < r.x + r.w; x++) {
      for (let y = r.y; y < r.y + r.h; y++) walls.add(x + ',' + y)
    }
  }

  // 从外到内挑第一个不压障碍的矩形环
  const candidates = [
    [5, 5, 14, 14],
    [4, 4, 15, 15],
    [6, 6, 13, 13],
    [3, 3, 16, 16],
    [7, 7, 12, 12],
    [2, 2, 17, 17]
  ]
  let ring = null
  for (const [x0, y0, x1, y1] of candidates) {
    const pts = ringPath(x0, y0, x1, y1)
    if (pts.length >= 12 && pts.every(([x, y]) => !walls.has(x + ',' + y))) {
      ring = pts
      break
    }
  }
  if (!ring) ring = ringPath(5, 5, 14, 14)

  const L = ring.length
  const steps = L * laps
  const snake0 = [ring[2], ring[1], ring[0]]   // 头在 ring[2]，尾往后数
  const headIdx = (s) => (2 + s) % L           // 第 s 步（从 0 开始）蛇头在环上的位置

  const heads = []
  for (let i = 0; i < steps; i++) heads.push(ring[(3 + i) % L])

  // 每 6 步喂一个食物：正好放在那一刻蛇头要到达的格子上
  const foods = []
  for (let s = 5; s < steps; s += 6) foods.push(headIdx(s))

  return {
    v: TRACK_VERSION,
    grid,
    mapId: (map && map.id) || '',
    skinId: (skin && skin.id) || '',
    // 演示轨迹留在内存里直接用，不落库，所以这里直接给数组、不需要压缩
    snake0,
    heads,
    foods,
    steps,
    stepMs: 130,
    demo: true
  }
}

/* ------------------------------ 小工具 ------------------------------ */

/** 一圈矩形环（顺时针，格子两两相邻），例如 5,5 → 14,14 得到 36 格 */
function ringPath(x0, y0, x1, y1) {
  const pts = []
  for (let x = x0; x <= x1; x++) pts.push([x, y0])
  for (let y = y0 + 1; y <= y1; y++) pts.push([x1, y])
  for (let x = x1 - 1; x >= x0; x--) pts.push([x, y1])
  for (let y = y1 - 1; y > y0; y--) pts.push([x0, y])
  return pts
}

/**
 * [{x,y}] 或 [[x,y]] 或已经是 "x,y;x,y" → "x,y;x,y"
 *
 * 必须幂等：`createRecorder().build()` 交出来的轨迹里这三个字段已经是字符串了，
 * 而 `buildDemoTrack()` 交出来的是数组，`encodeTrack()` 两种都会收到。
 * 少了开头这个字符串短路判断，就会按字符逐字编码，产出满屏 "undefined,undefined"
 * —— 轨迹存进去看着有几千字符，解码时却直接失败（这是踩过的真坑）。
 */
function pointsToStr(arr) {
  if (typeof arr === 'string') return arr
  const out = []
  for (const p of arr) {
    if (!p) continue
    if (Array.isArray(p)) out.push(p[0] + ',' + p[1])
    else out.push(p.x + ',' + p.y)
  }
  return out.join(';')
}

/** "x,y;x,y" → [[x,y]]；也接受已经是数组的输入（演示轨迹就是数组） */
function strToPoints(str) {
  const out = []
  if (!str) return out
  if (Array.isArray(str)) {
    for (const p of str) {
      if (!p) continue
      if (Array.isArray(p)) out.push([p[0], p[1]])
      else out.push([p.x, p.y])
    }
    return out
  }
  for (const seg of String(str).split(';')) {
    if (!seg) continue
    const i = seg.indexOf(',')
    if (i < 0) continue
    const x = parseInt(seg.slice(0, i), 10)
    const y = parseInt(seg.slice(i + 1), 10)
    if (Number.isFinite(x) && Number.isFinite(y)) out.push([x, y])
  }
  return out
}
