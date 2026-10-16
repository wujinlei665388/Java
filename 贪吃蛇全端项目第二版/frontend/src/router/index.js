import { createRouter, createWebHashHistory } from 'vue-router'
import Home from '../views/Home.vue'
import Login from '../views/Login.vue'
import Register from '../views/Register.vue'
import Game from '../views/Game.vue'
import MySpace from '../views/MySpace.vue'

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: '/', component: Home },          // 首页：地图选择 / 玩法 / 排行榜
    { path: '/login', component: Login },
    { path: '/register', component: Register },
    { path: '/game', component: Game },      // 地址栏可带 ?map=forest|neon|ice
    { path: '/my', component: MySpace }      // 我的空间：皮肤库 + 对局回放（可带 ?tab=records）
  ]
})

// 路由守卫：没登录不能进游戏页
// 注意 /my（我的空间）不拦：皮肤库不登录也能逛，只有对局那一栏需要登录，
// 那一栏自己会给出登录引导。
router.beforeEach((to, from, next) => {
  const logged = sessionStorage.getItem('snake_user')
  if (to.path === '/game' && !logged) {
    next({ path: '/login', query: to.query })  // 把选中的地图一起带过去
  } else {
    next()
  }
})

export default router
