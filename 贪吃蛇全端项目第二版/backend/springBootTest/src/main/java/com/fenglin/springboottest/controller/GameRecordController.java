package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.entity.GameRecord;
import com.fenglin.springboottest.entity.GameReplay;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.service.GameRecordService;
import com.fenglin.springboottest.service.GameReplayService;
import com.fenglin.springboottest.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 对局记录接口（前端通过 vite 代理 /api 访问本服务）
 *
 * POST   /api/record/save                    保存一局（游戏结束时玩家点「保存本局」才调用，
 *                                             请求体里可以带 replay 轨迹，不带就只存数据）
 * GET    /api/record/list?userId=&username=&limit=20    我的对局，按时间倒序（带 hasReplay 标记）
 * GET    /api/record/stats?userId=&username=           我的对局统计
 * GET    /api/record/{id}/replay?userId=&username=    取某一局的回放轨迹
 * DELETE /api/record/{id}?userId=&username=            删除自己的一条记录（连带删掉回放轨迹）
 *
 * 约定：userId / username 至少传一个，后端据此把数据限定在"本人"范围内，
 *       所以这个接口查不到别人的对局。
 */
@RestController
@RequestMapping("/api/record")
public class GameRecordController {

    @Autowired
    private GameRecordService recordService;

    @Autowired
    private GameReplayService replayService;

    @Autowired
    private UserService userService;

    /** 用户名最长 20（和 user 表一致），地图/皮肤名字段也都有上限，超了截断 */
    private static final int MAX_USERNAME = 20;
    private static final int MAX_ID_FIELD = 20;
    private static final int MAX_NAME_FIELD = 40;
    /** 单局时长上限 24 小时、得分上限一千万，防脏数据 */
    private static final int MAX_DURATION = 24 * 3600;
    private static final int MAX_SCORE = 10_000_000;
    /** 棋盘只有 20×20=400 格，蛇长和食物数不可能超过它 */
    private static final int MAX_CELL = 400;
    /**
     * 回放轨迹的长度上限（字符数）。一局几千步也就几十 KB，
     * 给到 1.5MB 已经很宽松了；超过这个量基本是客户端出了问题，
     * 这种情况只丢轨迹、不影响这一局的其它数据落库。
     */
    private static final int MAX_REPLAY_CHARS = 1_500_000;

    /**
     * 保存一局对局记录
     *
     * 请求体（都是前端游戏结束时手上的数据）：
     * { userId, username, score, snakeLen, foodCount,
     *   mapId, mapName, skinId, skinName, duration,
     *   replay, replaySteps }   ← 后两个可选，是回放轨迹（前端紧凑编码的 JSON 文本）
     * id 和 createTime 由后端/数据库生成，前端传了也会被忽略。
     */
    @PostMapping("/save")
    public Result<GameRecord> save(@RequestBody GameRecord body) {
        try {
            String username = body.getUsername() == null ? "" : body.getUsername().trim();
            if (username.isEmpty()) {
                return Result.fail("缺少 username，无法确定这是谁的对局");
            }
            if (username.length() > MAX_USERNAME) {
                username = username.substring(0, MAX_USERNAME);
            }

            // 传了 userId 就以数据库里的用户名为准，避免前端随手改成别人的名字
            Long userId = body.getUserId();
            if (userId != null) {
                User u = userService.findById(userId);
                if (u != null) {
                    username = u.getUsername();
                }
            }

            // 回放轨迹：可选。要么原样收下，要么整段丢掉（不截一半，截一半的回放会放歪）
            String replay = body.getReplay();
            boolean replayGiven = replay != null && !replay.trim().isEmpty();
            boolean replayDropped = replayGiven && replay.length() > MAX_REPLAY_CHARS;
            if (!replayGiven || replayDropped) {
                replay = null;
            }

            GameRecord record = new GameRecord();
            record.setUserId(userId);
            record.setUsername(username);
            record.setScore(clamp(body.getScore(), 0, MAX_SCORE, 0));
            record.setSnakeLen(clamp(body.getSnakeLen(), 3, MAX_CELL, 3));
            record.setFoodCount(clamp(body.getFoodCount(), 0, MAX_CELL, 0));
            record.setMapId(cut(body.getMapId(), MAX_ID_FIELD));
            record.setMapName(cut(body.getMapName(), MAX_NAME_FIELD));
            record.setSkinId(cut(body.getSkinId(), MAX_ID_FIELD));
            record.setSkinName(cut(body.getSkinName(), MAX_NAME_FIELD));
            record.setDuration(clamp(body.getDuration(), 0, MAX_DURATION, 0));
            // 这两个不是 game_record 的列，会被 Service 取出来写进 game_replay 表
            record.setReplay(replay);
            record.setReplaySteps(replay == null ? null : clamp(body.getReplaySteps(), 0, MAX_SCORE, 0));

            GameRecord saved = recordService.save(record);

            if (replayDropped) {
                return Result.ok("本局已保存（回放轨迹过长，未一并保存）", saved);
            }
            return Result.ok(replay != null ? "本局已保存，可以回放" : "本局已保存", saved);
        } catch (Exception e) {
            return Result.error("服务器异常: " + e.getMessage());
        }
    }

