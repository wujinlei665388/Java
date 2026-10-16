/**
 * 地图配置（三种风格）
 * ------------------------------------------------------------------
 * **地图只管机制，皮肤只管外观**（皮肤在 skins.js）：
 *   - 本文件：障碍布局、能否穿越边界、速度、每果得分，以及"纯色基础皮肤"
 *     下使用的地图自带配色 theme
 *   - skins.js：整套配色 + 底板图案 + 蛇身/食物造型
 * 两者由 skins.js 的 resolveTheme(map, skin) 合成，首页缩略图和游戏页共用。
 *
 * 字段说明：
 *   id              地图唯一标识，路由用 ?map=xxx 传递
 *   name / en       中文名 / 英文名（卡片上展示）
 *   rule            一句话机制说明（卡片 + 游戏页底部提示）
 *   desc            卡片上的介绍文案
 *   tags            卡片上的标签
 *   theme           地图自带配色（选"纯色基础"皮肤时生效）
 *   rules.wrap      true = 边界可穿越（右边走出去，左边穿回来）
 *   rules.walls     障碍方块，写矩形 {x,y,w,h}（单位是格），会展开成格子
 *   rules.speed     起始速度（毫秒/步，越小越快）
 *   rules.minSpeed  最快速度下限（加速不会超过它）
 *   rules.step      每吃一个食物提速多少毫秒
 *   rules.foodScore 每个食物的得分
 * ------------------------------------------------------------------
 */

export const GRID = 20   // 20 x 20 格
export const BOARD = 400 // 画布 400 x 400，每格 20px

export const MAPS = [
  {
    id: 'forest',
    name: '经典森林',
    en: 'CLASSIC FOREST',
    rule: '无障碍物 · 撞墙即结束',
    desc: '最原汁原味的贪吃蛇。开阔草地，没有任何遮挡，专心吃食物、把蛇养长就好。',
    tags: ['新手友好', '经典规则', '10 分/个'],
    theme: {
      boardBg: '#07130a',
      grid: 'rgba(74,222,128,.07)',
      border: '#4ade80',
      glow: 'rgba(74,222,128,.35)',
      text: '#4ade80',
      muted: '#14532d',
      pageBg: '#0b1a0f',
      snakeBody: '#4ade80',
      snakeHead: '#facc15',
      food: '#ef4444',
      wall: '#166534',
      wallEdge: '#22c55e',
      eye: '#07130a',
      accent: '#a3e635'
    },
    rules: { wrap: false, walls: [], speed: 150, minSpeed: 70, step: 3, foodScore: 10 }
  },
  {
    id: 'neon',
    name: '霓虹赛博',
    en: 'NEON CYBER',
    rule: '紫色壁垒不可撞 · 撞墙即结束',
    desc: '赛博朋克街区。紫色数据壁垒把场地切成迷宫，走位要提前一步想好，撞上壁垒就断电。',
    tags: ['有障碍', '高难度', '15 分/个'],
    theme: {
      boardBg: '#0a0618',
      grid: 'rgba(168,85,247,.12)',
      border: '#d946ef',
      glow: 'rgba(217,70,239,.45)',
      text: '#e9d5ff',
      muted: '#4c1d95',
      pageBg: '#08040f',
      snakeBody: '#22d3ee',
      snakeHead: '#e879f9',
      food: '#fde047',
      wall: '#7c3aed',
      wallEdge: '#c084fc',
      eye: '#0a0618',
      accent: '#a855f7'
    },
    rules: {
      wrap: false,
      // 四角 L 形堡垒 + 上下两段横向屏障（中间留出通道，出生点那一行保持畅通）
      walls: [
        { x: 3,  y: 3,  w: 4, h: 1 },
        { x: 3,  y: 4,  w: 1, h: 3 },
        { x: 13, y: 3,  w: 4, h: 1 },
        { x: 16, y: 4,  w: 1, h: 3 },
        { x: 3,  y: 16, w: 4, h: 1 },
        { x: 3,  y: 13, w: 1, h: 3 },
        { x: 13, y: 16, w: 4, h: 1 },
        { x: 16, y: 13, w: 1, h: 3 },
        { x: 7,  y: 5,  w: 6, h: 1 },
        { x: 7,  y: 14, w: 6, h: 1 }
      ],
      speed: 160,
      minSpeed: 75,
      step: 3,
      foodScore: 15
    }
  },
  {
    id: 'ice',
    name: '极地冰川',
    en: 'ARCTIC ICE',
    rule: '边界可穿越 · 节奏更快',
    desc: '一望无际的浮冰，没有墙。走到边缘会从对面穿出来，速度更快，小心别把自己绕进去。',
    tags: ['边界穿越', '高速', '12 分/个'],
    theme: {
      boardBg: '#061623',
      grid: 'rgba(125,211,252,.10)',
      border: '#7dd3fc',
      glow: 'rgba(125,211,252,.45)',
      text: '#bae6fd',
      muted: '#0c4a6e',
      pageBg: '#061320',
      snakeBody: '#7dd3fc',
      snakeHead: '#e0f2fe',
      food: '#fbbf24',
      wall: '#334155',
      wallEdge: '#94a3b8',
      eye: '#061623',
      accent: '#38bdf8'
    },
    rules: { wrap: true, walls: [], speed: 130, minSpeed: 60, step: 3, foodScore: 12 }
  }
]

export const DEFAULT_MAP = MAPS[0].id

/** 按 id 取地图，取不到就给第一张（避免脏参数把游戏页搞崩） */
export function getMap(id) {
  return MAPS.find((m) => m.id === id) || MAPS[0]
}

/** 把 walls 矩形展开成 "x,y" 集合，碰撞判断 O(1) */
export function wallSet(map) {
  const set = new Set()
  for (const r of map.rules.walls) {
    for (let x = r.x; x < r.x + r.w; x++) {
      for (let y = r.y; y < r.y + r.h; y++) set.add(x + ',' + y)
    }
  }
  return set
}

/** 读取 / 记住玩家选中的地图（首页选完，登录后游戏页能接着用） */
const KEY = 'snake_map'
export function loadMapId() {
  try {
    return localStorage.getItem(KEY) || DEFAULT_MAP
  } catch (e) {
    return DEFAULT_MAP
  }
}
export function saveMapId(id) {
  try {
    localStorage.setItem(KEY, id)
  } catch (e) {
    /* 隐私模式下 localStorage 可能不可用，忽略 */
  }
}

/* ------------------------- 绘制 -------------------------
 * 画棋盘 / 蛇 / 食物的函数都在 render.js 里（皮肤系统要复用），
 * 这里只保留地图数据：配色 theme + 机制 rules。
 * ------------------------------------------------------- */
