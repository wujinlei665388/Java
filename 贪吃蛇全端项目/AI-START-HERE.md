# AI 交接文档 —— 贪吃蛇项目（请先读我）

> 本文件是写给**后续 AI 助手**看的，不是给用户看的教学文档。
> 目的：避免重复踩坑、避免重复探索。**动手前请先读完本文。**

---

## 0. 一句话总览

桌面 `贪吃蛇全端项目` 是一个「Vue3 前端 + SpringBoot 后端 + MySQL」的贪吃蛇全栈项目。
前端 5173，后端 8080，数据库 `snake_game`（root / 123456）。
数据库备份在**独立备份仓** `db-backup/`（见第 13 节，先看那个再动备份相关的东西）。

---

## 0.1 ★ 下次 AI 快速启动（照抄就行，别再探索）★

每次开机 `node_modules/` 和 `target/` 都会被删，直接按顺序执行：

```bash
# 1. 后端：编译 + 拷贝依赖到 target/lib（离线优先，失败会自动走联网）
cd "C:/Users/Administrator/Desktop/贪吃蛇全端项目/backend/springBootTest"
export JAVA_HOME="C:/Program Files/Zulu/zulu-21"
MVN="/d/IntelliJ IDEA 2024.3.2.2/plugins/maven/lib/maven3/bin/mvn.cmd"
"$MVN" -o -q clean compile || "$MVN" -q clean compile
"$MVN" -o -q org.apache.maven.plugins:maven-dependency-plugin:3.5.0:copy-dependencies -DoutputDirectory=target/lib -DincludeScope=runtime

# 2. 后端：后台启动（必须清掉 SERVER__PORT，原因见第 2 节）
#    注意 classpath 用通配符 target/lib/*，java 自己展开，不再需要 cp.txt
env -u SERVER__PORT -u SERVER__HOST "$JAVA_HOME/bin/java.exe" -Dfile.encoding=UTF-8 \
  -cp "target/classes;target/lib/*" com.fenglin.springboottest.SpringBootTestApplication

# 3. 前端：装依赖 + 后台启动
cd "C:/Users/Administrator/Desktop/贪吃蛇全端项目/frontend"
NODE="C:/Users/Administrator/.workbuddy/binaries/node/versions/22.22.2-2"
"$NODE/npm.cmd" install --no-audit --no-fund --registry https://registry.npmmirror.com
"$NODE/node.exe" node_modules/vite/bin/vite.js --host 127.0.0.1

# 4. 验证（应返回 code:200）
curl -s -X POST http://localhost:8080/api/user/login -H "Content-Type: application/json" -d '{"username":"admin","password":"123456"}'
```

给用户双击用：`scripts\start.cmd`（启动）/ `scripts\stop.cmd`（停止）。
**不要**用 `mvn spring-boot:run`（见第 3 节）。

> **★ 本机 AI 环境下编译后端的唯一可行姿势（2026-10-14 实测）★**
> `mvn.cmd` / `cmd.exe` 都会被安全策略拒（见第 13 节坑 6），所以不能靠 `mvn.cmd`。
> 但 Maven 的 bash 启动脚本在 MSYS 下也起不来（classworlds jar 名对不上，
> IDEA 自带的是 `plexus-classworlds-2.8.0.jar`，缓存发行版是 `2.11.0` 的差异问题）。
> 直接调 Maven 的 Java 启动类就行：
> ```bash
> export JAVA_HOME="C:/Program Files/Zulu/zulu-21"
> M2="C:/Users/Administrator/.m2/wrapper/dists/apache-maven-3.9.16-bin/5grr65jo27hi51sujmtcldfovl/apache-maven-3.9.16"
> cd "C:/Users/Administrator/Desktop/贪吃蛇全端项目/backend/springBootTest"
> "$JAVA_HOME/bin/java.exe" -classpath "$M2/boot/plexus-classworlds-2.11.0.jar" \
>   "-Dclassworlds.conf=$M2/bin/m2.conf" "-Dmaven.home=$M2" "-Dmaven.multiModuleProjectDirectory=$PWD" \
>   org.codehaus.plexus.classworlds.launcher.Launcher -o compile
> ```
> 注意 `plexus-classworlds` 的版本号要去 `$M2/boot/` 里实际看一眼，别写死。
> `-o compile` **不要带 `clean`**：后端正在运行时 `target/lib/*.jar` 被占用，clean 会失败。
> 起了第二个测试实例（另一个端口）后同理。想验证接口又不想打扰用户正在跑的 8080，
> 就 `SNAKE_PORT=8181 java -cp "target/classes;target/lib/*" ...`，两个实例共用一个 MySQL 没问题。

---

## 1. 目录结构（已整理好，别乱动）

