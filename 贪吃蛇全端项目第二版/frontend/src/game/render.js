/**
 * 绘制层（游戏页棋盘 / 首页缩略图共用）
 * ------------------------------------------------------------------
 * 这里只认一个 view 对象：
 *   view.palette      整套配色
 *   view.pattern      底板图案：grid / dots / scan / stars / frost / circuit / petal / none
 *   view.snakeStyle   蛇身造型：solid / rainbow / gradient / outline / pixel / glass / ghost
 *   view.foodStyle    食物造型：square / circle / star / diamond / crystal / coin / petal / pixel
 *   view.map          原始地图对象（只用到 rules.walls / rules.wrap）
 *
 * view 由 skins.js 的 resolveTheme(map, skin) 合成。
 * 本文件不 import 任何模块，保证没有循环依赖。
 * ------------------------------------------------------------------
 */

/** 圆角矩形路径（不依赖 ctx.roundRect，兼容性好） */
export function roundRectPath(ctx, x, y, w, h, r) {
  const rr = Math.max(0, Math.min(r, w / 2, h / 2))
  ctx.beginPath()
  ctx.moveTo(x + rr, y)
  ctx.arcTo(x + w, y, x + w, y + h, rr)
  ctx.arcTo(x + w, y + h, x, y + h, rr)
  ctx.arcTo(x, y + h, x, y, rr)
  ctx.arcTo(x, y, x + w, y, rr)
  ctx.closePath()
}

/** 圆角矩形填充 */
export function roundRect(ctx, x, y, w, h, r) {
  roundRectPath(ctx, x, y, w, h, r)
  ctx.fill()
}

/** n 角星路径 */
function starPath(ctx, cx, cy, outer, inner, n) {
  ctx.beginPath()
  for (let i = 0; i < n * 2; i++) {
    const r = i % 2 === 0 ? outer : inner
    const a = (Math.PI / n) * i - Math.PI / 2
    const x = cx + Math.cos(a) * r
    const y = cy + Math.sin(a) * r
    i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y)
  }
  ctx.closePath()
}

/** n 边形路径 */
function polygonPath(ctx, cx, cy, r, n, rot = -Math.PI / 2) {
  ctx.beginPath()
  for (let i = 0; i < n; i++) {
    const a = rot + (Math.PI * 2 * i) / n
    const x = cx + Math.cos(a) * r
    const y = cy + Math.sin(a) * r
    i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y)
  }
  ctx.closePath()
}

/* ---------------- 颜色 ---------------- */
function hexToRgb(hex) {
  const h = hex.replace('#', '')
  const v = h.length === 3 ? h.split('').map((c) => c + c).join('') : h
  return [parseInt(v.slice(0, 2), 16), parseInt(v.slice(2, 4), 16), parseInt(v.slice(4, 6), 16)]
}

/** 两个 hex 颜色之间插值（t=0 取 a，t=1 取 b） */
export function lerpColor(a, b, t) {
  const [r1, g1, b1] = hexToRgb(a)
  const [r2, g2, b2] = hexToRgb(b)
  const k = Math.max(0, Math.min(1, t))
  const to = (x, y) => Math.round(x + (y - x) * k)
  return `rgb(${to(r1, r2)},${to(g1, g2)},${to(b1, b2)})`
}

/* ---------------- 底板图案 ---------------- */
// 星星 / 花瓣这类随机点缀必须是"确定性"的，否则每帧重绘都会闪；
// 所以用固定种子的伪随机生成一次后缓存起来。
const patternCache = new Map()

function seededPoints(pattern, size, count) {
  const key = `${pattern}|${size}|${count}`
  if (patternCache.has(key)) return patternCache.get(key)
  let seed = 20261012
  const rnd = () => {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff
    return seed / 0x7fffffff
  }
  const pts = []
  for (let i = 0; i < count; i++) {
    pts.push({ x: rnd() * size, y: rnd() * size, r: 0.7 + rnd() * 1.8, a: 0.3 + rnd() * 0.7 })
  }
  patternCache.set(key, pts)
  return pts
}

