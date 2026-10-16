package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonInclude;

import java.time.LocalDateTime;

/**
 * 对局记录实体，对应表 game_record
 *
 * 每一行 = 玩家在「游戏结束」时主动点了「保存本局」的一局。
 * 和 User.score 的区别：
 *   User.score  → 历史最高分，只有刷新纪录才会变
 *   GameRecord  → 每一局的原始流水，玩家想存几局就存几局
 *
 * 字段名是驼峰，表字段是下划线，靠 application.properties 里的
 * mybatis-plus.global-config.db-config.table-underline=true 自动映射。
 */
@TableName("game_record")
public class GameRecord {

    /** 主键 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 用户 id（关联 user.id，未登录/取不到时为 null） */
    private Long userId;

    /** 用户名（冗余一份，方便直接按名字查） */
    private String username;

    /** 本局得分 */
    private Integer score;

    /** 本局结束时蛇的长度 */
    private Integer snakeLen;

    /** 本局吃掉的食物个数 */
    private Integer foodCount;

    /** 地图标识 forest / neon / ice */
    private String mapId;

    /** 地图中文名 */
    private String mapName;

    /** 皮肤标识 */
    private String skinId;

    /** 皮肤中文名 */
    private String skinName;

    /** 本局时长（秒，不含暂停时间） */
    private Integer duration;

    /** 保存时间，由数据库默认值生成；返回给前端时格式化成 2026-10-14 09:30:00 */
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime createTime;

    /* ------------------------------------------------------------------
     * 下面三个字段 **不是** game_record 表的列（@TableField(exist = false)），
     * 只是挂在实体上搭个便车：
     *   replay      保存时前端把轨迹塞进来，后端取出来存进 game_replay 表；
     *               存完就置空，绝不回传给前端（否则白白多传几十 KB）
     *   replaySteps 轨迹步数，同样只用于入库
     *   hasReplay   列表接口查完 game_replay 后回填，前端据此决定
     *               「回放」按钮是可点还是显示"这局没存回放"
     * ------------------------------------------------------------------ */

    /** 回放轨迹正文（仅保存接口入参用，不落 game_record 表） */
    @TableField(exist = false)
    @JsonInclude(JsonInclude.Include.NON_NULL)
    private String replay;

    /** 回放总步数（仅保存接口入参用，不落 game_record 表） */
    @TableField(exist = false)
    @JsonInclude(JsonInclude.Include.NON_NULL)
    private Integer replaySteps;

    /** 这局有没有回放（列表接口回填，不落表） */
    @TableField(exist = false)
    @JsonInclude(JsonInclude.Include.NON_NULL)
    private Boolean hasReplay;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public Integer getScore() { return score; }
    public void setScore(Integer score) { this.score = score; }

    public Integer getSnakeLen() { return snakeLen; }
    public void setSnakeLen(Integer snakeLen) { this.snakeLen = snakeLen; }

    public Integer getFoodCount() { return foodCount; }
    public void setFoodCount(Integer foodCount) { this.foodCount = foodCount; }

    public String getMapId() { return mapId; }
    public void setMapId(String mapId) { this.mapId = mapId; }

    public String getMapName() { return mapName; }
    public void setMapName(String mapName) { this.mapName = mapName; }

    public String getSkinId() { return skinId; }
    public void setSkinId(String skinId) { this.skinId = skinId; }

    public String getSkinName() { return skinName; }
    public void setSkinName(String skinName) { this.skinName = skinName; }

    public Integer getDuration() { return duration; }
    public void setDuration(Integer duration) { this.duration = duration; }

    public LocalDateTime getCreateTime() { return createTime; }
    public void setCreateTime(LocalDateTime createTime) { this.createTime = createTime; }

    public String getReplay() { return replay; }
    public void setReplay(String replay) { this.replay = replay; }

    public Integer getReplaySteps() { return replaySteps; }
    public void setReplaySteps(Integer replaySteps) { this.replaySteps = replaySteps; }

    public Boolean getHasReplay() { return hasReplay; }
    public void setHasReplay(Boolean hasReplay) { this.hasReplay = hasReplay; }
}
