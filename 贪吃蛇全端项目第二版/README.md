# 贪吃蛇全栈项目  SNAKE GAME

一个「贪吃蛇主题」的登录 / 注册 / 游戏系统，前后端分离。

- **前端**：Vue 3 + Vite + Vue Router + Axios
- **后端**：Spring Boot 3.4.5 + MyBatis-Plus 3.5.7
- **数据库**：MySQL 8.0（库名 `snake_game`，账号 `root` / `123456`）

---

## 一、最快上手（推荐）

**直接双击 `scripts\start.cmd`**，脚本会自动：

1. 检查 MySQL 是否在运行（没开就尝试启动服务）
2. 编译后端（`target` 被删了也没关系，会自动重新编译）
3. 启动后端 → 端口 **8080**
4. 启动前端（`node_modules` 被删了会自动 `npm install`）→ 端口 **5173**
5. 自动打开浏览器

等两个黑窗口都出现「就绪」提示后，浏览器访问：**http://127.0.0.1:5173/**

**停止**：双击 `scripts\stop.cmd`（或直接关掉那两个黑窗口）

**测试账号**：`admin` / `123456`

---

## 二、手动启动（想自己敲命令时）

### 后端
```bash
cd backend/springBootTest

# 1. 编译
mvn -o clean compile

# 2. 把运行时依赖 jar 拷到 target\lib
mvn -o org.apache.maven.plugins:maven-dependency-plugin:3.5.0:copy-dependencies \
     -DoutputDirectory=target/lib -DincludeScope=runtime

# 3. 启动（注意 Windows 下 classpath 分隔符是分号，* 由 java 自己展开）
java -cp "target/classes;target/lib/*" com.fenglin.springboottest.SpringBootTestApplication
```

> 也可以在 IDEA 里直接运行 `SpringBootTestApplication` 主类。
> 手工启动时建议先 `set "SERVER__PORT="`（或 `env -u SERVER__PORT -u SERVER__HOST`），
> 否则系统里那个 `SERVER__PORT` 环境变量会让后端抢错端口，详见 `AI-START-HERE.md` 第 2 节。

### 前端
```bash
cd frontend
npm install          # 首次或 node_modules 被删后需要
npm run dev          # 或 npm run build 打包
```

---

## 三、项目结构

```
贪吃蛇全端项目/
├── frontend/              Vue3 前端
│   └── src/
│       ├── views/Home.vue         首页（地图选择 / 皮肤选择 / 玩法 / 排行榜 / 我的空间入口）
│       ├── views/Login.vue        登录页
│       ├── views/Register.vue     注册页
│       ├── views/Game.vue         游戏页（排行榜 + 地图切换 + 皮肤弹层 + 对局保存 / 轨迹录制）
│       ├── views/MySpace.vue      ★ 我的空间（皮肤库 + 对局回放，两个功能合一个主页）
│       ├── game/maps.js           ★ 三种地图配置（机制 + 纯色基础下的配色）
│       ├── game/skins.js          ★ 十一款皮肤配置（配色 / 底板图案 / 蛇与食物造型）
│       ├── game/render.js         绘制层（棋盘图案 / 蛇身造型 / 食物造型，共用）
│       ├── game/replay.js         ★ 回放轨迹（录制 / 编解码 / 按步重建 / 演示轨迹）
│       ├── components/BgSnake.vue 背景装饰蛇（各页面共用）
│       ├── components/ReplayBoard.vue ★ 画布播放器（皮肤活预览 + 对局回放共用）
│       ├── api/request.js         axios 实例 + 响应拦截（user / record 共用）
│       ├── api/user.js            用户接口封装
│       └── api/record.js          对局记录 + 回放接口封装
├── backend/springBootTest/       SpringBoot 后端
├── screenshots/                  页面截图（0-首页 / 1-登录 / 2-注册 / 3-游戏 / 4~6-三种地图 / 7~10-皮肤 / 11-结束面板保存二选一 / 12-我的对局 / 13~15-我的空间）
├── db-backup/            ★ 数据库独立备份仓（备份文件 / 脚本 / 台账都在这，见它自己的 README.md）
│   ├── snapshots/manual/         手动备份（永久保留）
│   ├── snapshots/auto/           自动快照（每次启动自动存，只留最近 10 份）
│   ├── snapshots/latest/         最新一份的固定副本
│   ├── backup-db.cmd             手动备份
│   ├── restore-db.cmd            手动恢复
│   ├── list-backups.cmd          查看备份仓和数据库现状
│   └── auto-backup.cmd           启动自检 + 自动快照（start.cmd 调用）
├── sql/
│   └── snake_game.sql    建库脚本（空库模板）
├── scripts/              一键脚本（全部 GBK 编码）
│   ├── start.cmd         启动（含数据库备份自检）
│   ├── stop.cmd          停止
│   ├── init-db.cmd       重置数据库
│   ├── backup-db.cmd     转发到 db-backup\backup-db.cmd
│   └── restore-db.cmd    转发到 db-backup\restore-db.cmd
└── AI-START-HERE.md      给 AI 看的交接文档（含踩坑记录）
```

