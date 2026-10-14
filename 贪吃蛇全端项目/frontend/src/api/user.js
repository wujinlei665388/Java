import request from './request'

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

// 请求实例原来就在这个文件里，为了不打断可能存在的 `import request from './user'`，
// 这里继续把它转发出去；新代码请直接从 './request' 引入。
export { default } from './request'
