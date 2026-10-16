package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.service.HomeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * 首页接口（前端通过 vite 代理 /api 访问本服务）
 *
 * GET /api/home/summary?limit=5&userId=&username=
 *
 * 为什么首页要单独一个接口：首页上的数字来自好几张表
 * （玩家总数看 user，总局数/平均分/地图皮肤热度看 game_record，
 *   我的排名看 user + game_record），
 * 拆成多个接口就要打好几个来回；这里一次返回，首页只发一个请求。
 *
 * userId / username 都是可选的：
 *   不传 → me 为 null，首页只显示全站数据（游客视角）
 *   传了 → 额外带上"我的排名 / 我的最高分 / 已存几局"
 * 注意这里和 /api/record/* 不一样：这两个参数只是用来**认出你自己**，
 * 拿到的也只有你自己的战绩，不会因此暴露别人的数据。
 */
@RestController
@RequestMapping("/api/home")
public class HomeController {

    @Autowired
    private HomeService homeService;

    /**
     * 首页汇总数据
     *
     * @param limit    排行榜取前几名，默认 5（首页只展示 TOP 5，游戏页要 TOP 10 会另传）
     * @param userId   当前登录用户 id（可选，来自 sessionStorage.snake_uid）
     * @param username 当前登录用户名（可选，来自 sessionStorage.snake_user）
     */
    @GetMapping("/summary")
    public Result<Map<String, Object>> summary(@RequestParam(value = "limit", defaultValue = "5") int limit,
                                              @RequestParam(value = "userId", required = false) Long userId,
                                              @RequestParam(value = "username", required = false) String username) {
        try {
            return Result.ok("ok", homeService.summary(limit, userId, username));
        } catch (Exception e) {
            return Result.error("服务器异常: " + e.getMessage());
        }
    }
}
