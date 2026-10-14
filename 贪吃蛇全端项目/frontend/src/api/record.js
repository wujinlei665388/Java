import request from './request'

/**
 * 对局记录相关接口
 *
 * 设计约定：每局游戏结束时，前端会把这一局的数据攒成一个 payload，
 * 只有玩家点了「保存本局」才会调用 saveRecord 发出去；
 * 点「不保存」就什么都不写，后端不会收到任何请求。
 */

/**
 * 保存一局对局记录
 * @param {Object} payload
 *   userId      {number|string} 当前用户 id（可为空）
 *   username    {string}        当前用户名
 *   score       {number}        本局得分
 *   snakeLen    {number}        结束时蛇的长度
 *   foodCount   {number}        吃掉的食物个数
 *   mapId/mapName    {string}   地图标识 / 中文名
 *   skinId/skinName  {string}   皮肤标识 / 中文名
 *   duration    {number}        本局时长（秒，不含暂停）
 */
export function saveRecord(payload) {
  return request.post('/record/save', payload)
}

/** 我的对局列表（按保存时间倒序） */
export function getMyRecords(userId, username, limit = 20) {
  return request.get('/record/list', { params: { userId, username, limit } })
}

/** 我的对局统计：总局数 / 最高分 / 平均分 / 最长蛇 / 总时长 / 总食物 */
export function getRecordStats(userId, username) {
  return request.get('/record/stats', { params: { userId, username } })
}

/** 删除自己的一条对局记录 */
export function deleteRecord(id, userId, username) {
  return request.delete(`/record/${id}`, { params: { userId, username } })
}

/**
 * 取某一局的回放轨迹
 * 成功返回 { record, replay, steps }，其中 replay 是前端编码的轨迹文本；
 * 这一局没存过回放（比如是功能上线前保存的老记录）时返回 code 400 + 说明。
 */
export function getRecordReplay(id, userId, username) {
  return request.get(`/record/${id}/replay`, { params: { userId, username } })
}