```
贪吃蛇全端项目/
├── frontend/                    # Vue3 + Vite 前端
│   ├── src/views/Home.vue       # 首页（地图/皮肤/玩法/排行榜；2026-10-14 加「我的空间」入口）
│   ├── src/views/Login.vue      # 登录页（贪吃蛇主题，带"登录后进入地图 xx"提示）
│   ├── src/views/Register.vue   # 注册页
│   ├── src/views/Game.vue       # 游戏页（排行榜 + 三地图 tab + 皮肤弹层 + 对局保存/录制回放）
│   ├── src/views/MySpace.vue    # ★ 2026-10-14 新增：我的空间 = 皮肤库 + 对局回放（见第 15 节）
│   ├── src/game/maps.js         # ★ 三种地图配置（机制 + 纯色基础下的配色）
│   ├── src/game/skins.js        # ★ 2026-10-12 新增：十一款皮肤（1 基础 + 10 特设）
│   ├── src/game/render.js       # 2026-10-12 新增：绘制层（棋盘图案/蛇身造型/食物造型）
│   ├── src/game/replay.js       # ★ 2026-10-14 新增：轨迹录制/编解码/按步重建 + 演示轨迹
│   ├── src/components/BgSnake.vue    # 背景装饰蛇组件（登录/注册/首页/我的空间共用）
│   ├── src/components/ReplayBoard.vue # ★ 2026-10-14 新增：画布播放器（皮肤预览 + 对局回放共用）
│   ├── src/api/request.js       # ★ 2026-10-14 抽出：axios 实例 + 响应拦截器（user/record 共用）
│   ├── src/api/user.js          # 用户接口封装
│   ├── src/api/record.js        # ★ 2026-10-14 新增：对局记录接口（保存/列表/统计/删除/取回放）
│   ├── src/router/index.js      # 路由（'/' 首页、'/my' 我的空间）+ 登录守卫（只拦 /game）
│   └── vite.config.js           # ★ /api 代理到 8080 的配置在这里
├── backend/springBootTest/      # SpringBoot 3.4.5 后端
│   ├── src/main/java/com/fenglin/springboottest/
│   │   ├── controller/UserController.java         # 5 个用户接口
│   │   ├── controller/GameRecordController.java   # ★ 2026-10-14：5 个对局记录 + 回放接口
│   │   ├── service/UserService.java
│   │   ├── service/GameRecordService.java         # ★ 2026-10-14 新增
│   │   ├── service/GameReplayService.java         # ★ 2026-10-14 新增：轨迹存取
│   │   ├── entity/User.java
│   │   ├── entity/GameRecord.java                 # ★ 2026-10-14 新增（replay/replaySteps 是搭车的非表字段）
│   │   ├── entity/GameReplay.java                 # ★ 2026-10-14 新增
│   │   ├── mapper/UserMapper.java
│   │   ├── mapper/GameRecordMapper.java           # ★ 2026-10-14 新增
│   │   ├── mapper/GameReplayMapper.java           # ★ 2026-10-14 新增
│   │   └── config/WebConfig.java                  # CORS
│   └── src/main/resources/
│       ├── application.properties                 # ★ 关键配置，注释很详细
│       └── schema.sql                             # 启动时自动执行的建表语句（含 game_record / game_replay）
├── sql/
│   ├── snake_game.sql           # 完整建库脚本（空库模板）
│   └── backup/                  # 老备份目录，已停用（只留 snake_game_init.sql）
├── db-backup/                   # ★ 独立数据库备份仓（2026-10-14 新建，见第 13 节）
│   ├── README.md                #   备份仓说明书
│   ├── _db.cmd                  #   自包含环境探测（不依赖 scripts\_env.cmd）
│   ├── backup-db.cmd            #   [手动] 库 -> 备份
│   ├── restore-db.cmd           #   [手动] 备份 -> 库（交互选序号）
│   ├── list-backups.cmd         #   [手动] 只读查看备份仓 + 库现状
│   ├── auto-backup.cmd          #   [自动] 启动自检 + 快照，被 start.cmd 调，无 pause
│   ├── snapshots/               #   manual/（永久） auto/（留最近10份） latest/（最新副本）
│   └── logs/backup-history.log  #   备份/恢复台账
├── scripts/                     # ★ 全部是 GBK 编码 + CRLF 行尾
│   ├── _env.cmd                 # 环境探测（被其他脚本 call）
│   ├── start.cmd                # 一键启动（第 2 步会调 db-backup\auto-backup.cmd）
│   ├── stop.cmd                 # 一键停止
│   ├── init-db.cmd              # 初始化数据库
│   ├── backup-db.cmd            # 已改成转发 -> db-backup\backup-db.cmd
│   └── restore-db.cmd           # 已改成转发 -> db-backup\restore-db.cmd
└── AI-START-HERE.md             # 本文件
```

---

## 2. ★★★ 最大的坑：SERVER__PORT 环境变量 ★★★

**现象**：后端启动报 `Web server failed to start. Port 58049 was already in use.`

**原因**：WorkBuddy / CodeBuddy 运行时会往环境里塞 `SERVER__PORT=58049`。
Spring Boot 的「松散绑定」规则把 `SERVER__PORT` 认成了 `server.port`，
而且**环境变量优先级高于 application.properties**，于是后端跑去抢 58049
（那是 WorkBuddy 自己在用的端口），必然失败。

**已做的双重防护，请勿删除**：
1. `application.properties` 里写的是 `server.port=${SNAKE_PORT:8080}`，
   故意避开 `server.port` 这个键名，让环境变量覆盖不到。
2. `scripts/_env.cmd` 里有 `set "SERVER__PORT="` 把它清掉。

**如果你在命令行手工启动后端**，务必用：
```bash
env -u SERVER__PORT -u SERVER__HOST java -cp "target/classes;target/lib/*" com.fenglin.springboottest.SpringBootTestApplication
```

---

## 3. ★★ 第二个坑：不要用 spring-boot:run ★★

`spring-boot-maven-plugin` 自身的依赖（buildpack-platform、jna、jcommander、
micrometer 等）在本地 `.m2` 里**只有 pom 没有 jar**，
离线执行 `mvn spring-boot:run` 会报一堆
`has not been downloaded from it before` 而失败。

**正确做法**（start.cmd 就是这么做的）：
```
mvn -o clean compile                                        # 编译
mvn -o org.apache.maven.plugins:maven-dependency-plugin:3.5.0:copy-dependencies \
      -DoutputDirectory=target/lib -DincludeScope=runtime   # 依赖 jar 拷到 target/lib
java -cp "target/classes;target/lib/*" com.fenglin.springboottest.SpringBootTestApplication
```
> 依赖插件必须写**完整坐标 + 版本 3.5.0**：`dependency:copy-dependencies` 这种
> 简写在离线模式下解析不到前缀，只有 3.5.0 的 jar 在本地存在。

