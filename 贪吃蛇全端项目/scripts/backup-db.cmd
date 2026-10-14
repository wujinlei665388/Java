@echo off
rem ============================================================
rem  backup-db.cmd   备份数据库到 sql\backup\ 目录
rem ------------------------------------------------------------
rem  为什么需要这个？
rem    这台电脑每次重置后 MySQL 里的数据可能丢失。
rem    跑一次备份，把 .sql 文件存在项目里（跟着项目走），
rem    重置后用 restore-db.cmd 一条命令就能恢复所有用户和分数。
rem  建议：玩出高分后跑一次备份。
rem ============================================================
setlocal
chcp 936 >nul 2>&1
title 贪吃蛇项目 - 备份数据库

call "%~dp0_env.cmd"

if not defined MYSQL (
  echo [错误] 没找到 mysql.exe，无法备份
  pause
  exit /b 1
)

if not exist "%ROOT%\sql\backup" mkdir "%ROOT%\sql\backup"

rem 用日期做文件名，多次备份不会互相覆盖
for /f "tokens=1-3 delims=/- " %%a in ('date /t') do set "D=%%a%%b%%c"
set "FILE=%ROOT%\sql\backup\snake_game_%D%.sql"

echo ============================================================
echo   备份数据库 snake_game
echo ============================================================
echo   输出文件: %FILE%
echo.

rem --databases 会带上 CREATE DATABASE，恢复时不用手动建库
"%MYSQLDUMP%" -uroot -p123456 --databases snake_game --add-drop-table > "%FILE%" 2>nul

if exist "%FILE%" (
  for %%f in ("%FILE%") do echo   备份成功 [OK]  大小: %%~zf 字节
) else (
  echo   [错误] 备份失败，请检查 MySQL 是否已启动、密码是否正确。
)

echo.
echo ------------------------------------------------------------
pause
