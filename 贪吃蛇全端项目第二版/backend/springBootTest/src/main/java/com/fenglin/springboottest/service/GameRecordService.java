package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.fenglin.springboottest.entity.GameRecord;
import com.fenglin.springboottest.mapper.GameRecordMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 对局记录服务：保存 / 查询 / 统计 / 删除
 *
 * 设计要点：一张表里可能有多个玩家的记录，所以所有查询都带"归属过滤"，
 * 用 user_id 或 username 限定在本人范围内，不提供"查所有人记录"的接口。
 * 两个条件之间用 and(...) 包一层，避免生成 `id=? AND a=? OR b=?`
 * 这种优先级错误的 SQL。
 */
@Service
public class GameRecordService {

    @Autowired
    private GameRecordMapper recordMapper;

    @Autowired
    private GameReplayService replayService;

    /** 最多一次统计多少条，防止某天数据暴涨把内存吃光 */
    private static final int STATS_SCAN_LIMIT = 500;

    /**
     * 保存一局对局记录
     *
     * 如果这一局带了回放轨迹（record.replay 非空），会一并写进 game_replay 表。
     * 轨迹是"搭便车"从 record 上带进来的（不是 game_record 的列），
     * 落库后不回传，免得白白把几十 KB 再传回前端一遍。
     *
     * @return 落库后的完整记录（含数据库生成的 id 和 create_time）
     */
    public GameRecord save(GameRecord record) {
        String replay = record.getReplay();
        Integer replaySteps = record.getReplaySteps();

        recordMapper.insert(record);
        GameRecord saved = recordMapper.selectById(record.getId());

        if (saved != null) {
            // 存了轨迹才写轨迹表；没存（比如老版本前端）就只留记录本身
            replayService.save(saved.getId(), replay, replaySteps);
        }
        return saved;
    }

    /**
     * 查询某个玩家最近的对局（按保存时间倒序）
     * 返回前会给每条补上 hasReplay / replaySteps，前端不用再逐条问后端
     */
    public List<GameRecord> listMine(Long userId, String username, int limit) {
        QueryWrapper<GameRecord> wrapper = mine(userId, username);
        wrapper.orderByDesc("create_time").orderByDesc("id").last("LIMIT " + limit);
        List<GameRecord> list = recordMapper.selectList(wrapper);
        markHasReplay(list);
        return list;
    }

    /** 查一条属于本人的对局（回放接口用它做归属校验，查不到就别给回放） */
    public GameRecord findMine(Long id, Long userId, String username) {
        if (id == null) {
            return null;
        }
        QueryWrapper<GameRecord> wrapper = mine(userId, username);
        wrapper.eq("id", id);
        return recordMapper.selectOne(wrapper);
    }

    /** 给列表批量打上"有没有回放"的标记，一次查询搞定，不做 N+1 */
    private void markHasReplay(List<GameRecord> list) {
        if (list == null || list.isEmpty()) {
            return;
        }
        List<Long> ids = new ArrayList<>(list.size());
        for (GameRecord r : list) {
            if (r.getId() != null) {
                ids.add(r.getId());
            }
        }
        Map<Long, Integer> withReplay = replayService.whichHaveReplay(ids);
        for (GameRecord r : list) {
            Integer steps = withReplay.get(r.getId());
            r.setHasReplay(steps != null);
            r.setReplaySteps(steps);
        }
    }

    /**
     * 统计某个玩家的对局概况：总局数 / 最高分 / 平均分 / 最长蛇 / 总时长 / 总食物
     * 直接在 Java 里算，不写聚合 SQL，换数据库也不用改。
     */
    public Map<String, Object> stats(Long userId, String username) {
        QueryWrapper<GameRecord> wrapper = mine(userId, username);
        wrapper.orderByDesc("create_time").last("LIMIT " + STATS_SCAN_LIMIT);
        List<GameRecord> list = recordMapper.selectList(wrapper);

        int games = list.size();
        int best = 0;
        int maxLen = 0;
        int totalDuration = 0;
        int totalFood = 0;
        long sumScore = 0;
        for (GameRecord r : list) {
            int s = r.getScore() == null ? 0 : r.getScore();
            sumScore += s;
            if (s > best) best = s;
            if (r.getSnakeLen() != null && r.getSnakeLen() > maxLen) maxLen = r.getSnakeLen();
            if (r.getDuration() != null) totalDuration += r.getDuration();
            if (r.getFoodCount() != null) totalFood += r.getFoodCount();
        }

        Map<String, Object> m = new LinkedHashMap<>();
        m.put("games", games);
        m.put("best", best);
        // 平均分保留一位小数
        m.put("avgScore", games == 0 ? 0 : Math.round(sumScore * 10.0 / games) / 10.0);
        m.put("maxLen", maxLen);
        m.put("totalDuration", totalDuration);
        m.put("totalFood", totalFood);
        return m;
    }

    /**
     * 删除一条对局记录（只能删自己的）
     * 删掉了的话，顺手把它对应的回放轨迹也清掉，不留孤儿数据
     * @return true = 删掉了；false = 不存在或不属于这个玩家
     */
    public boolean deleteMine(Long id, Long userId, String username) {
        QueryWrapper<GameRecord> wrapper = mine(userId, username);
        wrapper.eq("id", id);
        boolean removed = recordMapper.delete(wrapper) > 0;
        if (removed) {
            replayService.delete(id);
        }
        return removed;
    }

    /** 归属条件：user_id 或 username 命中即可（两个都传就是"或"的关系） */
    private QueryWrapper<GameRecord> mine(Long userId, String username) {
        String name = username == null ? "" : username.trim();
        // 两个都没传就等于"没限定是谁"，那就不该查——直接报错，别把全表数据漏出去
        if (userId == null && name.isEmpty()) {
            throw new IllegalArgumentException("缺少 userId 或 username，无法定位到具体玩家");
        }
        QueryWrapper<GameRecord> wrapper = new QueryWrapper<>();
        wrapper.and(w -> {
            boolean hasUser = userId != null;
            boolean hasName = !name.isEmpty();
            if (hasUser) {
                w.eq("user_id", userId);
            }
            if (hasName) {
                if (hasUser) {
                    w.or();
                }
                w.eq("username", name);
            }
        });
        return wrapper;
    }
}
