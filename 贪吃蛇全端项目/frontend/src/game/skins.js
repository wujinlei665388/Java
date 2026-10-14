/**
 * 皮肤配置（1 款基础纯色 + 10 款特设）
 * ------------------------------------------------------------------
 * 设计原则：**地图管机制，皮肤管外观**
 *   - 地图（maps.js）：障碍布局、能否穿越边界、速度、每个食物多少分
 *   - 皮肤（本文件）：整套配色 + 底板图案 + 蛇身造型 + 食物造型
 *
 * 所以任何皮肤都能配任何地图，换肤不影响玩法，也不会清掉当前这一局。
 *
 * 字段说明：
 *   id / name / en / desc / tags   展示用
 *   palette        整套配色，会覆盖地图自带的 theme
 *                  （boardBg 棋盘底 / grid 图案色 / border 边框 / glow 辉光
 *                    text 主文字 / muted 次要文字 / pageBg 页面底色
 *                    snakeBody 蛇身 / snakeHead 蛇头 / eye 眼睛 / food 食物
 *                    wall 障碍填充 / wallEdge 障碍描边 / accent 强调色）
 *   pattern        底板图案：grid | dots | scan | stars | frost | circuit | petal | none
 *   snakeStyle     蛇身造型：solid | rainbow | gradient | outline | pixel | glass | ghost
 *   foodStyle      食物造型：square | circle | star | diamond | crystal | coin | petal | pixel
 * ------------------------------------------------------------------
 */

