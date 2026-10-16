package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 用户接口（前端通过 vite 代理 /api 访问本服务）
 *
 * POST /api/user/login     { username, password }
 * POST /api/user/register  { username, password }
 * POST /api/user/score     { userId, score }   保存最高分（取较大值）
 * GET  /api/user/info?username=xxx             查询单个用户信息（含最高分）
 * GET  /api/user/rank?limit=10                 排行榜（按最高分倒序）
 */
@RestController
@RequestMapping("/api/user")
public class UserController {

    @Autowired
    private UserService userService;

    /** 把 User 转成前端需要的结构（不暴露密码） */
    private Map<String, Object> toView(User user) {
        Map<String, Object> m = new HashMap<>();
        m.put("id", user.getId());
        m.put("username", user.getUsername());
        m.put("score", user.getScore() == null ? 0 : user.getScore());
        return m;
    }

    @PostMapping("/login")
    public Result<Map<String, Object>> login(@RequestBody Map<String, String> body) {
        try {
            String username = body.getOrDefault("username", "").trim();
            String password = body.getOrDefault("password", "");
            if (username.isEmpty() || password.isEmpty()) {
                return Result.fail("用户名或密码不能为空");
            }
            User user = userService.login(username, password);
            return Result.ok("登录成功", toView(user));
        } catch (IllegalArgumentException e) {
            return Result.fail(e.getMessage());
        } catch (Exception e) {
            return Result.error("服务器异常: " + e.getMessage());
        }
    }

    @PostMapping("/register")
    public Result<Map<String, Object>> register(@RequestBody Map<String, String> body) {
        try {
            String username = body.getOrDefault("username", "").trim();
            String password = body.getOrDefault("password", "");
            if (!username.matches("[A-Za-z0-9_]{3,20}")) {
                return Result.fail("用户名需为 3-20 位字母/数字/下划线");
            }
            if (password.length() < 6) {
                return Result.fail("密码至少 6 位");
            }
            User user = userService.register(username, password);
            return Result.ok("注册成功", toView(user));
        } catch (IllegalArgumentException e) {
            return Result.fail(e.getMessage());
        } catch (Exception e) {
            return Result.error("服务器异常: " + e.getMessage());
        }
    }

    /** 保存最高分：只在比库里记录更大时才更新 */
    @PostMapping("/score")
    public Result<Map<String, Object>> saveScore(@RequestBody Map<String, Object> body) {
        try {
            Object idObj = body.get("userId");
            Object scoreObj = body.get("score");
            if (idObj == null) {
                return Result.fail("缺少 userId");
            }
            Long userId = Long.valueOf(String.valueOf(idObj));
            int score = scoreObj == null ? 0 : Integer.parseInt(String.valueOf(scoreObj));
            User user = userService.updateScore(userId, score);
            if (user == null) {
                return Result.fail("用户不存在");
            }
            return Result.ok("最高分已更新", toView(user));
        } catch (NumberFormatException e) {
            return Result.fail("参数格式错误");
        } catch (Exception e) {
            return Result.error("服务器异常: " + e.getMessage());
        }
    }

    /** 查询用户信息（含最高分） */
    @GetMapping("/info")
    public Result<Map<String, Object>> info(@RequestParam("username") String username) {
        try {
            User user = userService.findByUsername(username.trim());
            if (user == null) {
                return Result.fail("用户不存在");
            }
            return Result.ok("ok", toView(user));
        } catch (Exception e) {
            return Result.error("服务器异常: " + e.getMessage());
        }
    }

    /** 排行榜：按最高分倒序，只返回前 limit 名 */
    @GetMapping("/rank")
    public Result<List<Map<String, Object>>> rank(@RequestParam(value = "limit", defaultValue = "10") int limit) {
        try {
            if (limit <= 0 || limit > 100) {
                limit = 10;
            }
            List<Map<String, Object>> list = userService.topRank(limit)
                    .stream().map(this::toView).toList();
            return Result.ok("ok", list);
        } catch (Exception e) {
            return Result.error("服务器异常: " + e.getMessage());
        }
    }
}
