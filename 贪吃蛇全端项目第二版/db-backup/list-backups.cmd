@echo off
rem ============================================================
rem  list-backups.cmd   查看备份仓状态（只读，不改任何数据）
rem ------------------------------------------------------------
rem  一眼看清三件事：
rem    1. 备份仓里有哪些备份、各多大、什么时候的
rem    2. 最新副本（latest）是哪一份
rem    3. 数据库里现在有多少用户、最高分是谁
rem  对比 1 和 3 就知道"备份跟库对不对得上"。
rem ============================================================
setlocal enabledelayedexpansion
chcp 936 >nul 2>&1
title 贪吃蛇项目 - 查看备份仓

call "%~dp0_db.cmd"

echo ============================================================
echo   备份仓状态   %VAULT%
echo ============================================================
echo.

rem ------------------------------------------------------------
rem  1. 手动备份
rem ------------------------------------------------------------
set /a MN=0
echo   --- 手动备份  snapshots\manual ---
if exist "%SNAP_MANUAL%\*.sql" (
  for /f "delims=" %%f in ('dir /b /a-d /o-d "%SNAP_MANUAL%\*.sql" 2^>nul') do (
    set /a MN+=1
    set "SZL=0"
    for %%g in ("%SNAP_MANUAL%\%%f") do set "SZL=%%~zg"
    set /a SZK=!SZL!/1024
    echo     %%f   ^( !SZK! KB ^)
  )
)
if !MN!==0 echo     （暂无，运行 backup-db.cmd 生成）
echo     共 !MN! 份
echo.

rem ------------------------------------------------------------
rem  2. 自动快照
rem ------------------------------------------------------------
set /a AN=0
echo   --- 自动快照  snapshots\auto ---
if exist "%SNAP_AUTO%\*.sql" (
  for /f "delims=" %%f in ('dir /b /a-d /o-d "%SNAP_AUTO%\*.sql" 2^>nul') do (
    set /a AN+=1
    if !AN! LEQ 5 (
      set "SZL=0"
      for %%g in ("%SNAP_AUTO%\%%f") do set "SZL=%%~zg"
      set /a SZK=!SZL!/1024
      echo     %%f   ^( !SZK! KB ^)
    )
  )
)
if !AN!==0 echo     （暂无，start.cmd 启动时会自动生成）
if !AN! GTR 5 echo     ... 另有 !AN! 份更早的快照未逐条列出
echo     共 !AN! 份（自动快照只保留最近 10 份）
echo.

rem ------------------------------------------------------------
rem  3. 最新副本
rem ------------------------------------------------------------
echo   --- 最新副本  snapshots\latest ---
if exist "%SNAP_LATEST%\snake_game_latest.sql" (
  for %%f in ("%SNAP_LATEST%\snake_game_latest.sql") do set "SZL=%%~zf"
  for %%f in ("%SNAP_LATEST%\snake_game_latest.sql") do set "TML=%%~tf"
  echo     snake_game_latest.sql   ^( !SZL! 字节  修改于 !TML! ^)
  echo     ^-^> restore-db.cmd 直接回车就用它
) else (
  echo     （暂无）
)
echo.

rem ------------------------------------------------------------
rem  4. 数据库现状
rem ------------------------------------------------------------
echo   --- 数据库现状   %DB_NAME% ---
if not defined MYSQL (
  echo     [提示] 没找到 mysql.exe，跳过。
  goto show_history
)
rem 不能把带引号的 mysql 路径塞进 for /f 的 '...'，改用临时文件再读
set "CNT="
del /q "%QOUT%" >nul 2>&1
"%MYSQL%" -u%DB_USER% -p%DB_PASS% -N -B -e "SELECT COUNT(*) FROM %DB_NAME%.user;" >"%QOUT%" 2>nul
if exist "%QOUT%" for /f "usebackq delims=" %%r in ("%QOUT%") do if not defined CNT set "CNT=%%r"
if not defined CNT (
  echo     [提示] 连不上库或库不存在（MySQL 没启动 / 还没建库）。
) else (
  echo     用户总数 : !CNT! 条
  echo     排行榜   :
  "%MYSQL%" -u%DB_USER% -p%DB_PASS% -e "USE %DB_NAME%; SELECT username, score FROM user ORDER BY score DESC, id ASC LIMIT 5;" 2>nul
)
echo.

:show_history
rem ------------------------------------------------------------
rem  5. 备份历史
rem ------------------------------------------------------------
echo   --- 最近的备份记录   logs\backup-history.log ---
if exist "%HISTORY%" (
  type "%HISTORY%"
) else (
  echo     （暂无记录）
)
echo.
echo ============================================================
echo   备份 : backup-db.cmd     恢复 : restore-db.cmd
echo ============================================================
echo.
pause