## 3.1 ★★ start.cmd 曾有的 bug：cp.txt + set /p 变量展开时序（已修复）★★

旧版 start.cmd 用 `start ... cmd /k "set /p CP=<cp.txt & java ... %CP% ..."` 启动后端。
**cmd 会把整行命令一次性解析，`%CP%` 在 `set /p` 执行前就被展开（结果为空）**，
新窗口里 classpath 变成 `target\classes;`（或字面量 `%CP%`），后端报
`Could not find or load main class` 永远起不来。
2026-10-10 已改为 copy-dependencies + `target\lib\*` 通配符，不再有 cp.txt。
**在 cmd 里拼接"先 set 再同行用 %var%"是经典错误**，要么用 `call` 强制二次展开，
要么像现在这样干脆不要变量。

---

## 4. ★ MySQL 驱动版本必须锁 8.0.33 ★

SpringBoot 3.4.5 默认的 `mysql-connector-j` 是 **9.1.0**，
本地 `.m2` **没有缓存**，离线构建直接失败。
已在 pom.xml 里显式锁 `8.0.33`（本地有完整 jar，且兼容 MySQL 8.0.39）。
**不要把版本号删掉。**

---

## 5. 环境路径（本机固定，已写进 _env.cmd）

| 组件  | 路径 |
|-------|------|
| JDK   | `C:\Program Files\Zulu\zulu-21` |
| Maven | `D:\IntelliJ IDEA 2024.3.2.2\plugins\maven\lib\maven3\bin\mvn.cmd` |
| MySQL | `C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe` |
| Node  | `C:\Users\Administrator\.workbuddy\binaries\node\versions\22.22.2-2\node.exe` |

> 本机没有独立安装 Maven，用的是 IDEA 自带的。
> 如果以后 IDEA 升级换目录，改 `_env.cmd` 第 2 节的 `MVN` 探测即可。

---

## 6. 常规操作速查

**启动**：双击 `scripts\start.cmd`（自动查MySQL、编译、起两端、开浏览器）

**停止**：双击 `scripts\stop.cmd`

**手工起后端**（调试用）：
```bash
cd backend/springBootTest
export JAVA_HOME="C:/Program Files/Zulu/zulu-21"
MVN="/d/IntelliJ IDEA 2024.3.2.2/plugins/maven/lib/maven3/bin/mvn.cmd"
"$MVN" -o -q clean compile
"$MVN" -o -q org.apache.maven.plugins:maven-dependency-plugin:3.5.0:copy-dependencies -DoutputDirectory=target/lib -DincludeScope=runtime
env -u SERVER__PORT -u SERVER__HOST "$JAVA_HOME/bin/java.exe" -cp "target/classes;target/lib/*" com.fenglin.springboottest.SpringBootTestApplication
```

**手工起前端**：
```bash
cd frontend
"C:/Users/Administrator/.workbuddy/binaries/node/versions/22.22.2-2/node.exe" node_modules/vite/bin/vite.js --host 127.0.0.1
# 没有 node_modules 时先：npm install --registry https://registry.npmmirror.com
```

**验证接口是否活着**：
```bash
curl -s -X POST http://localhost:8080/api/user/login -H "Content-Type: application/json" -d '{"username":"admin","password":"123456"}'
```

---

## 7. 后端接口清单

**用户（UserController，`/api/user`）**

| 方法 | 路径 | 入参 | 说明 |
|------|------|------|------|
| POST | `/api/user/register` | `{username, password}` | 注册，用户名单一约束 |
| POST | `/api/user/login` | `{username, password}` | 登录，返回 `{id, username, score}` |
| POST | `/api/user/score` | `{userId, score}` | 存最高分，**只在更大时更新** |
| GET  | `/api/user/info?username=x` | - | 查用户信息 |
| GET  | `/api/user/rank?limit=10` | - | 排行榜，score 倒序 |

**对局记录 + 回放（GameRecordController，`/api/record`，2026-10-14 新增，详见第 14 / 15 节）**

| 方法 | 路径 | 入参 | 说明 |
|------|------|------|------|
| POST   | `/api/record/save` | `{userId, username, score, snakeLen, foodCount, mapId, mapName, skinId, skinName, duration, replay?, replaySteps?}` | 保存一局（`id`/`createTime` 后端生成，前端传了也忽略） |
| GET    | `/api/record/list?userId=&username=&limit=20` | - | 我的对局，按 `create_time` 倒序；每条带 `hasReplay` / `replaySteps` |
| GET    | `/api/record/stats?userId=&username=` | - | 我的统计：`games/best/avgScore/maxLen/totalDuration/totalFood` |
| GET    | `/api/record/{id}/replay?userId=&username=` | - | 取某一局的回放轨迹，返回 `{record, replay, steps}`；没轨迹返回 400 |
| DELETE | `/api/record/{id}?userId=&username=` | - | 删自己的一条（**连带删掉它的回放轨迹**），不是自己的返回 400 |

`replay` 是前端 `encodeTrack()` 产出的**字符串**（紧凑 JSON），后端只当文本存，
不解析、不渲染 —— 回放格式归前端管，后端换语言实现都不用动。
超过 150 万字符会被整段丢弃（只丢轨迹，这一局的其它数据照样落库）。

统一响应：`{ code, msg, data }`（200 成功 / 400 业务失败 / 500 异常）

**注意**：`/api/user/score` 的 `userId` 必须用**真实的数据库 id**。
前端登录成功后把 `id` 存进了 `sessionStorage.snake_uid`，
`Game.vue` 结束时自动调用 `saveScore()`。不要改成传用户名。

