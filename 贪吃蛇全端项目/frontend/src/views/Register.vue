<template>
  <div class="page">
    <BgSnake />
    <div class="grid-bg"></div>

    <div class="reg-box">
      <div class="title">贪吃蛇</div>
      <div class="subtitle">S N A K E &nbsp; R E G I S T E R</div>

      <div class="field">
        <label>USERNAME · 用户名</label>
        <input v-model.trim="username" type="text" placeholder="3-20 位字母/数字" maxlength="20"
               @keyup.enter="doRegister">
      </div>
      <div class="field">
        <label>PASSWORD · 密码</label>
        <input v-model="password" type="password" placeholder="至少 6 位" maxlength="32"
               @keyup.enter="doRegister">
      </div>
      <div class="field">
        <label>CONFIRM · 确认密码</label>
        <input v-model="password2" type="password" placeholder="再次输入密码" maxlength="32"
               @keyup.enter="doRegister">
      </div>

      <button class="btn" :disabled="loading" @click="doRegister">
        {{ loading ? '注册中...' : '注 册 账 号' }}
      </button>

      <div class="msg" :class="msgType">{{ msg }}</div>
      <div class="links">
        已有账号？<a @click.prevent="$router.push('/login')">返回登录 &gt;&gt;</a>
      </div>
      <div class="links dim">
        <a @click.prevent="$router.push('/')">返回首页</a>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { register } from '../api/user'
import BgSnake from '../components/BgSnake.vue'

const router = useRouter()
const username = ref('')
const password = ref('')
const password2 = ref('')
const msg = ref('')
const msgType = ref('')
const loading = ref(false)

function showMsg(text, type) {
  msg.value = text
  msgType.value = type
}

async function doRegister() {
  const nameReg = /^[A-Za-z0-9_]{3,20}$/
  if (!nameReg.test(username.value)) {
    return showMsg('用户名需为 3-20 位字母/数字/下划线！', 'err')
  }
  if (password.value.length < 6) {
    return showMsg('密码至少 6 位！', 'err')
  }
  if (password.value !== password2.value) {
    return showMsg('两次密码输入不一致！', 'err')
  }
  loading.value = true
  const res = await register(username.value, password.value)
  loading.value = false
  if (res.code === 200) {
    showMsg('注册成功！正在跳转登录页...', 'ok')
    setTimeout(() => router.push('/login'), 900)
  } else {
    showMsg(res.msg || '注册失败', 'err')
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

.reg-box {
  position: relative;
  z-index: 10;
  width: 360px;
  margin: 7vh auto;
  padding: 36px 34px 30px;
  background: rgba(7, 19, 10, 0.92);
  border: 4px solid #a3e635;
  box-shadow: 0 0 30px rgba(163, 230, 53, 0.3), inset 0 0 20px rgba(163, 230, 53, 0.08);
}

.title {
  text-align: center;
  font-size: 26px;
  letter-spacing: 8px;
  text-shadow: 0 0 12px rgba(163, 230, 53, 0.7);
  margin-bottom: 4px;
}

.subtitle {
  text-align: center;
  color: #14532d;
  font-size: 12px;
  letter-spacing: 3px;
  margin-bottom: 26px;
}

.field {
  margin-bottom: 16px;
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
  border-color: #a3e635;
  box-shadow: 0 0 10px rgba(163, 230, 53, 0.45);
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
  background: #a3e635;
  border: none;
  cursor: pointer;
  box-shadow: 0 0 14px rgba(163, 230, 53, 0.55);
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