---

## 四、功能说明

| 页面 | 功能 |
|------|------|
| 首页 `/` | 游戏门面：三种**地图选择卡** + 十一款**皮肤选择卡**（都带实时缩略图预览，换皮肤时地图卡联动刷新）、玩法说明、Top5 排行榜预览；顶部导航可跳地图/皮肤/玩法/排行榜，右上角可进**我的空间** |
| 我的空间 `/my` | **皮肤库 + 对局回放合一个主页**（左右两个标签页切换）：皮肤库里有会自己跑的活预览 + 11 款卡片；对局回放里有统计、每一局的明细、点「回放」能像放录像一样重演那一局 |
| 登录页 | 账号密码登录，背景有装饰性游动贪吃蛇；会提示"登录后进入地图：xx"，可点"换一张"回首页重选 |
| 注册页 | 注册新账号，校验用户名格式（3-20位字母/数字/下划线）和密码长度（≥6位） |
| 游戏页 `/game` | 方向键/WASD 控制，空格暂停；棋盘上方可**随时切换三种地图**（换图即重开一局）；顶栏「皮肤」弹层可**边玩边换肤**（不清局）；每局结束可**决定要不要保存这一局**；顶栏可看**排行榜**、进**我的对局 / 我的空间** |

### 三种风格地图（配置在 `frontend/src/game/maps.js`）

| 地图 | 视觉 | 机制 | 分值 |
|------|------|------|------|
| 经典森林 | 深绿草地 + 霓虹绿 | 无障碍，撞墙或咬到自己结束 | 10 分/个 |
| 霓虹赛博 | 深紫夜色 + 品红/青 | 场内有紫色壁垒方块，撞上即结束 | 15 分/个 |
| 极地冰川 | 深蓝冰川 + 冰青 | **边界可穿越**（从一边出去从对面回来），节奏更快 | 12 分/个 |

想调配色 / 改障碍布局 / 改速度，只改 `maps.js` 一处即可——首页缩略图和游戏页共用同一份配置和绘制函数。

### 十一款皮肤（配置在 `frontend/src/game/skins.js`）

设计原则：**地图管机制，皮肤管外观**——换肤不影响障碍、穿墙、速度、分值，游戏里也能随时换，本局继续。

| 皮肤 | 亮点 |
|------|------|
| 纯色基础 | 不覆盖任何颜色，完全跟随所选地图（默认） |
| 彩虹糖果 | 蛇身七彩循环并缓缓流动 + 圆点底板 + 圆形光球食物 |
| 熔岩烈焰 | 暗红→亮黄渐变蛇身，岩层底板，菱形火种 |
| 黄金矿脉 | 青铜→纯金渐变，金币食物 |
| 极地冰晶 | 半透明冰蓝蛇身高光，斜纹冰面，六棱冰晶 |
| 霓虹描边 | 空心霓虹灯管蛇身 + CRT 扫描线底板 |
| 8bit 像素 | 直角方块蛇，红白机味儿 |
| 星河漫游 | 星空底板 + 靛蓝→青渐变蛇身 + 四角星食物 |
| 樱花物语 | 粉白配色、飘花瓣底板、樱花瓣食物 |
| 电子电路 | 绿色电路板（焊点+走线），芯片方块蛇 |
| 幽影潜行 | 半透明紫蛇，越到尾巴越淡 |