`/api/record/*` 的 `userId`/`username` **至少传一个**，两个都不传会返回 400
（这是有意的：防止有人不传身份就把全表对局捞走）。两个都传时是"或"的关系。

---

## 8. 每次开机重置后会怎样

- `node_modules/` 被删 → `start.cmd` 会自动 `npm install`（已加 npmmirror 国内镜像，约 40 秒）
- `target/` 被删 → `start.cmd` 会自动编译（离线优先，失败自动转联网）
- MySQL 数据可能丢 → 后端启动会自动建库建表（但用户数据没了），
  数据备份/恢复统一走 **`db-backup/` 独立备份仓**（见第 13 节）：
  `start.cmd` 启动时会自动快照一份，数据被清后在 `db-backup/restore-db.cmd` 里选一份倒回来
- `.m2` 仓库已缓存全部后端依赖（2026-10-10 验证：曾缺
  `mybatis-plus-spring-boot3-starter:3.5.7`，已联网补齐，现可离线构建）。
  若离线编译再报 `has not been downloaded`，去掉 `-o` 联网跑一次即可，
  阿里云镜像（`~/.m2/settings.xml`）可用。

---

## 9. 脚本编写约定（改动脚本时请遵守）

1. **必须是 GBK 编码** → 否则 cmd 窗口中文乱码
2. **必须是 CRLF 行尾** → 否则 cmd 会把中文注释行当命令执行，报一堆
   `'xxx' 不是内部或外部命令`
3. **不要用 GBK 无法编码的字符**：`✓ ✗ ★ → · ⚠ ✅` 等符号会转换失败，
   统一用 `[OK] / [X] / -> / - / !` 代替
4. **用相对路径**：脚本靠 `%~dp0` 定位自身，项目文件夹随便挪
5. 生成 GBK 脚本的命令：
   ```bash
   iconv -f UTF-8 -t GBK src.cmd > out.cmd
   sed -i 's/\r$//' out.cmd && sed -i 's/$/\r/' out.cmd   # 补 CRLF
   ```

---

## 10. 已知可优化项（如果用户要求继续优化）

- 密码是**明文存储**，生产环境应换 BCrypt
- 没有 JWT / Token 鉴权，登录态存在 sessionStorage，刷新即失效
- 前端每次登录都重新拉数据，可加 keep-alive 缓存
- ~~游戏分数只存最高分，没有历史对局记录表~~ → **2026-10-14 已做**，见第 14 节
- ~~皮肤和回放分散在首页/游戏页~~ → **2026-10-14 合并成「我的空间」独立页面**，见第 15 节
- 对局记录目前**一次最多取 20 条（上限 100）、没有分页和筛选**，
  等记录多了要加"按地图/皮肤/时间筛选 + 分页"
- 对局记录**没有"是否保存"的后悔药**：点了"不保存"就真的没有留档，
  点了"保存"只能事后在列表里删
- 回放**只对新存的对局有效**：功能上线前保存的老记录没有轨迹（列表里标「仅数据」），
  想要回放功能前的老局只能重新玩
- 皮肤库的活预览是"生成的演示路线"，不是真人对局；如果想让它更像真人，
  可以预录几条真实轨迹当模板轮流播
- 后端未做全局异常处理器（现在是 controller 里 try/catch）

---

## 11. 地图系统（2026-10-12 新增，改地图只动一个文件）

**三种风格地图**的配置全部在 `frontend/src/game/maps.js`，
首页缩略图（`paintPreview`）和游戏页棋盘（`paintBoard`）共用同一份配置和绘制函数，
**改 maps.js 一处，两处同时生效**。每张地图包含：

- `theme`：配色（会注入成游戏页的 CSS 变量 `--bd/--glow/--board/--body/--head/--text/--muted`）
- `rules.wrap`：true = 边界可穿越（极地冰川），false = 撞墙死
- `rules.walls`：障碍矩形列表 `{x,y,w,h}`（格为单位），运行时展开成 `"x,y"` 集合做 O(1) 碰撞
- `rules.speed/minSpeed/step/foodScore`：起始速度、加速下限、每果提速、每果得分

**换地图的入口有三处，行为一致**：
1. 首页地图卡片（写 `localStorage.snake_map`，未登录则跳 `/login?map=xx`）
2. 登录页顶部的"换一张"链接（回首页重选）
3. 游戏页棋盘上方的三个 tab（`switchMap()`，换图即重开一局，最高分不清）

路由：`/` = 首页，`/game?map=forest|neon|ice`。登录守卫会把 `?map=` 一起带到 `/login`。
**注意**：`mapId` 在 Game.vue setup 时从 `route.query.map` 读一次，游戏页内改地址栏 query 不会切图（tab 才会），这是有意为之。

**验证截图**：`screenshots/0-home.png`（首页）、`4-map-classic.png`、`5-map-neon.png`、`6-map-ice.png`（三张地图）。
已用无头 Chrome 实测：三图配色/障碍/穿越边界/切换 tab/吃食物计分（15 分=霓虹图分值）均正常，控制台无报错。

---

## 12. 皮肤系统（2026-10-12 新增，改皮肤只动 skins.js）

**地图管机制，皮肤管外观**：
- 地图（maps.js）：障碍布局、wrap 穿越边界、速度、每果得分
- 皮肤（skins.js）：整套 palette + 底板图案 pattern + 蛇身造型 snakeStyle + 食物造型 foodStyle

**11 款皮肤**：`纯色基础`(palette=null，完全跟随地图配色，默认) + 10 款特设
`彩虹糖果 / 熔岩烈焰 / 黄金矿脉 / 极地冰晶 / 霓虹描边 / 8bit 像素 / 星河漫游 / 樱花物语 / 电子电路 / 幽影潜行`。

