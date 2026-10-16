package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.fenglin.springboottest.entity.GameReplay;
import com.fenglin.springboottest.mapper.GameReplayMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 对局回放服务：存取 / 批量判断 / 删除
 *
 * 这里刻意只做"字符串搬运"：data 是前端编码好的一段 JSON 文本，
 * 后端不解析它的结构。这样将来回放格式升级（比如加了倍速标记、
 * 加了障碍动画），后端一行都不用改。
 */
@Service
public class GameReplayService {

    @Autowired
    private GameReplayMapper replayMapper;

    /**
     * 存一局回放。同一局重复保存就覆盖，不会插出第二条。
     * @param recordId game_record 的主键
     * @param data     轨迹正文（为空则什么都不做）
     * @param steps    总步数（可为空，空则记 0）
     */
    public void save(Long recordId, String data, Integer steps) {
        if (recordId == null || data == null || data.trim().isEmpty()) {
            return;
        }
        // 先删后插：record_id 是主键，重复保存时覆盖最稳妥
        replayMapper.deleteById(recordId);
        replayMapper.insert(new GameReplay(recordId, data, steps == null ? 0 : steps));
    }

    /** 取一局的轨迹，没有就返回 null（= 这局存的时候还没录轨迹） */
    public GameReplay find(Long recordId) {
        if (recordId == null) {
            return null;
        }
        return replayMapper.selectById(recordId);
    }

    /**
     * 批量判断这批对局里哪些有回放
     * @return recordId -> 总步数
     */
    public Map<Long, Integer> whichHaveReplay(List<Long> recordIds) {
        Map<Long, Integer> result = new HashMap<>();
        if (recordIds == null || recordIds.isEmpty()) {
            return result;
        }
        QueryWrapper<GameReplay> wrapper = new QueryWrapper<>();
        wrapper.select("record_id", "steps").in("record_id", recordIds);
        List<GameReplay> list = replayMapper.selectList(wrapper);
        if (list == null) {
            return result;
        }
        for (GameReplay r : list) {
            if (r.getRecordId() != null) {
                result.put(r.getRecordId(), r.getSteps() == null ? 0 : r.getSteps());
            }
        }
        return result;
    }

    /** 删掉一局的轨迹（记录被删时级联清理，别留孤儿行） */
    public void delete(Long recordId) {
        if (recordId != null) {
            replayMapper.deleteById(recordId);
        }
    }
}
