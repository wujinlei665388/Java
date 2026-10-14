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