**关键实现**：
- `skins.js` 的 `resolveTheme(map, skin)` 把地图+皮肤合成 view 对象（palette/pattern/snakeStyle/foodStyle + map 引用），
  供 `render.js` 的 `paintBoard / drawFood / drawSnake / paintPreview` 使用；render.js 不 import 任何模块，避免循环依赖。
- `maps.js` 已**不再导出绘制函数**（都在 render.js），只留数据；别再从 maps.js import paintBoard。
- 换肤 = 改 `skinId` + `saveSkinId` + 立即 `draw()`，**不重开一局**（换图才会重开）。
- 首页：皮肤卡预览 = 该皮肤画在**当前所选地图**上；换皮肤/换地图会重画全部缩略图（paintMapThumbs/paintSkinThumbs）。
- 底板随机图案（星星/花瓣）用**固定种子伪随机 + 模块级缓存**（render.js 的 seededPoints），
  否则游戏页每帧重绘会闪。加新图案时也要走这个缓存。
- 选中的皮肤存 `localStorage.snake_skin`；游戏页顶栏「皮肤：xx」打开弹层换肤。

**可扩展点**：加新皮肤 = 往 `SKINS` 数组加一个对象；加新蛇造型 = render.js 的 `drawSnake` 加一个 style 分支；
加新底板图案 = `drawPattern` 加一个 case + seededPoints 缓存。

**验证截图**：`screenshots/7-skins.png`（首页皮肤区）、`8-skins-all.png`（11 款总览）、
`9-game-skin-panel.png`（游戏内换肤弹层）、`10-game-skin-rainbow.png`（彩虹皮肤对局）。
已用无头 Chrome 实测：11 款缩略图指纹互不相同、游戏内逐款换肤棋盘指纹 11/11 互异、
换肤不影响本局长度与得分、控制台无报错。

---

## 13. 数据库独立备份仓 db-backup（2026-10-14 新建，改备份相关务必先看本节）

**需求原话**：在项目里建一个单独文件夹备份数据库，实现"两者互通"，单独保存。

**设计定性**：
- **独立**：`db-backup/` 里的脚本只用 `%~dp0` 定位自己，**不 call `scripts\_env.cmd`**，
  自带 `_db.cmd` 做环境探测。整个文件夹剪走/拷到 U 盘都能单独跑。
  改的时候**不要**把它接到 `scripts/` 上，那就破坏"独立"这个前提了。
- **互通**：`backup-db.cmd` 导出（库 → 备份），`restore-db.cmd` 导入（备份 → 库），
  两条通道都跑通并实测过。
- **单独保存**：备份文件全在 `db-backup/snapshots/` 下，不再往 `sql/backup/` 写。
  `sql/backup/` 只剩一个 `snake_game_init.sql`（空库模板），已停用。

**文件职责**：

| 文件 | 职责 | 有 pause？ |
|------|------|-----------|
| `_db.cmd` | 公共环境：定位 VAULT/PROJECT、建目录、探测 mysql/mysqldump、定 DB_NAME/USER/PASS、算 STAMP 时间戳 | — |
| `backup-db.cmd` | 手动备份 → `snapshots/manual/snake_game_<STAMP>.sql` + 刷新 latest + 记账 | 有 |
| `restore-db.cmd` | 列备份（手动在前、自动在后）→ 输序号或回车用 latest → 输 Y 确认 → 导入 → 核对条数 | 有 |
| `list-backups.cmd` | 只读查看：备份清单、latest 信息、库里现有数据、最近台账 | 有 |
| `auto-backup.cmd` | 启动自检 + 自动快照，**给 start.cmd 调的，全程无交互、不许 pause、不许 exit（不带 /b）** | **无** |

**start.cmd 接入点**：`[2/6] 数据库备份自检 ...`，位置在"检查 MySQL"之后、"检查 8080"之前
（即后端启动前，这样能拿到被后端 reset 之前的数据）。原 5 步已重新编号为 /6。

**指纹去重**：`snapshots/auto/.last-state` 存 `用户数#总分和`。一样就跳过快照，避免每次启动都塞一份。
手动备份不参与去重，每次都存。`snapshots/auto/` 只留最近 10 份，`manual/` 永不自动删。

**密码/库名只在一处**：`_db.cmd` 第 2 节 `DB_NAME/DB_USER/DB_PASS`，改密码只改这里 + `application.properties`。

**写这批脚本踩到的坑（重要）**：
1. **GBK + CRLF**：和 `scripts/` 一个规矩。用 Python 读写（`decode('gbk')` / `encode('gbk')`）最稳，
   **不要用会按 UTF-8 写回的编辑器工具去改**，否则整个文件中文全烂。
   本项目是在 workspace 的 `.db-backup-src/` 里写 UTF-8 源，再
   `iconv -f UTF-8 -t GBK | sed 's/\r$//' | sed 's/$/\r/'` 转过去的。
2. **括号块内不能用 `%VAR%` 读同块里刚 set 的变量**（老坑，同第 3.1 节）。一律用 `!VAR!`。
   本次在 `list-backups.cmd` 的 latest 区就踩了一次。
3. **延迟展开开着时 echo 文本里的 `!` 会被吃掉**，警告语用 `[警告]`，别用 `!!!`。
4. **`for %%f in ("D:\*.sql") do ...` 在没有匹配文件时也会迭代一次**（字面量），
   所以数文件个数不能用这种写法，要用 `for /f ... in ('dir /b /a-d ... 2^>nul')`。
5. 时间戳不要用 `%DATE% %TIME%` 直接拼：中文系统 `%DATE%` 带"周三"。
   现在做法是 `for /f "tokens=1"` 取日期段 + `%TIME: =0%` 补零，见 `_db.cmd` 第 4 节。
