package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonFormat;

import java.time.LocalDateTime;

/**
 * 对局回放轨迹实体，对应表 game_replay
 *
 * 一局对局（game_record 的一行）最多对应一行轨迹，用 record_id 做主键，
 * 也就是说它和 game_record 是"一对一、可缺省"的关系：
 *   - 有轨迹 → 前端可以点「回放」，像放录像一样重演那一局
 *   - 没有   → 老记录（这个功能上线前保存的），只能看数据
 *
 * data 里装的是前端紧凑编码后的 JSON 文本，后端只当字符串存取，
 * 不做结构解析 —— 回放怎么渲染是前端的事，后端不该跟着一起改。
 */
@TableName("game_replay")
public class GameReplay {

    /** 主键，同时也是 game_record.id（没有自增，插入时必须显式带上） */
    @TableId(type = IdType.INPUT)
    private Long recordId;

    /** 轨迹正文（JSON 文本，紧凑编码：几百步也就几 KB） */
    private String data;

    /** 总步数，列表里显示"回放 · N 步"用 */
    private Integer steps;

    /** 记录时间，由数据库默认值生成 */
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime createTime;

    public GameReplay() {
    }

    public GameReplay(Long recordId, String data, Integer steps) {
        this.recordId = recordId;
        this.data = data;
        this.steps = steps;
    }

    public Long getRecordId() { return recordId; }
    public void setRecordId(Long recordId) { this.recordId = recordId; }

    public String getData() { return data; }
    public void setData(String data) { this.data = data; }

    public Integer getSteps() { return steps; }
    public void setSteps(Integer steps) { this.steps = steps; }

    public LocalDateTime getCreateTime() { return createTime; }
    public void setCreateTime(LocalDateTime createTime) { this.createTime = createTime; }
}