function strokeGrid(ctx, size, grid, color) {
  const cell = size / grid
  ctx.strokeStyle = color
  ctx.lineWidth = 1
  ctx.beginPath()
  for (let i = 1; i < grid; i++) {
    const p = Math.round(i * cell) + 0.5
    ctx.moveTo(p, 0)
    ctx.lineTo(p, size)
    ctx.moveTo(0, p)
    ctx.lineTo(size, p)
  }
  ctx.stroke()
}

function drawPattern(ctx, view, size, grid) {
  const p = view.palette
  const cell = size / grid
  ctx.save()

  switch (view.pattern) {
    case 'dots': {
      strokeGrid(ctx, size, grid, p.grid)
      ctx.fillStyle = p.accent
      ctx.globalAlpha = 0.2
      for (let i = 1; i < grid; i++) {
        for (let j = 1; j < grid; j++) {
          ctx.fillRect(i * cell - 1, j * cell - 1, 2, 2)
        }
      }
      break
    }
    case 'scan': {
      ctx.fillStyle = p.grid
      for (let y = 0; y < size; y += 3) ctx.fillRect(0, y, size, 1)
      break
    }
    case 'stars': {
      ctx.fillStyle = p.accent
      for (const q of seededPoints('stars', size, 110)) {
        ctx.globalAlpha = q.a * 0.45
        ctx.beginPath()
        ctx.arc(q.x, q.y, q.r * 0.8, 0, Math.PI * 2)
        ctx.fill()
      }
      ctx.fillStyle = '#ffffff'
      for (const q of seededPoints('stars-big', size, 7)) {
        ctx.globalAlpha = 0.45
        starPath(ctx, q.x, q.y, q.r + 2.5, (q.r + 2.5) * 0.4, 4)
        ctx.fill()
      }
      break
    }
    case 'frost': {
      ctx.strokeStyle = p.grid
      ctx.lineWidth = 1
      for (let i = -grid; i < grid * 2; i++) {
        const o = i * cell
        ctx.beginPath()
        ctx.moveTo(o, 0)
        ctx.lineTo(o + size, size)
        ctx.stroke()
        ctx.beginPath()
        ctx.moveTo(o + size, 0)
        ctx.lineTo(o, size)
        ctx.stroke()
      }
      break
    }
    case 'circuit': {
      strokeGrid(ctx, size, grid, p.grid)
      ctx.strokeStyle = p.accent
      ctx.globalAlpha = 0.16
      ctx.lineWidth = 1
      for (let i = 2; i < grid; i += 4) {
        ctx.beginPath()
        ctx.moveTo(i * cell, 2 * cell)
        ctx.lineTo(i * cell, (grid - 2) * cell)
        ctx.stroke()
      }
      ctx.globalAlpha = 0.3
      ctx.fillStyle = p.accent
      for (let i = 2; i < grid; i += 4) {
        for (let j = 2; j < grid; j += 4) {
          ctx.fillRect(i * cell - 1.5, j * cell - 1.5, 3, 3)
        }
      }
      break
    }
    case 'petal': {
      ctx.fillStyle = p.accent
      for (const q of seededPoints('petal', size, 30)) {
        ctx.globalAlpha = 0.09 + q.a * 0.09
        ctx.save()
        ctx.translate(q.x, q.y)
        ctx.rotate(q.r * 2)
        ctx.beginPath()
        ctx.ellipse(0, 0, q.r + 2.5, (q.r + 2.5) * 0.42, 0, 0, Math.PI * 2)
        ctx.fill()
        ctx.restore()
      }
      break
    }
    case 'none':
      break
    case 'grid':
    default:
      strokeGrid(ctx, size, grid, p.grid)
      break
  }

  ctx.restore()
}

/* ---------------- 棋盘 ---------------- */
/**
 * 画静态底板：底色 + 图案 + 障碍 + 可穿越边界
 * @param {CanvasRenderingContext2D} ctx
 * @param {object} view  resolveTheme() 的结果
 * @param {number} size  画布边长（px）
 * @param {number} grid  格数
 */
