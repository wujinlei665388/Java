import axios from 'axios'

/**
 * 统一请求实例
 * 通过 vite 代理，所有请求走 /api，由开发服务器转发到 http://localhost:8080
 * （后端不在 8080 时，改 vite.config.js 里的 proxy target 即可）
 */
const request = axios.create({
  baseURL: '/api',
  timeout: 8000
})

// 统一响应格式: { code: 200, msg: 'ok', data: ... }
// 这里直接把 data 层返回给业务代码，网络异常也归一成同样的结构，
// 这样页面里就不用写 try/catch 了。
request.interceptors.response.use(
  (resp) => resp.data,
  () => ({ code: -1, msg: '网络错误，请确认后端已启动（端口 8080）', data: null })
)

/** 登录 */
export function login(username, password) {
  return request.post('/user/login', { username, password })
}

/** 注册 */
export function register(username, password) {
  return request.post('/user/register', { username, password })
}

/** 保存最高分（后端只在更大时才更新） */
export function saveScore(userId, score) {
  return request.post('/user/score', { userId, score })
}

/** 查询用户信息（含最高分） */
export function getUserInfo(username) {
  return request.get('/user/info', { params: { username } })
}

/** 排行榜 */
export function getRank(limit = 10) {
  return request.get('/user/rank', { params: { limit } })
}

export default request