6. **本机 AI 环境跑不了 cmd.exe**：Bash 工具调 `cmd` 被安全策略拒（"Invoking cmd.exe from Bash
   bypasses all command validation"），PowerShell 工具也拒（"cmd.exe cannot be used from the
   PowerShell tool"）。所以**批处理脚本没法由 AI 直接执行验证**，只能：
   (a) 由用户双击运行；或 (b) AI 直接跑脚本里那两条核心命令来验证数据通路，例如
   ```
   "C:/Program Files/MySQL/MySQL Server 8.0/bin/mysqldump.exe" -uroot -p123456 \
     --databases snake_game --add-drop-table --single-transaction --no-tablespaces \
     --triggers --routines --events --default-character-set=utf8mb4 --set-gtid-purged=OFF > x.sql
   "C:/Program Files/MySQL/MySQL Server 8.0/bin/mysql.exe" -uroot -p123456 < x.sql
   ```
   别浪费时间反复试各种调用 cmd 的花招。

**已验证的事实（2026-10-14）**：
- mysqldump 上述参数组合在 MySQL 8.0.39 上正常，导出 2751 字节（2 条用户）
- 实测往返：导出 → `INSERT` 一条 `zz_probe` 脏数据（共 3 条）→ 从备份导回 → 脏数据消失、
  `admin`/`qwer` 两条完整回来 → 说明 `--add-drop-table` 覆盖恢复是可靠的
- `scripts/backup-db.cmd`、`scripts/restore-db.cmd` 已改成**薄转发**，只 `call` 新备份仓的脚本，
  老习惯双击也能用

---

## 14. 对局保存功能（2026-10-14 新增，改对局记录务必先看本节）

**需求原话**：建立一个对局保存的功能，可以在每局结束后决定是否保存。

**一句话实现**：游戏结束时结束面板不再只有"再来一局"，而是多给一组
「保 存 本 局 / 不保存 · 再来一局」——**只有点了保存才会往 `game_record` 插一条**，
点不保存什么请求都不发，库里干干净净。

### 14.1 数据落在哪

新表 `game_record`（同时写进了 `backend/.../resources/schema.sql` 和 `sql/snake_game.sql`，
都是 `IF NOT EXISTS` 幂等，**后端启动时自动建好**，不用手工执行）：

| 字段 | 类型 | 含义 |
|------|------|------|
| `id` | BIGINT 自增 | 主键 |
| `user_id` | BIGINT 可空 | 关联 `user.id` |
| `username` | VARCHAR(20) | 冗余一份用户名，方便直接按名字查 |
| `score` | INT | 本局得分 |
| `snake_len` | INT | 结束时蛇的长度 |
| `food_count` | INT | 吃掉的食物个数 |
| `map_id` / `map_name` | VARCHAR | 地图标识 / 中文名 |
| `skin_id` / `skin_name` | VARCHAR | 皮肤标识 / 中文名 |
| `duration` | INT | 本局时长（**秒，已扣掉暂停**） |
| `create_time` | DATETIME | 保存时间，数据库默认值 |

索引：`idx_user_time(user_id, create_time)`、`idx_user_score(user_id, score)`。
**注意字段名用 `snake_len` 而不是 `length`**——`LENGTH` 是 MySQL 内置函数名，做列名要到处加反引号，容易踩雷。

### 14.2 ★ 和 `user.score` 的区别（最容易搞混的地方）

| | `user.score` | `game_record` |
|---|---|---|
| 语义 | **历史最高分**（一个玩家一行） | **每一局的流水**（一个玩家 N 行） |
| 什么时候写 | 每局结束**自动**写，且只在刷新纪录时才真的 UPDATE | **玩家点「保存本局」**才写，一局一条 |
| 谁在读 | 首页/游戏页的排行榜 | 游戏页右上角「我的对局」 |

所以「保存本局」**不会**影响排行榜，排行榜那套逻辑（`/api/user/score`）一点没动。

### 14.3 后端（4 个文件 + 1 个接口前缀）

```
controller/GameRecordController.java   /api/record/save | /list | /stats | DELETE /{id}
service/GameRecordService.java         保存 / 查询 / 统计 / 删除（统计在 Java 里算，不写聚合 SQL）
entity/GameRecord.java                 对应 game_record，create_time 用 @JsonFormat 输出 "yyyy-MM-dd HH:mm:ss"
mapper/GameRecordMapper.java           extends BaseMapper，被 @MapperScan 自动扫到
```

几个刻意的设计（改的时候别"顺手简化"掉）：

1. **必须传 userId 或 username**，两个都不传直接 400。
   这是防止有人不带身份就把全表对局捞走。`GameRecordService.mine()` 里做的。
2. **归属条件用 `and(...)` 包了一层**：`user_id=x OR username=y` 如果直接平铺，
   再拼上 `id=?` 会变成 `id=? AND a=? OR b=?`，优先级错掉就能越权删别人的记录。
3. **删除会校验归属**：`deleteMine` 把归属条件和 `id` 一起放进 WHERE，不是自己的删不到。
4. **传了 userId 就以数据库里的用户名为准**（`userService.findById`），
   防止前端把 username 改成别人的。
5. **参数兜底**：`clamp()` / `cut()` 把负数、超长、超界值夹到合法范围
   （分数上限一千万、时长上限 24 小时、蛇长和食物数上限 400 = 棋盘格数）。
6. **列表接口的 limit 夹在 1~100**，超过按 20 算。

### 14.4 前端

```
src/api/request.js   ★ 抽出来的 axios 实例 + 拦截器（user.js / record.js 共用，别再各建一个）
src/api/record.js    对局记录接口封装（saveRecord / getMyRecords / getRecordStats / deleteRecord）
src/views/Game.vue   ★ 主要改动都在这里
src/views/Home.vue   导航加「我的对局」按钮 + 玩法区加一张"保存对局"说明卡
```