- 选择入口：首页「选择皮肤」区块（每张卡都是该皮肤在当前地图上的实时预览）+ 游戏页顶栏「皮肤：xx」弹层
- 皮肤选中记录在 `localStorage.snake_skin`，和地图一样会被记住
- 加新皮肤：往 `SKINS` 数组里加一个对象即可（palette + pattern + snakeStyle + foodStyle）

### 保存对局（每局结束由你自己决定）

一局结束后，结束面板上会给出两个选择：

| 点哪个 | 会发生什么 |
|--------|-----------|
| **保 存 本 局** | 把这一局写进数据库：得分、蛇长、吃掉的食物个数、地图、皮肤、用时、保存时间。按钮随即变成「已保存 ✓」并锁住，同一局不会重复保存 |
| **不保存 · 再来一局** | **什么请求都不会发**，直接开下一局，库里不留任何痕迹 |

想回顾时，进**「我的空间」**（顶栏入口，首页右上角也有）：上方是统计
（已存局数 / 最高分 / 平均分 / 最长蛇 / 总时长 / 总食物），下方是每一局的明细，
**每一条都能单独删除**。

> 注意区分两个"分数"：
> - 排行榜看的是 `user.score` —— **历史最高分**，每局结束自动更新，只有刷新纪录才变
> - 「我的对局」看的是 `game_record` —— **每一局的流水**，只有你点了保存才留档
>
> 所以保存或不保存，**都不影响排行榜**。

**分数会存进数据库**：一局结束后自动把本局分数同步到后端，
后端只在比历史记录更高时才更新（不会被低分覆盖）。
排行榜按最高分倒序显示前 10 名。

### 我的空间 `/my`（皮肤库 + 对局回放）

**一个主页装了原来散在两处的两个功能**，左上角两个标签页切换：

**① 皮肤库** —— 把「试衣间」和「全部皮肤」放在一起：

- 左边是会**自己跑起来**的预览棋盘：一条蛇在环上绕圈、越绕越长、还边跑边吃食物，
  这样蛇身造型、食物造型、底板图案一眼就能看出差别（不用开局去试）
- 预览底板可以单独换成三张地图中的任意一张（换底板才能看出同一款皮肤在不同地图上的样子）
- 右边是当前皮肤的档案：名字、描述、标签，以及蛇头/蛇身/食物/底板四个色块，
  直白写出「底板图案 / 蛇身造型 / 食物造型」分别是什么
- 下面是全部 11 款皮肤卡，点哪张上面就换成哪张（连预览底板都不用重开）
- 「用这套皮肤开一局」= 把这套皮肤和底板记住，直接进游戏

**② 对局回放** —— 保存过的每一局都能像放录像一样重演：

- 每条记录显示得分、地图、皮肤、长度、食物数、用时、保存时间
- 能回放的带「可回放 N 步」标记，点**「回放」**打开播放器；
  功能上线前存的老记录没有轨迹，标成「仅数据」，回放按钮是灰的
- 播放器有 **播放/暂停、重播、进度条、0.5× / 1× / 2× / 4× 倍速**
- 回放用的是**那一局当时的地图和皮肤**（跟着轨迹走），所以看到的就是当时的画面，
  不受你现在选了什么影响
- 未登录时这一栏会给出登录引导（皮肤库不登录也能逛）

> 轨迹是怎么存的：只记「初始蛇身 + 每一步蛇头走到哪一格 + 食物出现顺序」，
> 整条蛇靠这些就能重建出来，所以一局几千步也就几十 KB，不用给每帧存一张图。

---

## 五、数据库

后端启动时会**自动建库建表**（配置了 `createDatabaseIfNotExist=true`
和启动执行 `schema.sql`），一般你什么都不用做。

