@echo off
rem ============================================================
rem  auto-backup.cmd   启动自检 + 自动快照（供 scripts\start.cmd 调用）
rem ------------------------------------------------------------
rem  这个脚本是给 start.cmd 用的，【全程无交互、不会 pause】，
rem  任何异常都静默收场，绝不能挡住项目启动。
rem
rem  它做三件事：
rem    1. 看数据库里现在有多少用户
rem       - 有数据 且 与上次快照不一样 -> 自动存一份到 snapshots\auto
rem       - 有数据 且 与上次快照一样   -> 跳过，不重复占地方
rem       - 0 条用户 但备份仓里有历史备份 -> 大声警告数据可能丢了，
rem                                        并告诉用户跑 restore-db.cmd 恢复
rem    2. 刷新 snapshots\latest（最新副本，恢复脚本默认用它）
rem    3. 轮换：snapshots\auto 只留最近 10 份，防止越积越多
rem
rem  ★ 写法约定：凡是"取 mysql 的一句话结果"，一律先重定向到
rem    %QOUT% 再用 for /f 读文件。绝对不要写成
rem      for /f %%r in ('"%MYSQL%" -e "select ..."')
rem    因为 %MYSQL% 是 "C:\Program Files\..." 带空格的带引号路径，
rem    cmd 处理引号的规则会让它解析失败。
rem ============================================================
setlocal enabledelayedexpansion
chcp 936 >nul 2>&1

call "%~dp0_db.cmd"

rem 缺客户端就直接跳过，不打扰启动流程
if not defined MYSQL exit /b 0
if not defined MYSQLDUMP exit /b 0

rem ---- 1. 读当前用户数 ----
set "CNT="
del /q "%QOUT%" >nul 2>&1
"%MYSQL%" -u%DB_USER% -p%DB_PASS% -N -B -e "SELECT COUNT(*) FROM %DB_NAME%.user;" >"%QOUT%" 2>"%ERRLOG%"
if exist "%QOUT%" for /f "delims=" %%r in ("%QOUT%") do if not defined CNT set "CNT=%%r"
if not defined CNT goto db_not_ready
if "!CNT!"=="0" goto empty_db

rem ---- 2. 算数据指纹，与上次快照比对，避免重复备份 ----
set "SUM="
del /q "%QOUT%" >nul 2>&1
"%MYSQL%" -u%DB_USER% -p%DB_PASS% -N -B -e "SELECT IFNULL(SUM(score),0) FROM %DB_NAME%.user;" >"%QOUT%" 2>"%ERRLOG%"
if exist "%QOUT%" for /f "delims=" %%r in ("%QOUT%") do if not defined SUM set "SUM=%%r"
if not defined SUM set "SUM=0"
set "CUR=!CNT!#!SUM!"

set "PREV="
if exist "%SNAP_AUTO%\.last-state" for /f "delims=" %%r in ("%SNAP_AUTO%\.last-state") do set "PREV=%%r"

if "!CUR!"=="!PREV!" (
  echo       数据没变化，跳过自动快照（当前 !CNT! 条用户）。
  exit /b 0
)

rem ---- 3. 自动快照 ----
set "FILE=%SNAP_AUTO%\snake_game_%STAMP%.sql"
"%MYSQLDUMP%" -u%DB_USER% -p%DB_PASS% ^
  --databases %DB_NAME% --add-drop-table --single-transaction --no-tablespaces ^
  --triggers --routines --events --default-character-set=utf8mb4 --set-gtid-purged=OFF ^
  > "%FILE%" 2>"%ERRLOG%"

set "SZ=0"
for %%f in ("%FILE%") do set "SZ=%%~zf"
if "!SZ!" LSS 500 (
  echo       [警告] 自动快照失败，可手动运行 db-backup\backup-db.cmd 查看报错。
  del /q "%FILE%" >nul 2>&1
  exit /b 0
)

copy /y "%FILE%" "%SNAP_LATEST%\snake_game_latest.sql" >nul 2>&1
>"%SNAP_AUTO%\.last-state" echo !CUR!
set "NOW=%DS:~0,4%-%DS:~4,2%-%DS:~6,2% %TS:~0,2%:%TS:~3,2%:%TS:~6,2%"
>>"%HISTORY%" echo !NOW!  ^|  AUTO  ^|  snake_game_%STAMP%.sql  ^|  用户数 !CNT!  ^|  !SZ! 字节

echo       已自动快照 !CNT! 条用户数据 -^> snapshots\auto\snake_game_%STAMP%.sql

rem ---- 4. 轮换：只保留最近 10 份自动快照 ----
set /a K=0
for /f "delims=" %%f in ('dir /b /a-d /o-d "%SNAP_AUTO%\*.sql" 2^>nul') do (
  set /a K+=1
  if !K! GTR 10 del /q "%SNAP_AUTO%\%%f" >nul 2>&1
)

exit /b 0


rem ============================================================
rem  分支：连不上库 / 库还没建
rem ============================================================
:db_not_ready
if exist "%SNAP_LATEST%\snake_game_latest.sql" (
  echo       数据库还没就绪，但备份仓里已有备份：
  echo       若启动后发现玩家数据不见，运行 db-backup\restore-db.cmd 即可恢复。
) else (
  echo       数据库还没就绪（首次运行属正常，后端启动时会自动建库建表）。
)
exit /b 0


rem ============================================================
rem  分支：库在、但一条用户都没有 —— 判断是"首次运行"还是"数据丢了"
rem ============================================================
:empty_db
set /a BAK=0
for /f "delims=" %%f in ('dir /b /a-d "%SNAP_MANUAL%\*.sql" 2^>nul') do set /a BAK+=1
for /f "delims=" %%f in ('dir /b /a-d "%SNAP_AUTO%\*.sql" 2^>nul') do set /a BAK+=1

if !BAK! GTR 0 (
  echo.
  echo       **********************************************************
  echo       [警告] 数据库里现在是空的，但备份仓里有 !BAK! 份历史备份。
  echo              数据很可能是被重置掉了（这台机器开机会清数据）。
  echo              要恢复请双击运行：db-backup\restore-db.cmd
  echo       **********************************************************
  echo.
) else (
  echo       数据库是空的（还没有任何玩家注册，属于首次运行，无需恢复）。
)
exit /b 0
