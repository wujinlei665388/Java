<template>
  <canvas class="bg-snake" ref="cv"></canvas>
</template>

<script setup>
/**
 * 背景装饰：一条在全屏游走的贪吃蛇（首页 / 登录 / 注册共用）
 * 抽成组件是为了不再三处复制粘贴同一段 canvas 代码。
 */
import { ref, onMounted, onBeforeUnmount } from 'vue'

const cv = ref(null)
let timer = null
let resizeFn = null

onMounted(() => {
  const canvas = cv.value
  const ctx = canvas.getContext('2d')
  const GRID = 20
  let cols, rows, snake, dir

  resizeFn = function resize() {
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    cols = Math.ceil(canvas.width / GRID)
    rows = Math.ceil(canvas.height / GRID)
  }
  resizeFn()
  window.addEventListener('resize', resizeFn)

  const sx = Math.floor(Math.random() * 30)
  const sy = Math.floor(Math.random() * 20)
  snake = Array.from({ length: 12 }, (_, i) => ({ x: sx - i, y: sy }))
  dir = { x: 1, y: 0 }

  timer = setInterval(() => {
    if (Math.random() < 0.3) {
      const d = [{ x: 1, y: 0 }, { x: -1, y: 0 }, { x: 0, y: 1 }, { x: 0, y: -1 }]
      dir = d[Math.floor(Math.random() * 4)]
    }
    const head = { x: snake[0].x + dir.x, y: snake[0].y + dir.y }
    head.x = (head.x + cols) % cols
    head.y = (head.y + rows) % rows
    snake.unshift(head)
    if (snake.length > 14) snake.pop()

    ctx.clearRect(0, 0, canvas.width, canvas.height)
    for (let i = snake.length - 1; i >= 0; i--) {
      ctx.fillStyle = i === 0 ? 'rgba(250,204,21,.8)' : 'rgba(74,222,128,.55)'
      ctx.fillRect(snake[i].x * GRID + 2, snake[i].y * GRID + 2, GRID - 4, GRID - 4)
    }
  }, 120)
})

onBeforeUnmount(() => {
  clearInterval(timer)
  if (resizeFn) window.removeEventListener('resize', resizeFn)
})
</script>

<style scoped>
.bg-snake {
  position: fixed;
  inset: 0;
  width: 100%;
  height: 100%;
  opacity: 0.25;
  pointer-events: none;
}
</style>