需要手动操作时：

| 脚本 | 作用 |
|------|------|
| `scripts\init-db.cmd` | 重置数据库（清空数据重新建表） |
| `db-backup\backup-db.cmd` | 手动备份一份到 `db-backup\snapshots\manual\` |
| `db-backup\restore-db.cmd` | 从备份恢复（列出所有备份让你选，回车=最新一份） |
| `db-backup\list-backups.cmd` | 查看备份仓有哪些备份 + 库里现在是什么数据 |

> 备份、恢复、脚本、台账全部集中在独立的 **`db-backup\`** 文件夹里，
> 口径和机制详见 `db-backup\README.md`。
> `scripts\backup-db.cmd` / `scripts\restore-db.cmd` 还留着，双击它们等于双击上面那两个。

命令行直接连库：
```bash
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -uroot -p123456
```

表结构：
```sql
CREATE TABLE `user` (
  `id`          BIGINT       NOT NULL AUTO_INCREMENT,
  `username`    VARCHAR(20)  NOT NULL,
  `password`    VARCHAR(100) NOT NULL,   -- 教学项目为明文
  `score`       INT          NOT NULL DEFAULT 0,   -- 历史最高分
  `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`),
  KEY `idx_score` (`score`)              -- 给排行榜用
);

-- 对局记录：玩家每局结束点「保存本局」才写一行
CREATE TABLE `game_record` (
  `id`          BIGINT      NOT NULL AUTO_INCREMENT,
  `user_id`     BIGINT      DEFAULT NULL,          -- 关联 user.id
  `username`    VARCHAR(20) NOT NULL,              -- 冗余一份，方便按名字查
  `score`       INT         NOT NULL DEFAULT 0,    -- 本局得分
  `snake_len`   INT         NOT NULL DEFAULT 3,    -- 本局结束时蛇长
  `food_count`  INT         NOT NULL DEFAULT 0,    -- 吃掉的食物个数
  `map_id`      VARCHAR(20) NOT NULL DEFAULT '',   -- forest / neon / ice
  `map_name`    VARCHAR(40) NOT NULL DEFAULT '',   -- 地图中文名
  `skin_id`     VARCHAR(20) NOT NULL DEFAULT '',
  `skin_name`   VARCHAR(40) NOT NULL DEFAULT '',
  `duration`    INT         NOT NULL DEFAULT 0,    -- 本局时长（秒，不含暂停）
  `create_time` DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,  -- 保存时间
  PRIMARY KEY (`id`),
  KEY `idx_user_time` (`user_id`, `create_time`),
  KEY `idx_user_score` (`user_id`, `score`)
);

