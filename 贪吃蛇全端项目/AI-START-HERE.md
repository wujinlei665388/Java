# AI 交接文档 —— 贪吃蛇项目（请先读我）

> 本文件是写给**后续 AI 助手**看的，不是给用户看的教学文档。
> 目的：避免重复踩坑、避免重复探索。**动手前请先读完本文。**

---

## 0. 一句话总览

桌面 `snake-project` 是一个「Vue3 前端 + SpringBoot 后端 + MySQL」的贪吃蛇全栈项目。
前端 5173，后端 8080，数据库 `snake_game`（root / 123456）。

---

## 0.1 ★ 下次 AI 快速启动（照抄就行，别再探索）★

每次开机 `node_modules/` 和 `target/` 都会被删，直接按顺序执行：

```bash
# 1. 后端：编译 + 拷贝依赖到 target/lib（离线优先，失败会自动走联网）
cd "C:/Users/Administrator/Desktop/snake-project/backend/springBootTest"
export JAVA_HOME="C:/Program Files/Zulu/zulu-21"
MVN="/d/IntelliJ IDEA 2024.3.2.2/plugins/maven/lib/maven3/bin/mvn.cmd"
"$MVN" -o -q clean compile || "$MVN" -q clean compile
"$MVN" -o -q org.apache.maven.plugins:maven-dependency-plugin:3.5.0:copy-dependencies -DoutputDirectory=target/lib -DincludeScope=runtime

# 2. 后端：后台启动（必须清掉 SERVER__PORT，原因见第 2 节）
#    注意 classpath 用通配符 target/lib/*，java 自己展开，不再需要 cp.txt
env -u SERVER__PORT -u SERVER__HOST "$JAVA_HOME/bin/java.exe" -Dfile.encoding=UTF-8 \
  -cp "target/classes;target/lib/*" com.fenglin.springboottest.SpringBootTestApplication

# 3. 前端：装依赖 + 后台启动
cd "C:/Users/Administrator/Desktop/snake-project/frontend"
NODE="C:/Users/Administrator/.workbuddy/binaries/node/versions/22.22.2-2"
"$NODE/npm.cmd" install --no-audit --no-fund --registry https://registry.npmmirror.com
"$NODE/node.exe" node_modules/vite/bin/vite.js --host 127.0.0.1

# 4. 验证（应返回 code:200）
curl -s -X POST http://localhost:8080/api/user/login -H "Content-Type: application/json" -d '{"username":"admin","password":"123456"}'
```

给用户双击用：`scripts\start.cmd`（启动）/ `scripts\stop.cmd`（停止）。
**不要**用 `mvn spring-boot:run`（见第 3 节）。

---

## 1. 目录结构（已整理好，别乱动）

```
snake-project/
├── frontend/                    # Vue3 + Vite 前端
│   ├── src/views/Home.vue       # 首页（2026-10-12 新增：地图选择/皮肤选择/玩法/排行榜）
│   ├── src/views/Login.vue      # 登录页（贪吃蛇主题，带"登录后进入地图 xx"提示）
│   ├── src/views/Register.vue   # 注册页
│   ├── src/views/Game.vue       # 游戏页（含排行榜 + 三地图切换 tab + 皮肤弹层）
│   ├── src/game/maps.js         # ★ 三种地图配置（机制 + 纯色基础下的配色）
│   ├── src/game/skins.js        # ★ 2026-10-12 新增：十一款皮肤（1 基础 + 10 特设）
│   ├── src/game/render.js       # 2026-10-12 新增：绘制层（棋盘图案/蛇身造型/食物造型）
│   ├── src/components/BgSnake.vue # 背景装饰蛇组件（原登录/注册页的内联 canvas 已抽成它）
│   ├── src/api/user.js          # 所有后端接口封装
│   ├── src/router/index.js      # 路由（'/' 现在指向首页）+ 登录守卫
│   └── vite.config.js           # ★ /api 代理到 8080 的配置在这里
├── backend/springBootTest/      # SpringBoot 3.4.5 后端
│   ├── src/main/java/com/fenglin/springboottest/
│   │   ├── controller/UserController.java   # 5 个接口
│   │   ├── service/UserService.java
│   │   ├── entity/User.java
│   │   ├── mapper/UserMapper.java
│   │   └── config/WebConfig.java            # CORS
│   └── src/main/resources/
│       ├── application.properties           # ★ 关键配置，注释很详细
│       └── schema.sql                       # 启动时自动执行的建表语句
├── sql/
│   ├── snake_game.sql           # 完整建库脚本（备份用）
│   └── backup/                  # mysqldump 备份目录（可能有）
├── scripts/                     # ★ 全部是 GBK 编码 + CRLF 行尾
│   ├── _env.cmd                 # 环境探测（被其他脚本 call）
│   ├── start.cmd                # 一键启动
│   ├── stop.cmd                 # 一键停止
│   ├── init-db.cmd              # 初始化数据库
│   ├── backup-db.cmd            # 备份数据库
│   └── restore-db.cmd           # 恢复数据库
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

| 方法 | 路径 | 入参 | 说明 |
|------|------|------|------|
| POST | `/api/user/register` | `{username, password}` | 注册，用户名单一约束 |
| POST | `/api/user/login` | `{username, password}` | 登录，返回 `{id, username, score}` |
| POST | `/api/user/score` | `{userId, score}` | 存最高分，**只在更大时更新** |
| GET  | `/api/user/info?username=x` | - | 查用户信息 |
| GET  | `/api/user/rank?limit=10` | - | 排行榜，score 倒序 |

统一响应：`{ code, msg, data }`（200 成功 / 400 业务失败 / 500 异常）

**注意**：`/api/user/score` 的 `userId` 必须用**真实的数据库 id**。
前端登录成功后把 `id` 存进了 `sessionStorage.snake_uid`，
`Game.vue` 结束时自动调用 `saveScore()`。不要改成传用户名。

---

## 8. 每次开机重置后会怎样

- `node_modules/` 被删 → `start.cmd` 会自动 `npm install`（已加 npmmirror 国内镜像，约 40 秒）
- `target/` 被删 → `start.cmd` 会自动编译（离线优先，失败自动转联网）
- MySQL 数据可能丢 → 后端启动会自动建库建表（但用户数据没了），
  想保留历史分数就提前跑 `backup-db.cmd`，重置后跑 `restore-db.cmd`
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
- 游戏分数只存最高分，没有历史对局记录表
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
