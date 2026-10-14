package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.mapper.UserMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 用户服务：注册 / 登录 / 最高分 / 排行榜
 *
 * ⚠ 说明：密码目前是明文存储（教学演示项目）。
 *    如果要用于真实场景，请改成 BCrypt 等哈希算法。
 */
@Service
public class UserService {

    @Autowired
    private UserMapper userMapper;

    /**
     * 注册：用户名已存在则失败
     * @return 注册成功的 User（含自增 id）
     */
    public User register(String username, String password) {
        if (findByUsername(username) != null) {
            throw new IllegalArgumentException("用户名已存在");
        }
        User user = new User();
        user.setUsername(username);
        user.setPassword(password);
        user.setScore(0);
        userMapper.insert(user);
        return user;
    }

    /**
     * 登录：校验用户名密码
     */
    public User login(String username, String password) {
        User user = findByUsername(username);
        if (user == null) {
            throw new IllegalArgumentException("用户不存在");
        }
        if (!user.getPassword().equals(password)) {
            throw new IllegalArgumentException("密码错误");
        }
        return user;
    }

    /**
     * 更新最高分（只在传入分数更大时才写库，避免无意义 UPDATE）
     * @return 更新后的 User；用户不存在返回 null
     */
    public User updateScore(Long userId, int score) {
        User user = userMapper.selectById(userId);
        if (user == null) {
            return null;
        }
        if (user.getScore() == null || score > user.getScore()) {
            user.setScore(score);
            userMapper.updateById(user);
        }
        return user;
    }

    /**
     * 排行榜：按最高分倒序取前 limit 名（分数相同按 id 升序，先注册的排前面）
     */
    public List<User> topRank(int limit) {
        QueryWrapper<User> wrapper = new QueryWrapper<>();
        wrapper.orderByDesc("score").orderByAsc("id").last("LIMIT " + limit);
        return userMapper.selectList(wrapper);
    }

    public User findByUsername(String username) {
        QueryWrapper<User> wrapper = new QueryWrapper<>();
        wrapper.eq("username", username);
        return userMapper.selectOne(wrapper);
    }
}