-- 回放轨迹：一局一条，record_id 就是 game_record.id（跟着记录一起删）
CREATE TABLE `game_replay` (
  `record_id`   BIGINT       NOT NULL,   -- 主键，也是 game_record.id
  `steps`       INT          NOT NULL DEFAULT 0,        -- 录了多少步
  `data`        MEDIUMTEXT,              -- 前端紧凑编码的轨迹文本
  `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`record_id`)
);
```

---

## 六、接口一览

统一响应格式：`{ "code": 200, "msg": "xxx", "data": ... }`

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/user/register` | 注册 |
| POST | `/api/user/login` | 登录 |
| POST | `/api/user/score` | 保存最高分 |
| GET  | `/api/user/info?username=x` | 查用户 |
| GET  | `/api/user/rank?limit=10` | 排行榜 |
| POST | `/api/record/save` | 保存一局对局（点「保存本局」才调，请求体里可带回放轨迹 `replay`） |
| GET  | `/api/record/list?userId=&username=&limit=20` | 我的对局，按时间倒序（每条带 `hasReplay` 标记） |
| GET  | `/api/record/stats?userId=&username=` | 我的对局统计 |
| GET  | `/api/record/{id}/replay?userId=&username=` | 取某一局的回放轨迹（没轨迹会返回 400） |
| DELETE | `/api/record/{id}?userId=&username=` | 删除自己的一条对局（连回放一起删） |

> `/api/record/*` 的 `userId` / `username` **至少传一个**，两个都不传会被拒（400）——
> 这是有意的，避免有人不带身份就把全表对局捞走。删别人的记录也会被拒。

前端通过 vite 代理访问（`/api` → `http://localhost:8080`），所以不存在跨域问题。
代理配置在 `frontend/vite.config.js`。

---

## 七、换一台电脑 / 重置后怎么办

1. 双击 `scripts\start.cmd` —— 它会自动处理编译和依赖安装，
   启动前还会自动把数据库现状快照一份到 `db-backup\snapshots\auto\`
2. 想找回之前的玩家数据：
   ```
   双击 db-backup\restore-db.cmd     （列出所有备份，直接回车用最新一份）
   ```

> **小提示**：这台电脑每次开机都会重置，`node_modules`、`target`
> 和 MySQL 里的玩家数据都可能被清掉。
> 所以 `start.cmd` 里专门写了自动重装/重编译/**自动快照**逻辑，**不需要你手动处理**。
> 如果启动时看到"[警告] 数据库里现在是空的，但备份仓里有 N 份历史备份"，
> 说明数据被重置了，跑一次 `db-backup\restore-db.cmd` 就能全部倒回来。
>
> 「我的对局」保存的记录也在数据库里（`game_record` 表），
> 回放轨迹在 `game_replay` 表，
> 所以**备份/恢复数据库时对局记录和回放会跟着一起走**，不用担心只备份了排行榜。

---

## 八、常见问题

**Q：后端报 `Port 58049 was already in use`？**
A：这是系统的 `SERVER__PORT` 环境变量干扰了 SpringBoot。
用 `start.cmd` 启动（脚本已屏蔽该变量），或手工启动时加
`env -u SERVER__PORT -u SERVER__HOST`。详见 `AI-START-HERE.md`。

**Q：页面提示「网络错误，请确认后端已启动」？**
A：后端没起来。看看后端那个黑窗口有没有报错，确认 8080 端口在监听。

**Q：中文乱码？**
A：所有 `.cmd` 脚本都是 GBK 编码，双击运行不会乱码；
如果用编辑器打开看到乱码，请把编辑器编码切到 GBK。

**Q：能改成让密码加密吗？**
A：可以。目前是明文（教学演示用）。要改成 BCrypt 需要引入
`spring-security-crypto`，并在 `UserService` 里加解密逻辑。

---

## 九、技术要点

- 前端路由带登录守卫，未登录访问 `/game` 会被弹回 `/login`（并带上 `?map=`，登录后直达所选地图）
- 选中的地图存在 `localStorage.snake_map`，登录后进入游戏自动带上；游戏页地址栏也支持 `?map=forest|neon|ice`
- 登录成功后把 `id` 和 `username` 存进 `sessionStorage`
- 游戏用 `setInterval` 驱动，吃食物后加速（各地图起点/下限不同，见 `maps.js`）
- 对局保存的**时长**由三个变量算：开局时间戳、暂停开始时间戳、累计暂停毫秒数，
  所以暂停期间的时间不会被算进成绩
- **回放不存录像，只存走位**：录制器只记「初始蛇身 + 每步蛇头位置 + 食物顺序」，
  播放时按步重建蛇身（蛇身就是头走过的路径），一局几千步也才几十 KB
- 皮肤库的活预览和对局回放**共用同一个播放组件**（`ReplayBoard.vue`）：
  前者传一段生成的演示轨迹（循环播、不显示控制条），后者传后端存的真实轨迹（带播放条）
- 「我的对局」的删除接口会校验归属（`WHERE id=? AND (user_id=? OR username=?)`），
  删不到别人的记录；回放接口同样先校验归属，拿不到别人的回放
- 后端 `spring.sql.init.mode=always` 让 `schema.sql` 每次启动都执行
  （语句都带 `IF NOT EXISTS`，幂等安全）
- Hikari 连接池调成了懒加载 + 小池，缩短后端启动时间（实测约 2.7 秒）
