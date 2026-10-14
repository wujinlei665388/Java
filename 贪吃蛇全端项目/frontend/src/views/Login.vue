<template>
  <div class="page">
    <BgSnake />
    <div class="grid-bg"></div>

    <div class="login-box">
      <div class="title">贪吃蛇</div>
      <div class="subtitle">S N A K E &nbsp; L O G I N</div>

      <div class="map-tip">
        登录后进入地图：<b>{{ mapName }}</b>
        <a @click.prevent="$router.push('/')">换一张 &gt;&gt;</a>
      </div>

      <div class="field">
        <label>USERNAME · 用户名</label>
        <input v-model.trim="username" type="text" placeholder="请输入用户名" maxlength="20"
               @keyup.enter="doLogin">
      </div>
      <div class="field">
        <label>PASSWORD · 密码</label>
        <input v-model="password" type="password" placeholder="请输入密码" maxlength="32"
               @keyup.enter="doLogin">
      </div>

      <button class="btn" :disabled="loading" @click="doLogin">
        {{ loading ? '登录中...' : '进 入 游 戏' }}
      </button>

      <div class="msg" :class="msgType">{{ msg }}</div>
      <div class="links">
        还没有账号？<a @click.prevent="$router.push('/register')">立即注册 &gt;&gt;</a>
      </div>
      <div class="links dim">
        <a @click.prevent="$router.push('/')">返回首页</a>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { login } from '../api/user'
import BgSnake from '../components/BgSnake.vue'
import { getMap, loadMapId, saveMapId } from '../game/maps'

const router = useRouter()
const route = useRoute()

// 地图来源：首页点"选它开玩"会带 ?map=xxx 过来，否则用上次选过的
const mapId = getMap(route.query.map || loadMapId()).id
const mapName = getMap(mapId).name

const username = ref('')
const password = ref('')
const msg = ref('')
const msgType = ref('')
const loading = ref(false)

function showMsg(text, type) {
  msg.value = text
  msgType.value = type
}

async function doLogin() {
  if (!username.value) return showMsg('用户名不能为空！', 'err')
  if (!password.value) return showMsg('密码不能为空！', 'err')
  loading.value = true
  const res = await login(username.value, password.value)
  loading.value = false
  if (res.code === 200) {
    // 同时存下用户名和用户 id：id 用于游戏结束后保存最高分
    sessionStorage.setItem('snake_user', res.data.username)
    sessionStorage.setItem('snake_uid', String(res.data.id))
    saveMapId(mapId) // 记住这次选的地图
    showMsg('登录成功！正在进入游戏...', 'ok')
    setTimeout(() => router.push({ path: '/game', query: { map: mapId } }), 600)
  } else {
    showMsg(res.msg || '登录失败', 'err')
  }
}
</script>

<style scoped>
.page {
  height: 100%;
  position: relative;
  overflow-y: auto;
}

.grid-bg {
  position: fixed;
  inset: 0;
  background-image:
    linear-gradient(rgba(74, 222, 128, 0.05) 1px, transparent 1px),
    linear-gradient(90deg, rgba(74, 222, 128, 0.05) 1px, transparent 1px);
  background-size: 20px 20px;
}

.login-box {
  position: relative;
  z-index: 10;
  width: 360px;
  margin: 8vh auto 6vh;
  padding: 36px 34px 30px;
  background: rgba(7, 19, 10, 0.92);
  border: 4px solid #4ade80;
  box-shadow: 0 0 30px rgba(74, 222, 128, 0.35), inset 0 0 20px rgba(74, 222, 128, 0.08);
}

.map-tip {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  margin: -14px 0 22px;
  padding: 7px 10px;
  font-size: 11.5px;
  letter-spacing: 1px;
  color: #14532d;
  border: 1px dashed #166534;
}

.map-tip b {
  color: #facc15;
  font-weight: normal;
}

.map-tip a {
  color: #4ade80;
  cursor: pointer;
  white-space: nowrap;
}

.map-tip a:hover {
  text-shadow: 0 0 8px rgba(74, 222, 128, 0.8);
}

.title {
  text-align: center;
  font-size: 26px;
  letter-spacing: 8px;
  text-shadow: 0 0 12px rgba(74, 222, 128, 0.7);
  margin-bottom: 4px;
}

.subtitle {
  text-align: center;
  color: #14532d;
  font-size: 12px;
  letter-spacing: 3px;
  margin-bottom: 28px;
}

.field {
  margin-bottom: 20px;
}

.field label {
  display: block;
  font-size: 12px;
  letter-spacing: 2px;
  margin-bottom: 8px;
  color: #a3e635;
}

.field input {
  width: 100%;
  padding: 11px 12px;
  font-family: inherit;
  font-size: 14px;
  color: #4ade80;
  background: #0b1a0f;
  border: 2px solid #166534;
  outline: none;
  letter-spacing: 1px;
}

.field input:focus {
  border-color: #4ade80;
  box-shadow: 0 0 10px rgba(74, 222, 128, 0.45);
}

.field input::placeholder {
  color: #14532d;
}

.btn {
  width: 100%;
  margin-top: 6px;
  padding: 12px;
  font-family: inherit;
  font-size: 15px;
  font-weight: bold;
  letter-spacing: 4px;
  color: #07130a;
  background: #4ade80;
  border: none;
  cursor: pointer;
  box-shadow: 0 0 14px rgba(74, 222, 128, 0.55);
  transition: all 0.15s;
}

.btn:hover {
  background: #facc15;
  box-shadow: 0 0 16px rgba(250, 204, 21, 0.7);
}

.btn:disabled {
  opacity: 0.6;
  cursor: wait;
}

.msg {
  min-height: 20px;
  text-align: center;
  font-size: 12px;
  letter-spacing: 1px;
  margin-top: 14px;
}

.msg.ok {
  color: #a3e635;
}

.msg.err {
  color: #ef4444;
}

.links {
  margin-top: 8px;
  text-align: center;
  font-size: 12px;
  letter-spacing: 1px;
}

.links a {
  color: #facc15;
  text-decoration: none;
  cursor: pointer;
}

.links a:hover {
  text-shadow: 0 0 8px rgba(250, 204, 21, 0.8);
}

.links.dim {
  margin-top: 10px;
}

.links.dim a {
  color: #14532d;
  font-size: 11.5px;
}

.links.dim a:hover {
  color: #4ade80;
  text-shadow: 0 0 8px rgba(74, 222, 128, 0.8);
}
</style>