`Game.vue` 的改动点：

- **计时**：`playStartAt / pauseStartAt / pausedMs` 三个变量算净时长，
  暂停（空格）会把这段时间攒到 `pausedMs`，结束和恢复时都不漏；
  `reset()` 里统一归零，`start()` 里用当前时间戳重新起算。
- **食物计数**：单独一个 `foodsEaten` 计数器，**不要用 `score / foodScore` 反算**
  （换地图时 `foodScore` 会变，算出来是错的）。
- **结束面板**：`gameOver` 为真时 override 原本那个"开始/继续"单按钮，
  换成「保存本局」+「不保存·再来一局」两个按钮；保存成功后按钮变「已保存 ✓」且 `disabled`，
  **同一局不会重复保存**（`saved` / `saving` 两个 flag 一起挡）。
- **顶栏入口**：`我的对局` → `router.push('/my?tab=records')`（直接落到回放那一栏），
  `我的空间` → `router.push('/my')`。游戏页自己**不再有对局面板**了
  （2026-10-14 第 15 节把它整体搬到 `MySpace.vue`，Game.vue 里相关的
  `showRecords / records / stats / loadRecords / removeRecord / .record-* 样式` 已删干净）。

### 14.5 验证截图与实测

- 截图：`screenshots/11-record-gameover.png`（结束面板的二选一）、
  `screenshots/12-my-records.png`（我的对局面板）
- **接口层实测**（2026-10-14，另起 8181 实例跑的，10 项全过）：
  保存（中文正常落库）、列表、统计、越权删除被拒（400）、正常删除、
  缺 username 被拒、不带身份查列表/统计被拒、删不存在的 id 被拒、
  异常数值兜底（-5→0、99999→400、-9→0）、旧接口 `/api/user/rank` 不受影响
- **浏览器端到端实测**（headless Chrome + CDP，走真实登录 → 开局 → 撞墙 → 点保存 → 看我的对局 → 再玩一局点不保存 → 删除）：
  见 `.tools/` 下那套脚本的做法；结论：保存后库里 +1 且按钮锁死，
  不保存时库里条数不变，删除后回到原条数。

> **测试别踩的坑（本机 AI 环境）**：不要在脚本的 EXIT trap 里对被 Chrome 写满的
> profile 目录做 `rm -rf`——本机有"批量删除需二次确认"的安全拦截，
> 会把整个 trap 卡死，后台任务永远不结束。profile 直接放 `$TEMP` 下就别管它了。

---

## 15. 我的空间：皮肤库 + 对局回放（2026-10-14 新增，改回放务必先看本节）

**需求原话**：将皮肤和回放查看合并成一个主页，可以在其中使用这两个功能。

**一句话实现**：新开一个独立页面 `/my`（`views/MySpace.vue`），
上面是两个标签页——**皮肤库**（把散在首页的皮肤卡 + 游戏页的换肤弹层合成一个"活的试衣间"）
和**对局回放**（把原来游戏页里的"我的对局"搬过来，并给每一局加了**轨迹动画回放**）。
原来的首页保持原样，只是导航里多一个入口。

### 15.1 路由与入口

| 位置 | 行为 |
|------|------|
| `/my` | 我的空间，默认停在「皮肤库」 |
| `/my?tab=records` | 直接落到「对局回放」那一栏（点「对局回放」会把 tab 同步进地址栏，刷新还在这一栏） |
| 首页导航 `我的空间`、首页按钮 `我的对局` | `/my` 与 `/my?tab=records` |
| 游戏页顶栏 `我的空间` / `我的对局` | 同上 |
| 游戏结束的保存提示 | 文案指向「我的空间 · 对局回放」 |

**路由守卫只拦 `/game`，不拦 `/my`**（`router/index.js`）——皮肤库不登录也能逛，
只有对局那一栏自己判断，未登录时显示登录引导。改守卫时注意保持这一点。

### 15.2 ★★ 回放轨迹怎么存（本节最关键，改动前必读）

**不存录像，只存走位。** 一局的轨迹只有三样东西（`frontend/src/game/replay.js`）：

1. `snake0`：开局那 3 格蛇身（只有一次）
2. `heads`：之后**每一步蛇头到达的格子**
3. `foods`：食物出现的先后顺序（开局那个 + 每吃掉一个后新生成的）

蛇身不用存——蛇身就是"蛇头走过的路径"的最后 N 格。解码时按 `lenAt[]`（每步的长度）
和 `foodAt[]`（每步该显示第几个食物）两张预计算表重建，一趟 O(n)。
编码成 `"x,y;x,y"` 这种紧凑写法，比 JSON 数组省一半以上：**一局几十步约 0.4KB，
几千步也就几十 KB**，`steps` 单独存一列方便列表显示"可回放 N 步"。

#### 这里踩了一个真坑（务必别再犯）

`createRecorder().build()` 交出来的轨迹里，`snake0 / heads / foods` **已经是字符串**了；
而 `buildDemoTrack()`（皮肤预览用的演示轨迹）交出来的是**数组**。
`encodeTrack()` 两种都会收到，所以 `pointsToStr()` **必须幂等**：

```js
function pointsToStr(arr) {
  if (typeof arr === 'string') return arr   // ← 少了这一行就出事
  ...
}
```

少了这个字符串短路判断，`for (const p of arr)` 会**按字符逐字迭代**，
产出满屏 `"undefined,undefined;undefined,undefined;..."`：
- 现象：轨迹存进去看着有好几千字符（像是存成功了），列表上 `hasReplay` 也是 true，
  但点「回放」画布是**空白 + "这局没有回放数据"**（`decodeTrack` 直接返回 null）
