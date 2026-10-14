# db-backup —— 数据库独立备份仓

这个文件夹是**独立**的：备份文件、备份脚本、备份记录都只放在这里，
不和 `sql/`、`scripts/` 混在一起。整个 `db-backup` 文件夹拷到哪都能单独用
（甚至拷到 U 盘或另一台装了 MySQL 的电脑），不依赖项目里任何其他脚本。

---

## 一、它解决什么问题

这台电脑**每次开机都会重置数据**：

| 会被清掉的东西 | 谁会管 |
|---|---|
| `frontend/node_modules` | `scripts/start.cmd` 自动重装 |
| `backend/.../target` | `scripts/start.cmd` 自动重编译 |
| **MySQL 里的玩家账号和分数** | **本文件夹** |

玩法：平时让它自动攒快照，数据被清掉之后，用 `restore-db.cmd` 一键倒回来。

---

## 二、目录结构

```
db-backup/
├── README.md                     本说明
├── _db.cmd                       公共环境（自包含，不依赖 scripts\_env.cmd）
│
├── backup-db.cmd                 [手动] 数据库 -> 备份      （双击运行）
├── restore-db.cmd                [手动] 备份 -> 数据库      （双击运行）
├── list-backups.cmd              [手动] 看备份仓和数据库现状（只读）
├── auto-backup.cmd               启动自检 + 自动快照（由 start.cmd 调用，无交互）
│
├── snapshots/                    备份文件都在这儿
│   ├── manual/                   手动备份，永久保留，不自动删
│   ├── auto/                     自动快照，只留最近 10 份
│   └── latest/
│       └── snake_game_latest.sql 最新一份的固定副本（restore 直接回车就用它）
│
└── logs/
    └── backup-history.log        备份/恢复台账（时间 | 类型 | 文件 | 数据量）
```

---

## 三、两条通道（这就是"互通"）

```
        backup-db.cmd  （导出 ↓）
MySQL  ────────────────────────────>  snapshots\manual\
snake_game  <────────────────────────  snapshots\latest\
        restore-db.cmd （导入 ↑）
```

- **导出**：`mysqldump --databases snake_game`。备份文件里自带
  `CREATE DATABASE` + `DROP TABLE`，所以哪怕整个库被删了，
  恢复时也不用先手动建库，一条命令倒回去。
- **导入**：`mysql < 备份文件`。恢复后会自动核对用户条数并打印出来，
  同时对不上会立刻在屏幕上显示。
- 每次导出/导入都会写一行台账到 `logs/backup-history.log`，
  格式：`时间 | MANUAL/AUTO/RESTORE | 文件名 | 用户数 | 字节数`。

---

## 四、三个手动脚本怎么用

| 脚本 | 什么时候用 | 它会做什么 |
|---|---|---|
| `backup-db.cmd` | 玩出高分之后；想留个纪念 | 存一份到 `manual\`，刷新 `latest\`，记账 |
| `restore-db.cmd` | 开机后发现账号/分数没了 | 列出所有备份 → 你输序号（或直接回车用最新一份）→ 输 `Y` 确认 → 导入 |
| `list-backups.cmd` | 想知道"备份和现在的库对不对得上" | 只读展示：有哪些备份、多大、最新副本是哪份、库里现在多少用户、最近 10 条台账 |

> `restore-db.cmd` 会**先 DROP TABLE 再重建**，当前库里的数据会被备份内容整个覆盖。
> 脚本在动手前会把当前数据打印出来给你看，并要求输入 `Y` 才继续，不会误操作。

---

## 五、开机自动做的事（接入 start.cmd）

`scripts/start.cmd` 在**检查完 MySQL、还没启动后端之前**会调用
`auto-backup.cmd`，逻辑是：

| 数据库现状 | 备份仓现状 | 自动做什么 |
|---|---|---|
| 有数据，且和上次快照不一样 | — | 静默快照一份到 `auto\`，刷新 `latest\` |
| 有数据，和上次快照一样 | — | 跳过，不重复占地方（靠 `auto\.last-state` 指纹比对） |
| 0 条用户 | 有历史备份 | **醒目警告**：提示数据可能被重置，去跑 `restore-db.cmd` |
| 0 条用户 | 没有备份 | 提示正常首次运行，无需恢复 |
| 库还没建 / 连不上 | 有历史备份 | 提示"启动后发现数据不见就去恢复" |

`auto\` 里的快照超过 10 份会自动删最旧的；`manual\` 里的**永远不会被自动删**。

---

## 六、常见问题

**Q：备份文件长得像 `snake_game_20261014-085456.sql`，后面那串是什么？**
A：`年月日-时分秒`。同一秒内不会重复，按文件名排序就是按时间排序。

**Q：想换数据库密码 / 换库名？**
A：只改 `_db.cmd` 第 2 节的 `DB_NAME / DB_USER / DB_PASS`，
然后同步改后端 `application.properties`，其它脚本不用动。

**Q：备份仓能搬到别的地方吗？**
A：可以。整个 `db-backup` 文件夹是自包含的，剪走之后双击 `backup-db.cmd`
依然能正常备份（它靠 `%~dp0` 定位自己）。搬走之后记得
`start.cmd` 里的调用路径也要跟着改（现在写的是 `%ROOT%\db-backup\auto-backup.cmd`）。

**Q：双击脚本会不会一闪而过？**
A：不会，每个手动脚本结尾都有 `pause`，会停在"请按任意键继续"。
**只有 `auto-backup.cmd` 没有 pause**——它是给 `start.cmd` 调的，设计上不该停。

**Q：脚本里中文乱码？**
A：这些 `.cmd` 和项目其它脚本一样是 **GBK 编码 + CRLF 行尾**。
用 VS Code 打开请把编码切成 GBK；双击运行是正常的。

---

## 七、当前状态（2026-10-14 建立）

- 已生成首份手动备份：`snapshots/manual/snake_game_20261014-085456.sql`（2751 字节，2 条用户）
- 已实测通过：导出 → 往库里插一条脏数据 → 从备份导回 → 脏数据消失、原数据完整回来
- 已接入 `scripts/start.cmd`：每次启动自动自检 + 需要时自动快照