export function paintBoard(ctx, view, size, grid) {
  const p = view.palette
  const cell = size / grid

  ctx.clearRect(0, 0, size, size)
  ctx.fillStyle = p.boardBg
  ctx.fillRect(0, 0, size, size)

  drawPattern(ctx, view, size, grid)

  // 障碍块
  for (const r of view.map.rules.walls) {
    const x = Math.round(r.x * cell) + 1
    const y = Math.round(r.y * cell) + 1
    const w = Math.round(r.w * cell) - 2
    const h = Math.round(r.h * cell) - 2
    ctx.fillStyle = p.wall
    ctx.fillRect(x, y, w, h)
    ctx.strokeStyle = p.wallEdge
    ctx.lineWidth = 1
    ctx.strokeRect(x + 0.5, y + 0.5, w - 1, h - 1)
  }

  // 可穿越边界：虚线内框
  if (view.map.rules.wrap) {
    ctx.save()
    ctx.setLineDash([6, 6])
    ctx.strokeStyle = p.accent
    ctx.lineWidth = 2
    ctx.strokeRect(4, 4, size - 8, size - 8)
    ctx.restore()
  }
}

/* ---------------- 食物 ---------------- */
export function drawFood(ctx, view, food, cell) {
  const p = view.palette
  const style = view.foodStyle
  const cx = food.x * cell + cell / 2
  const cy = food.y * cell + cell / 2
  const r = cell / 2 - 3

  ctx.save()
  ctx.fillStyle = p.food
  ctx.strokeStyle = p.food
  ctx.shadowColor = p.food
  ctx.shadowBlur = 10

  switch (style) {
    case 'circle':
      ctx.beginPath()
      ctx.arc(cx, cy, r, 0, Math.PI * 2)
      ctx.fill()
      break
    case 'star':
      starPath(ctx, cx, cy, r + 1, (r + 1) * 0.45, 5)
      ctx.fill()
      break
    case 'diamond':
      polygonPath(ctx, cx, cy, r + 1, 4)
      ctx.fill()
      break
    case 'crystal':
      polygonPath(ctx, cx, cy, r + 1, 6)
      ctx.fill()
      ctx.shadowBlur = 0
      ctx.globalAlpha = 0.55
      ctx.strokeStyle = '#ffffff'
      ctx.lineWidth = 1
      ctx.beginPath()
      ctx.moveTo(cx, cy - r)
      ctx.lineTo(cx, cy + r)
      ctx.stroke()
      ctx.globalAlpha = 1
      break
    case 'coin':
      ctx.beginPath()
      ctx.arc(cx, cy, r, 0, Math.PI * 2)
      ctx.fill()
      ctx.shadowBlur = 0
      ctx.globalAlpha = 0.75
      ctx.strokeStyle = p.boardBg
      ctx.lineWidth = 2
      ctx.beginPath()
      ctx.arc(cx, cy, r * 0.55, 0, Math.PI * 2)
      ctx.stroke()
      ctx.globalAlpha = 1
      break
    case 'petal': {
      ctx.save()
      ctx.translate(cx, cy)
      ctx.rotate(-0.5)
      ctx.beginPath()
      ctx.ellipse(0, 0, r * 1.05, r * 0.62, 0, 0, Math.PI * 2)
      ctx.fill()
      ctx.restore()
      break
    }
    case 'pixel': {
      ctx.shadowBlur = 0
      const s = Math.round(cell * 0.3)
      const x = Math.round(cx - s / 2)
      const y = Math.round(cy - s / 2)
      ctx.fillRect(x, y, s, s)
      ctx.globalAlpha = 0.55
      ctx.fillRect(x - s + 2, y, s - 3, s - 3)
      ctx.fillRect(x + s - 2, y, s - 3, s - 3)
      ctx.globalAlpha = 1
      break
    }
    case 'square':
    default:
      roundRect(ctx, food.x * cell + 3, food.y * cell + 3, cell - 6, cell - 6, 5)
      break
  }

  ctx.restore()
}