export const SKINS = [
  {
    id: 'plain',
    name: '纯色基础',
    en: 'PLAIN · FOLLOW MAP',
    desc: '最原始的一套。不覆盖任何颜色，完全跟随你选的地图配色。',
    tags: ['基础', '跟随地图'],
    palette: null, // null = 用地图自带的 theme
    pattern: 'grid',
    snakeStyle: 'solid',
    foodStyle: 'square'
  },
  {
    id: 'rainbow',
    name: '彩虹糖果',
    en: 'RAINBOW CANDY',
    desc: '蛇身按节数循环七彩并缓缓流动，食物是会发光的小球。',
    tags: ['七彩', '会流动'],
    palette: {
      boardBg: '#0d0a18',
      grid: 'rgba(244,114,182,.07)',
      border: '#f472b6',
      glow: 'rgba(244,114,182,.45)',
      text: '#fbcfe8',
      muted: '#6b21a8',
      pageBg: '#0b0714',
      snakeBody: '#ffffff',
      snakeHead: '#ffffff',
      eye: '#1f2937',
      food: '#ffffff',
      wall: '#4c1d95',
      wallEdge: '#c084fc',
      accent: '#f472b6'
    },
    pattern: 'dots',
    snakeStyle: 'rainbow',
    foodStyle: 'circle'
  },
  {
    id: 'flame',
    name: '熔岩烈焰',
    en: 'LAVA FLAME',
    desc: '从暗红烧到亮黄的渐变色蛇身，底板像滚烫的岩层，食物是火种。',
    tags: ['渐变', '高温'],
    palette: {
      boardBg: '#1a0805',
      grid: 'rgba(249,115,22,.09)',
      border: '#f97316',
      glow: 'rgba(249,115,22,.5)',
      text: '#fdba74',
      muted: '#7c2d12',
      pageBg: '#150604',
      snakeBody: '#ea580c',
      snakeHead: '#fde047',
      eye: '#1a0805',
      food: '#fbbf24',
      wall: '#7f1d1d',
      wallEdge: '#dc2626',
      accent: '#fb923c'
    },
    pattern: 'dots',
    snakeStyle: 'gradient',
    foodStyle: 'diamond'
  },
  {
    id: 'gold',
    name: '黄金矿脉',
    en: 'GOLDEN VEIN',
    desc: '青铜到纯金的金属渐变，食物是一枚枚金币，看着就很贵。',
    tags: ['金属', '金币'],
    palette: {
      boardBg: '#14100a',
      grid: 'rgba(234,179,8,.10)',
      border: '#eab308',
      glow: 'rgba(234,179,8,.5)',
      text: '#fde68a',
      muted: '#78350f',
      pageBg: '#100c07',
      snakeBody: '#b45309',
      snakeHead: '#fde047',
      eye: '#14100a',
      food: '#facc15',
      wall: '#57534e',
      wallEdge: '#a8a29e',
      accent: '#eab308'
    },
    pattern: 'grid',
    snakeStyle: 'gradient',
    foodStyle: 'coin'
  },
  {
    id: 'ice',
    name: '极地冰晶',
    en: 'POLAR CRYSTAL',
    desc: '半透明的冰蓝色蛇身带一层高光，斜纹冰面，食物是六棱冰晶。',
    tags: ['半透明', '冰晶'],
    palette: {
      boardBg: '#081726',
      grid: 'rgba(186,230,253,.10)',
      border: '#7dd3fc',
      glow: 'rgba(125,211,252,.5)',
      text: '#e0f2fe',
      muted: '#0c4a6e',
      pageBg: '#061320',
      snakeBody: '#a5f3fc',
      snakeHead: '#f0f9ff',
      eye: '#0c4a6e',
      food: '#67e8f9',
      wall: '#1e3a5f',
      wallEdge: '#7dd3fc',
      accent: '#38bdf8'
    },
    pattern: 'frost',
    snakeStyle: 'glass',
    foodStyle: 'crystal'
  },
  {
    id: 'neonline',
    name: '霓虹描边',
    en: 'NEON OUTLINE',
    desc: '蛇身是空心描边，像霓虹灯管；底板带 CRT 扫描线，头是品红。',
    tags: ['空心', '扫描线'],
    palette: {
      boardBg: '#050510',
      grid: 'rgba(34,211,238,.07)',
      border: '#22d3ee',
      glow: 'rgba(34,211,238,.5)',
      text: '#a5f3fc',
      muted: '#1e3a8a',
      pageBg: '#04040c',
      snakeBody: '#22d3ee',
      snakeHead: '#f472b6',
      eye: '#050510',
      food: '#f0abfc',
      wall: '#312e81',
      wallEdge: '#6366f1',
      accent: '#22d3ee'
    },
    pattern: 'scan',
    snakeStyle: 'outline',
    foodStyle: 'circle'
  },
  {
    id: 'pixel',
    name: '8bit 像素',
    en: 'PIXEL 8BIT',
    desc: '直角方块蛇，没有圆角没有渐变，纯正红白机味儿。',
    tags: ['复古', '硬边'],
    palette: {
      boardBg: '#101820',
      grid: 'rgba(148,163,184,.07)',
      border: '#94a3b8',
      glow: 'rgba(148,163,184,.35)',
      text: '#cbd5e1',
      muted: '#334155',
      pageBg: '#0b1118',
      snakeBody: '#22c55e',
      snakeHead: '#fbbf24',
      eye: '#101820',
      food: '#ef4444',
      wall: '#475569',
      wallEdge: '#94a3b8',
      accent: '#94a3b8'
    },
    pattern: 'dots',
    snakeStyle: 'pixel',
    foodStyle: 'pixel'
  },
  {
    id: 'galaxy',
    name: '星河漫游',
    en: 'GALAXY DRIFT',
    desc: '星空底板上撒满星点，蛇身从靛蓝渐变到青色，食物是四角星。',
    tags: ['星空', '渐变'],
    palette: {
      boardBg: '#070b1f',
      grid: 'rgba(129,140,248,.06)',
      border: '#818cf8',
      glow: 'rgba(129,140,248,.5)',
      text: '#c7d2fe',
      muted: '#312e81',
      pageBg: '#05071a',
      snakeBody: '#22d3ee',
      snakeHead: '#e0e7ff',
      eye: '#070b1f',
      food: '#fde68a',
      wall: '#312e81',
      wallEdge: '#6366f1',
      accent: '#a5b4fc'
    },
    pattern: 'stars',
    snakeStyle: 'gradient',
    foodStyle: 'star'
  },
  {
    id: 'sakura',
    name: '樱花物语',
    en: 'SAKURA STORY',
    desc: '粉白配色，背景飘着几片花瓣，食物是一片樱花瓣。',
    tags: ['温柔', '花瓣'],
    palette: {
      boardBg: '#1c0f18',
      grid: 'rgba(251,207,232,.07)',
      border: '#f9a8d4',
      glow: 'rgba(249,168,212,.5)',
      text: '#fbcfe8',
      muted: '#831843',
      pageBg: '#170b13',
      snakeBody: '#fb7185',
      snakeHead: '#ffffff',
      eye: '#1c0f18',
      food: '#fda4af',
      wall: '#4c1d24',
      wallEdge: '#9f1239',
      accent: '#f472b6'
    },
    pattern: 'petal',
    snakeStyle: 'gradient',
    foodStyle: 'petal'
  },
  {
    id: 'circuit',
    name: '电子电路',
    en: 'CIRCUIT BOARD',
    desc: '绿油油的电路板底板，带焊点与走线；蛇是带高光的方形芯片。',
    tags: ['电路板', '科技'],
    palette: {
      boardBg: '#04140c',
      grid: 'rgba(16,185,129,.09)',
      border: '#10b981',
      glow: 'rgba(16,185,129,.5)',
      text: '#6ee7b7',
      muted: '#064e3b',
      pageBg: '#03110a',
      snakeBody: '#34d399',
      snakeHead: '#a7f3d0',
      eye: '#04140c',
      food: '#fde047',
      wall: '#065f46',
      wallEdge: '#34d399',
      accent: '#10b981'
    },
    pattern: 'circuit',
    snakeStyle: 'pixel',
    foodStyle: 'circle'
  },
  {
    id: 'ghost',
    name: '幽影潜行',
    en: 'GHOST SHADOW',
    desc: '半透明的紫色蛇，越到尾巴越淡，整条蛇都透着光。',
    tags: ['半透明', '幽光'],
    palette: {
      boardBg: '#0b0716',
      grid: 'rgba(167,139,250,.06)',
      border: '#a78bfa',
      glow: 'rgba(167,139,250,.5)',
      text: '#ddd6fe',
      muted: '#3730a3',
      pageBg: '#090513',
      snakeBody: '#a78bfa',
      snakeHead: '#ede9fe',
      eye: '#0b0716',
      food: '#5eead4',
      wall: '#2e1065',
      wallEdge: '#7c3aed',
      accent: '#a78bfa'
    },
    pattern: 'none',
    snakeStyle: 'ghost',
    foodStyle: 'circle'
  }
]

