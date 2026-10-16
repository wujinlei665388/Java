import axios from 'axios'

/**
 * 统一请求实例
 * 通过 vite 代理，所有请求走 /api，由开发服务器转发到 http://localhost:8080
 * （后端不在 8080 时，改 vite.config.js 里的 proxy target 即可）
 *
 * 单独抽成一个文件，是为了让 api/user.js、api/record.js 共用同一个实例
 * （共用拦截器，也就共用同一套"网络异常归一化"的返回结构）。
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

export default request
