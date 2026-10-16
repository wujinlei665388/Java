package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.fenglin.springboottest.entity.GameRecord;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.mapper.GameRecordMapper;
import com.fenglin.springboottest.mapper.UserMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 首页聚合服务
 *
 * 首页要的东西很碎：站点统计 + 排行榜 + 地图/皮肤热度 + "我自己的战绩"。
 * 如果让前端一条条请求，开一次首页要打四五个来回；这里在服务端合成一个对象，
 * 前端一个请求就能把首页填满（QUERY 也从 5 次降到 1 次）。
 *
 * ── 两个统计口径要分清（很容易搞混）────────────────────────────
 *   user.score       每一行的"历史最高分"   → 排行榜、全服最高分、我的排名都看它
 *   game_record      每一局的原始流水       → 总局数、平均分、地图/皮肤热度看它
 *   所以"全服最高分"取自 user，"每局平均分"取自 game_record，两者不是一回事。
 *
 * ── 不新增任何数据库表/字段 ──────────────────────────────────
 *   全部靠现有两张表查询得出，所以 schema.sql 不用改，
 *   老库直接就能跑（这也是这个接口不建汇总表的原因）。
 */
@Service
public class HomeService {

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private GameRecordMapper recordMapper;

    @Autowired
    private UserService userService;

    @Autowired
    private GameRecordService recordService;

    /** 排行榜默认取前 5 名（首页只显示 TOP 5） */
    private static final int DEFAULT_LIMIT = 5;
    /** 一次最多给 100 名，防止有人 limit=99999 把库拖垮 */
    private static final int MAX_LIMIT = 100;
    /** 地图/皮肤热度榜最多返回多少项（本来就只有 3 张图 / 11 款皮肤，给足余量） */
    private static final int MAX_HEAT_ITEMS = 20;

    /**
     * 首页汇总数据
     *
     * @param limitParam 排行榜取前几名（<=0 或 >100 会回落到默认值 5）
     * @param userId     当前登录用户 id（可为空）
     * @param username   当前登录用户名（可为空）
     * @return { stats, rank, mapRank, skinRank, me }
     *         me 只有在传了 userId / username 且这个用户真实存在时才不是 null
     */
    public Map<String, Object> summary(Integer limitParam, Long userId, String username) {
        int limit = (limitParam == null || limitParam <= 0 || limitParam > MAX_LIMIT)
                ? DEFAULT_LIMIT : limitParam;

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("stats", stats());
        data.put("rank", rank(limit));
        // 地图 / 皮肤热度：从"玩家主动保存的对局"里统计，没存过的局不算数
        // （也就是说这是"已存档热度"，不是"开过多少局"）
        data.put("mapRank", heat("map_id", "map_name"));
        data.put("skinRank", heat("skin_id", "skin_name"));
        data.put("me", me(userId, username));
        return data;
    }

    /* ---------------------------------------------------------------
     *  站点统计
     * --------------------------------------------------------------- */

    /**
     * 站点总览：注册玩家数 / 已存对局数 / 全服最高分 / 每局平均分 / 今日活跃
     *
     * 注意 playerCount 和"排行榜条数"不是一回事：
     * 排行榜只取前 N 名，条数最多就是 N；玩家总数必须单独 count，
     * 否则会出现"注册了 20 个人，首页却显示上榜 5 人"这种假数据。
     */
    private Map<String, Object> stats() {
        long playerCount = toLong(userMapper.selectCount(null), 0L);

        // 对局维度的三个数一条聚合查询就够（COUNT 在空表时是 0，SUM/MAX 会是 NULL）
        long gameCount = 0L;
        long scoreSum = 0L;
        long bestPerGame = 0L;
        QueryWrapper<GameRecord> agg = new QueryWrapper<>();
        agg.select("COUNT(*) AS cnt", "SUM(score) AS total", "MAX(score) AS best");
        List<Map<String, Object>> aggRows = safeSelectMaps(agg);
        if (!aggRows.isEmpty()) {
            Map<String, Object> row = aggRows.get(0);
            gameCount = toLong(pick(row, "cnt"), 0L);
            scoreSum = toLong(pick(row, "total"), 0L);
            bestPerGame = toLong(pick(row, "best"), 0L);
        }

        // 今日：0 点之后的保存量、以及有多少个不同玩家今天玩过
        LocalDateTime todayStart = LocalDate.now().atStartOfDay();
        QueryWrapper<GameRecord> todayWrapper = new QueryWrapper<>();
        todayWrapper.ge("create_time", todayStart);
        long todayGames = toLong(recordMapper.selectCount(todayWrapper), 0L);

        long todayPlayers = 0L;
        QueryWrapper<GameRecord> todayPlayerWrapper = new QueryWrapper<>();
        todayPlayerWrapper.select("DISTINCT username").ge("create_time", todayStart).ne("username", "");
        try {
            List<Object> names = recordMapper.selectObjs(todayPlayerWrapper);
            todayPlayers = names == null ? 0L : names.size();
        } catch (Exception ignore) {
            // 统计口径的东西不值得让整个首页挂掉，算不出来就当 0
        }

        Map<String, Object> m = new LinkedHashMap<>();
        m.put("playerCount", playerCount);
        m.put("gameCount", gameCount);
        // 全服最高分取自 user.score（历史最高分），和排行榜同源，保证首页数字与榜单第一名一致
        m.put("topScore", topScore());
        m.put("bestPerGame", bestPerGame);
        // 平均分保留一位小数
        m.put("avgScore", gameCount == 0 ? 0.0 : Math.round(scoreSum * 10.0 / gameCount) / 10.0);
        m.put("todayGames", todayGames);
        m.put("todayPlayers", todayPlayers);
        return m;
    }

