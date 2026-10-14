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

-- ============================================================
--  对局记录表 game_record
--  「每局结束后由玩家决定是否保存」——玩家点了保存才会插一条，
--  不点就不写。user.score 是历史最高分，这张表是每一局的流水。
-- ============================================================
CREATE TABLE IF NOT EXISTS `game_record` (
  `id`          BIGINT      NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id`     BIGINT      DEFAULT NULL COMMENT '用户 id（关联 user.id，可为空）',
  `username`    VARCHAR(20) NOT NULL COMMENT '用户名（冗余一份，方便直接查）',
  `score`       INT         NOT NULL DEFAULT 0 COMMENT '本局得分',
  `snake_len`   INT         NOT NULL DEFAULT 3 COMMENT '本局结束时蛇的长度',
  `food_count`  INT         NOT NULL DEFAULT 0 COMMENT '本局吃掉的食物个数',
  `map_id`      VARCHAR(20) NOT NULL DEFAULT '' COMMENT '地图标识 forest/neon/ice',
  `map_name`    VARCHAR(40) NOT NULL DEFAULT '' COMMENT '地图中文名',
  `skin_id`     VARCHAR(20) NOT NULL DEFAULT '' COMMENT '皮肤标识',
  `skin_name`   VARCHAR(40) NOT NULL DEFAULT '' COMMENT '皮肤中文名',
  `duration`    INT         NOT NULL DEFAULT 0 COMMENT '本局时长（秒，不含暂停）',
  `create_time` DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '保存时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_time` (`user_id`, `create_time`),
  KEY `idx_user_score` (`user_id`, `score`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='对局记录表（玩家主动保存的每一局）';

-- ============================================================
--  对局回放轨迹表 game_replay
--  和 game_record 一对一（record_id 即主键，可缺省）。
--  单独一张表而不是给 game_record 加列，是为了：
--    1) 建表幂等，老库不用 ALTER 就能升级（MySQL 8 没有
--       ADD COLUMN IF NOT EXISTS，加列做不到幂等）；
--    2) 轨迹动辄几十 KB，列表查询不会连带捞出来。
--  没有这一行的对局 = 保存时还没录轨迹，前端显示"这局没存回放"。
-- ============================================================
CREATE TABLE IF NOT EXISTS `game_replay` (
  `record_id`   BIGINT     NOT NULL COMMENT '关联 game_record.id',
  `data`        MEDIUMTEXT NOT NULL COMMENT '回放轨迹（前端紧凑编码后的 JSON 文本）',
  `steps`       INT        NOT NULL DEFAULT 0 COMMENT '总步数，列表里显示用',
  `create_time` DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录时间',
  PRIMARY KEY (`record_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='对局回放轨迹（一局一行，可缺省）';

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
-- 某个玩家保存过的对局（按时间倒序）
-- SELECT id, score, snake_len, map_name, skin_name, duration, create_time
--   FROM `game_record` WHERE username = 'admin' ORDER BY create_time DESC;
-- 谁的得分最高（对局流水维度，和排行榜的最高分不是一回事）
-- SELECT username, MAX(score) AS best, COUNT(*) AS games
--   FROM `game_record` GROUP BY username ORDER BY best DESC LIMIT 10;
