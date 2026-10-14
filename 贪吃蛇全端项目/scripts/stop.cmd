@echo off
rem ============================================================
rem  stop.cmd   一键停止（后端 + 前端）
rem ------------------------------------------------------------
rem  原理：按端口找进程号（8080=后端，5173=前端），然后杀掉。
rem  比按进程名杀更安全，不会误杀 IDEA、其他 java 程序。
rem ============================================================
setlocal enabledelayedexpansion
chcp 936 >nul 2>&1
title 贪吃蛇项目 - 停止

echo ============================================================
echo   贪吃蛇项目  一键停止
echo ============================================================
echo.

rem ---- 停后端（8080）----
set "FOUND=0"
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /r /c:":8080 .*LISTENING"') do (
  if not "%%p"=="0" (
    echo   停止后端 PID %%p ...
    taskkill /F /PID %%p >nul 2>&1
    set "FOUND=1"
  )
)
if "!FOUND!"=="0" echo   后端没有在运行（8080 未监听）

rem ---- 停前端（5173）----
set "FOUND=0"
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /r /c:":5173 .*LISTENING"') do (
  if not "%%p"=="0" (
    echo   停止前端 PID %%p ...
    taskkill /F /PID %%p >nul 2>&1
    set "FOUND=1"
  )
)
if "!FOUND!"=="0" echo   前端没有在运行（5173 未监听）

echo.
echo   完成。相关窗口如果没有自动关闭，手动关掉即可。
echo ------------------------------------------------------------
timeout /t 3 /nobreak >nul
