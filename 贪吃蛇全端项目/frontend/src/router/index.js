import { createRouter, createWebHashHistory } from 'vue-router'
import Home from '../views/Home.vue'
import Login from '../views/Login.vue'
import Register from '../views/Register.vue'
import Game from '../views/Game.vue'

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: '/', component: Home },          // 首页：地图选择 / 玩法 / 排行榜
    { path: '/login', component: Login },
    { path: '/register', component: Register },
    { path: '/game', component: Game }       // 地址栏可带 ?map=forest|neon|ice
  ]
})

// 路由守卫：没登录不能进游戏页
router.beforeEach((to, from, next) => {
  const logged = sessionStorage.getItem('snake_user')
  if (to.path === '/game' && !logged) {
    next({ path: '/login', query: to.query })  // 把选中的地图一起带过去
  } else {
    next()
  }
})

export default router
