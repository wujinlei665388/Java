import request from './request'

/**
 * 首页接口
 *
 * 首页上的数字来自好几张表（玩家总数看 user，总局数/平均分/地图皮肤热度看 game_record，
 * 我的排名同时看 user + game_record），所以后端把它们合成一个接口返回，
 * 首页只发一个请求就能把 Hero 统计、排行榜、地图/皮肤热度、我的战绩全部填上。
 *
 * 返回结构（data 层）：
 * {
 *   stats: {
 *     playerCount,   // 注册玩家总数
 *     gameCount,     // 玩家主动保存的对局总数
 *     topScore,      // 全服最高分（取自 user.score，与排行榜第一名同源）
 *     bestPerGame,   // 单局最高分（取自 game_record）
 *     avgScore,      // 每局平均分（保留一位小数）
 *     todayGames,    // 今日保存的对局数
 *     todayPlayers   // 今日活跃玩家数（按用户名去重）
 *   },
 *   rank:     [{ id, username, score }],            // 排行榜前 limit 名
 *   mapRank:  [{ id, name, count }],                // 地图热度，count 倒序，只含玩过的
 *   skinRank: [{ id, name, count }],                // 皮肤热度，同上
 *   me: null | { id, username, score, rank, games, best, totalFood }   // 未登录/用户不存在时是 null
 * }
 *
 * @param {Object}  opts
 *   limit    {number}        排行榜取前几名，默认 5
 *   userId   {number|string} 当前登录用户 id（可选，传了才返回 me）
 *   username {string}        当前登录用户名（可选）
 */
export function getHomeSummary({ limit = 5, userId, username } = {}) {
  return request.get('/home/summary', { params: { limit, userId, username } })
}