export const DEFAULT_SKIN = SKINS[0].id

/** 按 id 取皮肤，取不到给基础款 */
export function getSkin(id) {
  return SKINS.find((s) => s.id === id) || SKINS[0]
}

/**
 * 把「地图 + 皮肤」合成渲染层需要的 view 对象
 * - 基础皮肤（plain）：完全用地图自带配色，图案/造型用默认值 → 和以前一模一样
 * - 特设皮肤：用皮肤自己的整套配色，覆盖地图的颜色（但不动地图的机制）
 */
export function resolveTheme(map, skin) {
  const s = skin && skin.id !== 'plain' ? skin : null
  const palette = s ? { ...s.palette } : { ...map.theme }
  if (!palette.pageBg) palette.pageBg = '#0b1a0f'
  return {
    map,
    skinId: skin ? skin.id : 'plain',
    skinName: skin ? skin.name : SKINS[0].name,
    palette,
    pattern: s ? s.pattern : 'grid',
    snakeStyle: s ? s.snakeStyle : 'solid',
    foodStyle: s ? s.foodStyle : 'square'
  }
}

/* 记住玩家选中的皮肤 */
const KEY = 'snake_skin'
export function loadSkinId() {
  try {
    return localStorage.getItem(KEY) || DEFAULT_SKIN
  } catch (e) {
    return DEFAULT_SKIN
  }
}
export function saveSkinId(id) {
  try {
    localStorage.setItem(KEY, id)
  } catch (e) {
    /* 隐私模式下可能不可用，忽略 */
  }
}
