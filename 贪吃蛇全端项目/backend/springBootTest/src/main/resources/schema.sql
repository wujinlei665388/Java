-- ============================================================
--  贪吃蛇项目建表语句
--  由 application.properties 里的 spring.sql.init.mode=always 在
--  每次启动时自动执行；所有语句都是幂等的（IF NOT EXISTS / INSERT IGNORE），
--  所以重复执行不会报错、也不会重复插数据。
-- ============================================================

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

-- 排行榜查询会用到 score 倒序，上面的 idx_score 索引就是给它用的

-- 默认测试账号：admin / 123456
INSERT IGNORE INTO `user` (`username`, `password`) VALUES ('admin', '123456');

-- ============================================================
--  对局记录表 game_record
--  「每局结束后由玩家决定是否保存」——点了保存才往这张表插一条，
--  不点就什么都不写，所以这张表里每一行都代表"玩家主动存下来的那一局"。
--  注意：user 表的 score 是历史最高分（只有刷新纪录才更新），
--        这张表才是每一局的原始流水，两者互不影响。
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
--  和 game_record 一对一（record_id 就是主键）。单独一张表而不是给
--  game_record 加列，是为了两个好处：
--    1) 建表语句是幂等的，老库不用 ALTER 就能平滑升级（MySQL 8 没有
--       ADD COLUMN IF NOT EXISTS，加列会很难做到幂等）；
--    2) 轨迹动辄几十 KB，列表查询不会把它一起捞出来。
--  老记录没有这一行 → 前端显示"这局没存回放"，只有数据可看。
-- ============================================================
CREATE TABLE IF NOT EXISTS `game_replay` (
  `record_id`   BIGINT     NOT NULL COMMENT '关联 game_record.id',
  `data`        MEDIUMTEXT NOT NULL COMMENT '回放轨迹（前端紧凑编码后的 JSON 文本）',
  `steps`       INT        NOT NULL DEFAULT 0 COMMENT '总步数，列表里显示用',
  `create_time` DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录时间',
  PRIMARY KEY (`record_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='对局回放轨迹（一局一行，可缺省）';