    /** 全服最高分：直接复用排行榜的第一名，避免"首页显示 120、榜单第一名却是 130"这种不一致 */
    private int topScore() {
        List<User> top = userService.topRank(1);
        if (top.isEmpty() || top.get(0).getScore() == null) {
            return 0;
        }
        return top.get(0).getScore();
    }

    /* ---------------------------------------------------------------
     *  排行榜（复用 UserService，不重复写 SQL）
     * --------------------------------------------------------------- */

    private List<Map<String, Object>> rank(int limit) {
        List<Map<String, Object>> list = new ArrayList<>();
        for (User u : userService.topRank(limit)) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", u.getId());
            m.put("username", u.getUsername());
            m.put("score", u.getScore() == null ? 0 : u.getScore());
            list.add(m);
        }
        return list;
    }

    /* ---------------------------------------------------------------
     *  地图 / 皮肤热度
     * --------------------------------------------------------------- */

    /**
     * 按某个维度统计使用次数，次数倒序
     *
     * @param idCol   标识列（map_id / skin_id）
     * @param nameCol 中文名列（map_name / skin_name）
     * @return [{ id, name, count }, ...]；空表时返回空数组
     *
     * 过滤掉空标识：老版本前端或异常请求可能存下 map_id=''，
     * 这种行不进热度榜，否则会出现一个名字空白的"最受欢迎"。
     */
    private List<Map<String, Object>> heat(String idCol, String nameCol) {
        QueryWrapper<GameRecord> wrapper = new QueryWrapper<>();
        wrapper.select(idCol + " AS gid", nameCol + " AS gname", "COUNT(*) AS cnt")
                .isNotNull(idCol)
                .ne(idCol, "")
                .groupBy(idCol, nameCol)
                .orderByDesc("cnt")
                .last("LIMIT " + MAX_HEAT_ITEMS);

        List<Map<String, Object>> out = new ArrayList<>();
        for (Map<String, Object> row : safeSelectMaps(wrapper)) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", str(pick(row, "gid")));
            m.put("name", str(pick(row, "gname")));
            m.put("count", toLong(pick(row, "cnt"), 0L));
            out.add(m);
        }
        return out;
    }

    /* ---------------------------------------------------------------
     *  "我"的首页数据
     * --------------------------------------------------------------- */

    /**
     * 当前登录用户在首页要看到的东西：我的最高分、全站排名、已存对局数、单局最好成绩
     *
     * @return 没传身份、或这个用户不存在时返回 null（前端据此隐藏这块，不报错）
     */
    private Map<String, Object> me(Long userId, String username) {
        String name = username == null ? "" : username.trim();
        if (userId == null && name.isEmpty()) {
            return null;
        }

        User user = userId == null ? null : userService.findById(userId);
        if (user == null && !name.isEmpty()) {
            user = userService.findByUsername(name);
        }
        if (user == null) {
            return null;
        }

        int score = user.getScore() == null ? 0 : user.getScore();

        // 排名 = 比我分高的人数 + 1。同分的并列，不再按注册先后细分
        // （首页只显示一个名次，按注册时间再拆意义不大）。
        QueryWrapper<User> aheadWrapper = new QueryWrapper<>();
        aheadWrapper.gt("score", score);
        long ahead = toLong(userMapper.selectCount(aheadWrapper), 0L);

        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", user.getId());
        m.put("username", user.getUsername());
        m.put("score", score);
        m.put("rank", ahead + 1);

        // 我的对局战绩直接复用「我的空间」那套统计，保证两处数字口径完全一致
        Map<String, Object> recordStats = recordService.stats(user.getId(), user.getUsername());
        m.put("games", recordStats.get("games"));
        m.put("best", recordStats.get("best"));
        m.put("totalFood", recordStats.get("totalFood"));
        return m;
    }

    /* ---------------------------------------------------------------
     *  小工具
     * --------------------------------------------------------------- */

    /**
     * 查一次聚合结果，出错就返回空列表
     *
     * 首页的"热度""平均分"都是锦上添花的东西，
     * 不该因为一条统计 SQL 出问题就让整个首页白屏。
     */
    private List<Map<String, Object>> safeSelectMaps(QueryWrapper<GameRecord> wrapper) {
        try {
            List<Map<String, Object>> rows = recordMapper.selectMaps(wrapper);
            return rows == null ? new ArrayList<>() : rows;
        } catch (Exception e) {
            return new ArrayList<>();
        }
    }

    /**
     * 从聚合结果里取值
     *
     * 不同数据库/驱动返回的列名大小写可能不一样（cnt / CNT），
     * 这里先按原名取，取不到再忽略大小写找一遍。
     */
    private Object pick(Map<String, Object> row, String key) {
        if (row == null || key == null) {
            return null;
        }
        Object v = row.get(key);
        if (v != null) {
            return v;
        }
        for (Map.Entry<String, Object> e : row.entrySet()) {
            if (e.getKey() != null && e.getKey().equalsIgnoreCase(key)) {
                return e.getValue();
            }
        }
        return null;
    }

    private long toLong(Object v, long fallback) {
        if (v == null) {
            return fallback;
        }
        if (v instanceof Number) {
            return ((Number) v).longValue();
        }
        try {
            return Long.parseLong(String.valueOf(v).trim());
        } catch (NumberFormatException e) {
            return fallback;
        }
    }

    private String str(Object v) {
        return v == null ? "" : String.valueOf(v);
    }
}