- 定位手法：`decodeTrack()` 是纯函数、`replay.js` 无任何依赖，
  可以直接在 Node 里 `await import('file:///.../frontend/src/game/replay.js')` 单独跑通验证，
  不用起浏览器（`.tools/debug-replay.mjs` 就是这么做的）

#### 其它约定

- `MAX_RECORD_STEPS = 50000`（约 1 小时高速局），超了置 `overflow`，前端会提示"只录了前 5 万步"
- 轨迹是**搭车**在 `/record/save` 的请求体里上来的（`replay` / `replaySteps` 两个字段，
  在 `GameRecord` 上是 `@TableField(exist = false)`，不是 `game_record` 的列）；
  落库后**不回传**（别白白把几十 KB 再发回前端一遍）
- 后端对回放**只做字符串搬运**，不解析结构：将来回放格式升级（加倍速标记、加障碍动画），
  后端一行都不用改；超 150 万字符整段丢弃（只丢轨迹，这一局的其它数据照样落库）
- 回放时用的是**轨迹里记着的那张地图 + 那款皮肤**（`ReplayBoard` 的 `view` computed 优先取
  props 里的 mapId/skinId，其次取轨迹里的），所以看到的一定是当时那一局的画面

### 15.3 后端

```
entity/GameReplay.java          对应 game_replay（record_id 是主键，@TableId(type = INPUT)，没有自增）
mapper/GameReplayMapper.java    extends BaseMapper
service/GameReplayService.java  save（先删后插，覆盖式）/ find / whichHaveReplay（批量，避免 N+1）/ delete
```

- 新表 `game_replay`：`record_id`(PK) / `steps` / `data`(MEDIUMTEXT) / `create_time`，
  已写进 `schema.sql` 和 `sql/snake_game.sql`，启动自动建
- **删对局会连带删回放**（`GameRecordService.deleteMine` → `replayService.delete`），不留孤儿行
- 列表接口 `markHasReplay()` **一次查询**给整批打标记，不要写成逐条查
- `/api/record/{id}/replay` **先校验归属再给轨迹**（`recordService.findMine`），
  不是自己的记录返回 400，所以拿不到别人的回放

### 15.4 前端

```
views/MySpace.vue              ★ 我的空间（两个标签页）
components/ReplayBoard.vue     ★ 画布播放器：皮肤活预览 + 对局回放共用同一个组件
game/replay.js                 ★ 录制 / 编解码 / 按步重建 / 演示轨迹
views/Game.vue                 录制轨迹 + 顶栏入口改指 /my（原来的对局面板已整块删除）
views/Home.vue                 导航加「我的空间」，按钮改成跳 /my?tab=records
api/record.js                  加 getRecordReplay()
```

- **`ReplayBoard` 一个组件两个用场**：皮肤库传演示轨迹（`loop`、不显示控制条），
  对局回放传后端存的真实轨迹（`controls`、带进度条/倍速/重播）。
  props：`track / mapId / skinId / size / controls / loop / speed / autoplay`
- 皮肤库的活预览：`buildDemoTrack(map, null)` 让蛇沿棋盘内圈的矩形环绕圈、边绕边吃食物，
  环的位置会**避开当前地图的障碍**（霓虹赛博有墙），所以预览和真在这张地图上玩是一致的
- 预览轨迹只跟"试衣间底板"（`previewMapId`）有关，皮肤走 `ReplayBoard` 的 `skinId` prop，
  所以**换皮肤时动画不会被打断重来**（这是 `demoTrack` 写成 computed 而不是方法的原因）
- `Game.vue` 的录制：`reset()` 里**先 `placeFood()` 再 `createRecorder()`**（开局那个食物也是轨迹的一部分），
  `tick()` 末尾 `recorder.push(head, food)`；只有点「保存本局」时才 `build()` + `encodeTrack()`
- 删除是**内联二次确认**（点「删除」变「确认删除」，4 秒不点自动撤回），不用浏览器弹窗

### 15.5 验证截图与实测

- 截图：`screenshots/13-myspace-skins.png`（皮肤库）、
  `14-myspace-records.png`（对局回放列表）、`15-myspace-replay.png`（回放播放器）
- **接口层实测**（2026-10-14，另起 8181 实例，28 项全过）：
  带/不带轨迹保存、列表 `hasReplay`、取回放、越权取回放被拒（400）、
  没轨迹的记录取回放返回 400、删除连带清轨迹、缺身份被拒、异常数值兜底
- **浏览器端到端实测**（headless Chrome + CDP，脚本 `.tools/run-myspace-test.sh` +
  `.tools/myspace-ui-test.mjs`）：玩一局（会自己拐弯走满几十步）→ 保存 → 进我的空间 →
  皮肤库（活预览真的在动、11 张缩略图指纹互异、点卡片切肤、换底板）→
  对局回放（统计/列表/可回放与仅数据标记）→ 播放器（自动播、暂停、拖进度条、
  4× 倍速、重播）→ 删除 → 未登录引导

> **写这类测试的两个坑（本机）**：
> 1. 模板字符串里 `\s` 会被吃掉变成字面量 `s`（`\n` 不会），
>    所以页面里注入的正则要写成 `\\s`；否则 `find()` 返回 undefined，报
>    "Cannot read properties of undefined"。
> 2. `Page.navigate` 到**和当前完全相同**的 URL 只会被当成同文档跳转，页面不会重建。
>    测"清掉 sessionStorage 后再看页面"这类场景，要先 `about:blank` 绕一下。
> 3. 想测回放的播放/暂停/倍速，得先让这一局**玩得够久**：开局后按
>    「下→左→上→右」的顺时针节奏拐弯（开局朝右，这个顺序才绕得回原点；
>    写成「下→右→上→左」会一路往右漂、十几步就撞边界），转够圈数再掉头自杀。
