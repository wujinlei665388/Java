-- ============================================================
--  贪吃蛇项目数据库脚本  snake_game.sql
--  MySQL 8.0 | 用户名: root | 密码: 123456
-- ------------------------------------------------------------
--  使用方式（推荐第 1 种，通常你什么都不用做）：
--   1. 后端 application.properties 已配置：
--        · createDatabaseIfNotExist=true  → 库不存在时自动建库
--        · spring.sql.init.mode=always    → 启动时自动执行 schema.sql 建表
--      所以直接启动后端即可，本文件仅作备份/手动执行用。
--   2. 想手动执行：在 cmd 里运行（注意路径按实际改）：
--        "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -uroot -p123456 < snake_game.sql
-- ------------------------------------------------------------
--  ⚠ 本机环境每次重置后数据库可能被清空，重置后两种恢复方式：
--    A. 直接启动后端（会自动建库建表，但用户数据会丢）
--    B. 用 mysqldump 备份文件恢复：
--         恢复脚本已放在 scripts/ 目录，见 restore-db.cmd
-- ============================================================

CREATE DATABASE IF NOT EXISTS `snake_game`
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_general_ci;

USE `snake_game`;

CREATE TABLE IF NOT EXISTS `user` (
  `id`       BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
  `username` VARCHAR(20)  NOT NULL COMMENT '用户名',
  `password` VARCHAR(100) NOT NULL COMMENT '密码（教学项目为明文，生产需加密）',
  `score`    INT          NOT NULL DEFAULT 0 COMMENT '历史最高分',
  `create_time` DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`),
  KEY `idx_score` (`score`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- 默认测试账号：admin / 123456
INSERT IGNORE INTO `user` (`username`, `password`) VALUES ('admin', '123456');

-- ------------------------------------------------------------
--  常用查询（方便你在 Navicat / 命令行里手查）
-- ------------------------------------------------------------
-- 查看全部用户
-- SELECT * FROM `user`;
-- 查看排行榜前 10
-- SELECT username, score FROM `user` ORDER BY score DESC, id ASC LIMIT 10;
-- 手动加一个玩家
-- INSERT INTO `user` (`username`,`password`) VALUES ('player1','abc123');
-- 手动改最高分
-- UPDATE `user` SET score = 999 WHERE username = 'player1';