    /** 我的对局：按保存时间倒序，默认取最近 20 局 */
    @GetMapping("/list")
    public Result<List<GameRecord>> list(@RequestParam(value = "userId", required = false) Long userId,
                                         @RequestParam(value = "username", required = false) String username,
                                         @RequestParam(value = "limit", defaultValue = "20") int limit) {
        try {
            if (limit <= 0 || limit > 100) {
                limit = 20;
            }
            return Result.ok("ok", recordService.listMine(userId, username, limit));
        } catch (IllegalArgumentException e) {
            return Result.fail(e.getMessage());
        } catch (Exception e) {
            return Result.error("服务器异常: " + e.getMessage());
        }
    }

    /** 我的对局统计：总局数 / 最高分 / 平均分 / 最长蛇 / 总时长 / 总食物 */
    @GetMapping("/stats")
    public Result<Map<String, Object>> stats(@RequestParam(value = "userId", required = false) Long userId,
                                             @RequestParam(value = "username", required = false) String username) {
        try {
            return Result.ok("ok", recordService.stats(userId, username));
        } catch (IllegalArgumentException e) {
            return Result.fail(e.getMessage());
        } catch (Exception e) {
            return Result.error("服务器异常: " + e.getMessage());
        }
    }

    /** 删除自己的一条对局记录 */
    @DeleteMapping("/{id}")
    public Result<Object> delete(@PathVariable("id") Long id,
                                 @RequestParam(value = "userId", required = false) Long userId,
                                 @RequestParam(value = "username", required = false) String username) {
        try {
            if (recordService.deleteMine(id, userId, username)) {
                return Result.ok("已删除这条对局", null);
            }
            return Result.fail("这条记录不存在，或者不属于你");
        } catch (IllegalArgumentException e) {
            return Result.fail(e.getMessage());
        } catch (Exception e) {
            return Result.error("服务器异常: " + e.getMessage());
        }
    }

    /**
     * 取某一局的回放轨迹
     * GET /api/record/{id}/replay?userId=&username=
     *
     * 返回 { record: {...本局数据...}, replay: "前端编码的轨迹文本", steps: 128 }
     * replay 是字符串，前端自己 JSON.parse —— 后端不掺和渲染格式。
     * 归属校验在这儿做：不是自己的记录直接拒绝，所以拿不到别人的回放。
     */
    @GetMapping("/{id}/replay")
    public Result<Map<String, Object>> replay(@PathVariable("id") Long id,
                                              @RequestParam(value = "userId", required = false) Long userId,
                                              @RequestParam(value = "username", required = false) String username) {
        try {
            GameRecord record = recordService.findMine(id, userId, username);
            if (record == null) {
                return Result.fail("这条对局不存在，或者不属于你");
            }
            GameReplay replay = replayService.find(id);
            if (replay == null || replay.getData() == null || replay.getData().trim().isEmpty()) {
                return Result.fail("这一局保存时还没有回放，只能看数据");
            }
            Map<String, Object> data = new LinkedHashMap<>();
            data.put("record", record);
            data.put("replay", replay.getData());
            data.put("steps", replay.getSteps() == null ? 0 : replay.getSteps());
            return Result.ok("ok", data);
        } catch (IllegalArgumentException e) {
            return Result.fail(e.getMessage());
        } catch (Exception e) {
            return Result.error("服务器异常: " + e.getMessage());
        }
    }

    /* ---------------- 小工具 ---------------- */

    /** 数值兜底：null 用默认值，越界夹到边界 */
    private int clamp(Integer value, int min, int max, int fallback) {
        if (value == null) {
            return fallback;
        }
        int v = value;
        if (v < min) v = min;
        if (v > max) v = max;
        return v;
    }

    /** 字符串兜底：null 变空串，超长截断 */
    private String cut(String value, int max) {
        if (value == null) {
            return "";
        }
        String v = value.trim();
        return v.length() > max ? v.substring(0, max) : v;
    }
}
