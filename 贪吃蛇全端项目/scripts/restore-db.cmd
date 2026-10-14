@echo off
rem ============================================================
rem  restore-db.cmd   从 sql\backup\ 里最新的备份恢复数据库
rem ------------------------------------------------------------
rem  电脑重置 / MySQL 数据丢失后，跑这个脚本就能把
rem  之前的用户和最高分全部恢复回来。
rem ============================================================
setlocal enabledelayedexpansion
chcp 936 >nul 2>&1
title 贪吃蛇项目 - 恢复数据库

call "%~dp0_env.cmd"

if not defined MYSQL (
  echo [错误] 没找到 mysql.exe，无法恢复
  pause
  exit /b 1
)

if not exist "%ROOT%\sql\backup" (
  echo [提示] 还没有任何备份（sql\backup 目录不存在）。
  echo        请先运行 backup-db.cmd 生成备份。
  pause
  exit /b 1
)

rem ---- 找出最新的一份备份 ----
set "LATEST="
for /f "delims=" %%f in ('dir /b /o-d "%ROOT%\sql\backup\*.sql" 2^>nul') do (
  if not defined LATEST set "LATEST=%ROOT%\sql\backup\%%f"
)

if not defined LATEST (
  echo [提示] sql\backup 目录里没有 .sql 备份文件。
  pause
  exit /b 1
)

echo ============================================================
echo   从备份恢复数据库
echo ============================================================
echo   备份文件: !LATEST!
echo.
set /p CONFIRM=确定要恢复吗？（会覆盖当前数据，输入 Y 继续）:
if /i not "%CONFIRM%"=="Y" (
  echo 已取消。
  pause
  exit /b 0
)

echo.
echo   正在恢复 ...
"%MYSQL%" -uroot -p123456 < "!LATEST!"
if errorlevel 1 (
  echo.
  echo   [错误] 恢复失败！请检查 MySQL 是否已启动、密码是否为 123456。
  pause
  exit /b 1
)

echo.
echo   恢复完成，当前数据：
"%MYSQL%" -uroot -p123456 -e "USE snake_game; SELECT id, username, score FROM user;" 2>nul
echo.
echo ------------------------------------------------------------
pause
