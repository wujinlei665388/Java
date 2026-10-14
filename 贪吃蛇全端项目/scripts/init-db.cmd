@echo off
rem ============================================================
rem  init-db.cmd   初始化数据库（建库 + 建表 + 默认账号）
rem ------------------------------------------------------------
rem  平时不需要手动跑：后端启动时会自动建库建表。
rem  什么时候需要跑？
rem    - 想彻底重置数据（先删库再重建）
rem    - 后端连库报错时，用来确认 MySQL 账号密码是否正常
rem ============================================================
setlocal
chcp 936 >nul 2>&1
title 贪吃蛇项目 - 初始化数据库

call "%~dp0_env.cmd"

if not defined MYSQL (
  echo [错误] 没找到 mysql.exe，请手动执行 sql\snake_game.sql
  pause
  exit /b 1
)

echo ============================================================
echo   初始化数据库 snake_game
echo ============================================================
echo   MySQL 客户端: %MYSQL%
echo   账号        : root / 123456
echo.
set /p CONFIRM=确定要执行吗？（会删除已有数据，输入 Y 继续）:
if /i not "%CONFIRM%"=="Y" (
  echo 已取消。
  pause
  exit /b 0
)

echo.
echo   正在导入 sql\snake_game.sql ...
"%MYSQL%" -uroot -p123456 < "%ROOT%\sql\snake_game.sql"
if errorlevel 1 (
  echo.
  echo   [错误] 导入失败！请检查 MySQL 是否已启动、密码是否为 123456。
  pause
  exit /b 1
)

echo.
echo   导入完成，当前数据：
"%MYSQL%" -uroot -p123456 -e "USE snake_game; SELECT id, username, score, create_time FROM user;" 2>nul
echo.
echo ------------------------------------------------------------
pause
