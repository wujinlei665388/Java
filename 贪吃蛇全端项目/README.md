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

# 2. 导出依赖清单（生成 cp.txt）
mvn -o org.apache.maven.plugins:maven-dependency-plugin:3.5.0:build-classpath \
     -Dmdep.outputFile=cp.txt -Dmdep.includeScope=runtime

# 3. 启动（注意 Windows 下 classpath 分隔符是分号）
java -cp "target/classes;$(cat cp.txt)" com.fenglin.springboottest.SpringBootTestApplication
```

> 也可以在 IDEA 里直接运行 `SpringBootTestApplication` 主类。

### 前端
```bash
cd frontend
npm install          # 首次或 node_modules 被删后需要
npm run dev          # 或 npm run build 打包
```

---

## 三、项目结构

```
snake-project/
├── frontend/              Vue3 前端
│   └── src/
│       ├── views/Home.vue         首页（地图选择 / 皮肤选择 / 玩法 / 排行榜）
│       ├── views/Login.vue        登录页
│       ├── views/Register.vue     注册页
│       ├── views/Game.vue         游戏页（含排行榜 + 地图切换 + 皮肤弹层）
│       ├── game/maps.js           ★ 三种地图配置（机制 + 纯色基础下的配色）
│       ├── game/skins.js          ★ 十一款皮肤配置（配色 / 底板图案 / 蛇与食物造型）
│       ├── game/render.js         绘制层（棋盘图案 / 蛇身造型 / 食物造型，共用）
│       ├── components/BgSnake.vue 背景装饰蛇（三个页面共用）
│       └── api/user.js            接口封装
├── backend/springBootTest/       SpringBoot 后端
├── screenshots/                  页面截图（0-首页 / 1-登录 / 2-注册 / 3-游戏 / 4~6-三种地图 / 7~10-皮肤）
├── sql/
│   ├── snake_game.sql    建库脚本（备份）
│   └── backup/           数据备份目录
├── scripts/              一键脚本（全部 GBK 编码）
│   ├── start.cmd         启动
│   ├── stop.cmd          停止
│   ├── init-db.cmd       重置数据库
│   ├── backup-db.cmd     备份数据
│   └── restore-db.cmd    恢复数据
└── AI-START-HERE.md      给 AI 看的交接文档（含踩坑记录）
```

---

## 四、功能说明

| 页面 | 功能 |
|------|------|
| 首页 `/` | 游戏门面：三种**地图选择卡** + 十一款**皮肤选择卡**（都带实时缩略图预览，换皮肤时地图卡联动刷新）、玩法说明、Top5 排行榜预览；顶部导航可跳地图/皮肤/玩法/排行榜，右上角显示登录状态 |
| 登录页 | 账号密码登录，背景有装饰性游动贪吃蛇；会提示"登录后进入地图：xx"，可点"换一张"回首页重选 |
| 注册页 | 注册新账号，校验用户名格式（3-20位字母/数字/下划线）和密码长度（≥6位） |
| 游戏页 | 方向键/WASD 控制，空格暂停；棋盘上方可**随时切换三种地图**（换图即重开一局）；顶栏「皮肤」弹层可**边玩边换肤**（不清局）；右上角可看**排行榜** |

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

**分数会存进数据库**：一局结束后自动把本局分数同步到后端，
后端只在比历史记录更高时才更新（不会被低分覆盖）。
排行榜按最高分倒序显示前 10 名。

---

## 五、数据库

后端启动时会**自动建库建表**（配置了 `createDatabaseIfNotExist=true`
和启动执行 `schema.sql`），一般你什么都不用做。

需要手动操作时：

| 脚本 | 作用 |
|------|------|
| `scripts\init-db.cmd` | 重置数据库（清空数据重新建表） |
| `scripts\backup-db.cmd` | 备份到 `sql\backup\snake_game_日期.sql` |
| `scripts\restore-db.cmd` | 从最新备份恢复 |

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

前端通过 vite 代理访问（`/api` → `http://localhost:8080`），所以不存在跨域问题。
代理配置在 `frontend/vite.config.js`。

---

## 七、换一台电脑 / 重置后怎么办

1. 双击 `scripts\start.cmd` —— 它会自动处理编译和依赖安装
2. 想找回之前的玩家数据：先恢复备份
   ```
   双击 scripts\restore-db.cmd
   ```

> **小提示**：这台电脑每次开机都会重置，`node_modules` 和 `target` 会被清掉。
> 所以 `start.cmd` 里专门写了自动重装/重编译逻辑，**不需要你手动处理**。
> 玩出高分后建议跑一次 `backup-db.cmd`，把数据存下来。

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
- 后端 `spring.sql.init.mode=always` 让 `schema.sql` 每次启动都执行
  （语句都带 `IF NOT EXISTS`，幂等安全）
- Hikari 连接池调成了懒加载 + 小池，缩短后端启动时间（实测约 2.7 秒）