/* ---------------- 蛇 ---------------- */
function drawEyes(ctx, view, head, dir, cell, square) {
  const p = view.palette
  const ex = head.x * cell + cell / 2
  const ey = head.y * cell + cell / 2
  const off = 4
  const s = square ? 4 : 3
  ctx.fillStyle = p.eye
  const put = (x, y) => ctx.fillRect(Math.round(x), Math.round(y), s, s)
  if (dir.x === 1) { put(ex + 2, ey - off); put(ex + 2, ey + off - s) }
  else if (dir.x === -1) { put(ex - 2 - s, ey - off); put(ex - 2 - s, ey + off - s) }
  else if (dir.y === -1) { put(ex - off, ey - 2 - s); put(ex + off - s, ey - 2 - s) }
  else { put(ex - off, ey + 2); put(ex + off - s, ey + 2) }
}

/**
 * 画整条蛇（从尾到头）
 * @param {number} frame 帧计数，供彩虹皮肤流动用
 */
export function drawSnake(ctx, view, snake, dir, cell, frame = 0) {
  const p = view.palette
  const style = view.snakeStyle
  const n = snake.length

  ctx.save()
  for (let i = n - 1; i >= 0; i--) {
    const s = snake[i]
    const isHead = i === 0
    const x = s.x * cell + 1
    const y = s.y * cell + 1
    const w = cell - 2
    const h = cell - 2
    const radius = isHead ? 7 : 5

    let color = isHead ? p.snakeHead : p.snakeBody
    if (style === 'rainbow') {
      const hue = (i * 15 + frame * 5) % 360
      color = `hsl(${hue}, 88%, ${isHead ? 74 : 60}%)`
    } else if (style === 'gradient') {
      color = lerpColor(p.snakeHead, p.snakeBody, n === 1 ? 0 : i / (n - 1))
    } else if (style === 'ghost') {
      ctx.globalAlpha = isHead ? 0.9 : 0.52
    }

    if (style === 'outline') {
      ctx.strokeStyle = color
      ctx.lineWidth = 2
      ctx.shadowColor = isHead ? color : 'transparent'
      ctx.shadowBlur = isHead ? 10 : 0
      roundRectPath(ctx, x + 1.5, y + 1.5, w - 3, h - 3, isHead ? 6 : 4)
      ctx.stroke()
      ctx.shadowBlur = 0
    } else if (style === 'pixel') {
      ctx.fillStyle = color
      ctx.shadowColor = isHead ? color : 'transparent'
      ctx.shadowBlur = isHead ? 8 : 0
      ctx.fillRect(Math.round(x), Math.round(y), w, h)
      ctx.shadowBlur = 0
      // 像素高光
      const keep = ctx.globalAlpha
      ctx.globalAlpha = keep * 0.35
      ctx.fillStyle = '#ffffff'
      ctx.fillRect(Math.round(x) + 2, Math.round(y) + 2, 3, 3)
      ctx.globalAlpha = keep
    } else {
      ctx.fillStyle = color
      ctx.shadowColor = isHead ? p.snakeHead : 'transparent'
      ctx.shadowBlur = isHead ? 12 : 0
      roundRect(ctx, x, y, w, h, radius)
      ctx.shadowBlur = 0
      if (style === 'glass') {
        ctx.globalAlpha = 0.4
        ctx.fillStyle = '#ffffff'
        roundRect(ctx, x + 2, y + 2, w - 4, Math.max(2, h * 0.26), 2)
        ctx.globalAlpha = 1
      }
    }
  }
  ctx.globalAlpha = 1
  drawEyes(ctx, view, snake[0], dir, cell, style === 'pixel')
  ctx.restore()
}

/* ---------------- 缩略图 ---------------- */
// 首页卡片用的示例蛇：一条 L 形，头在 (8,12)，不会压到任何地图的障碍
const SAMPLE_SNAKE = [[8, 12], [7, 12], [6, 12], [6, 11], [6, 10], [5, 10]]
const SAMPLE_FOOD = { x: 14, y: 5 }

/** 首页卡片缩略图：底板 + 示例蛇 + 示例食物 */
export function paintPreview(ctx, view, size, grid) {
  const cell = size / grid
  paintBoard(ctx, view, size, grid)
  drawFood(ctx, view, SAMPLE_FOOD, cell)
  drawSnake(
    ctx,
    view,
    SAMPLE_SNAKE.map(([x, y]) => ({ x, y })),
    { x: 1, y: 0 },
    cell,
    8
  )
}
