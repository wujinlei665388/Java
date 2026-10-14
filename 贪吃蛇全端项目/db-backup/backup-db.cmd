@echo off
rem ============================================================
rem  backup-db.cmd   手动备份数据库 -> db-backup 独立备份仓
rem ------------------------------------------------------------
rem  这是"数据库 -> 备份文件夹"的正向通道。
rem  每跑一次就在 snapshots\manual\ 里落一份带时间戳的 .sql，
rem  同时刷新 snapshots\latest\snake_game_latest.sql（最新副本，
rem  恢复脚本默认用它），并在 logs\backup-history.log 里记账。
rem
rem  为什么备份文件不带路径以外的依赖？
rem    用的是 mysqldump --databases，文件里自带 CREATE DATABASE，
rem    所以哪怕整个库被删掉，恢复时也不用先手动建库。
rem ============================================================
setlocal
chcp 936 >nul 2>&1
title 贪吃蛇项目 - 备份数据库（独立备份仓）

call "%~dp0_db.cmd"

if not defined MYSQLDUMP (
  echo [错误] 没找到 mysqldump.exe，无法备份。
  echo        请确认 MySQL 8.0 已安装，或检查 _db.cmd 第 3 节的探测路径。
  pause
  exit /b 1
)

set "FILE=%SNAP_MANUAL%\snake_game_%STAMP%.sql"

echo ============================================================
echo   备份数据库  --^>  db-backup 独立备份仓
echo ============================================================
echo   数据库   : %DB_NAME%   ^( %DB_USER% / %DB_PASS% ^)
echo   备份仓   : %VAULT%
echo   输出文件 : %FILE%
echo.

rem ---- 导出（--databases 带建库语句；--add-drop-table 保证可重复恢复）----
"%MYSQLDUMP%" -u%DB_USER% -p%DB_PASS% ^
  --databases %DB_NAME% ^
  --add-drop-table ^
  --single-transaction ^
  --no-tablespaces ^
  --triggers --routines --events ^
  --default-character-set=utf8mb4 ^
  --set-gtid-purged=OFF ^
  > "%FILE%" 2>"%ERRLOG%"

rem ---- 校验：文件太小基本就是失败了（正常的 dump 至少几 KB）----
for %%f in ("%FILE%") do set "SZ=%%~zf"
if not defined SZ set "SZ=0"
if %SZ% LSS 500 (
  echo   [错误] 备份失败！文件大小只有 %SZ% 字节。
  echo.
  if exist "%ERRLOG%" type "%ERRLOG%"
  echo.
  echo   常见原因：MySQL 服务没启动 / 密码不是 %DB_PASS% / 库 %DB_NAME% 不存在。
  echo   临时文件位置：%FILE%
  echo.
  echo ------------------------------------------------------------
  pause
  exit /b 1
)

rem ---- 刷新"最新副本"，恢复脚本默认用这个 ----
copy /y "%FILE%" "%SNAP_LATEST%\snake_game_latest.sql" >nul 2>&1

rem ---- 统计当前数据量，顺便验证库真的连上了 ----
rem 不能把带引号的 mysql 路径塞进 for /f 的 '...'，改用临时文件再读
set "CNT=?"
del /q "%QOUT%" >nul 2>&1
"%MYSQL%" -u%DB_USER% -p%DB_PASS% -N -B -e "SELECT COUNT(*) FROM %DB_NAME%.user;" >"%QOUT%" 2>nul
if exist "%QOUT%" for /f "delims=" %%r in ("%QOUT%") do set "CNT=%%r"

rem ---- 记账 ----
set "NOW=%DS:~0,4%-%DS:~4,2%-%DS:~6,2% %TS:~0,2%:%TS:~3,2%:%TS:~6,2%"
>>"%HISTORY%" echo %NOW%  ^|  MANUAL  ^|  snake_game_%STAMP%.sql  ^|  用户数 %CNT%  ^|  %SZ% 字节

echo   备份成功 [OK]
echo     文件大小 : %SZ% 字节
echo     用户数据 : %CNT% 条
echo     最新副本 : snapshots\latest\snake_game_latest.sql
echo     备份记录 : logs\backup-history.log
echo.
echo ------------------------------------------------------------
pause
