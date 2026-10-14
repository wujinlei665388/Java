@echo off
rem ============================================================
rem  _db.cmd   备份仓公共环境脚本（被本目录下其他脚本 call）
rem ------------------------------------------------------------
rem  本文件属于 db-backup 独立备份仓，特点是【完全自包含】：
rem  不依赖 scripts\_env.cmd，把 db-backup 整个文件夹单独拷到
rem  任何地方（甚至拷到 U 盘），备份/恢复依然能正常工作。
rem  作用：
rem    1. 定位 VAULT（备份仓自身）和 PROJECT（项目根目录）
rem    2. 建好 snapshots 目录结构
rem    3. 探测 mysql.exe / mysqldump.exe
rem    4. 统一数据库连接参数（与 application.properties 一致）
rem    5. 生成时间戳，供备份文件命名
rem ============================================================

rem ---- 1. 目录定位 ----
rem 本脚本在 <项目根>\db-backup\ 下，所以上两层就是项目根
set "VAULT=%~dp0"
if "%VAULT:~-1%"=="\" set "VAULT=%VAULT:~0,-1%"
for %%i in ("%VAULT%\..") do set "PROJECT=%~fi"

set "SNAP=%VAULT%\snapshots"
set "SNAP_MANUAL=%SNAP%\manual"
set "SNAP_AUTO=%SNAP%\auto"
set "SNAP_LATEST=%SNAP%\latest"
set "LOGDIR=%VAULT%\logs"
set "HISTORY=%LOGDIR%\backup-history.log"
set "ERRLOG=%LOGDIR%\last-error.log"
rem 查询临时输出：mysql.exe 路径带空格，不能塞进 for /f 的 '...' 里，
rem 所以统一"先输出到本文件，再用 for /f 读文件"，见各脚本。
set "QOUT=%LOGDIR%\query.out"

if not exist "%SNAP_MANUAL%" mkdir "%SNAP_MANUAL%" >nul 2>&1
if not exist "%SNAP_AUTO%"   mkdir "%SNAP_AUTO%"   >nul 2>&1
if not exist "%SNAP_LATEST%" mkdir "%SNAP_LATEST%" >nul 2>&1
if not exist "%LOGDIR%"      mkdir "%LOGDIR%"      >nul 2>&1

rem ---- 2. 数据库连接参数（改密码只改这里）----
set "DB_NAME=snake_game"
set "DB_USER=root"
set "DB_PASS=123456"

rem ---- 3. 探测 MySQL 客户端 ----
set "MYSQL="
if exist "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" set "MYSQL=C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
if not defined MYSQL (
  for /d %%d in ("C:\Program Files\MySQL\*") do (
    if not defined MYSQL if exist "%%d\bin\mysql.exe" set "MYSQL=%%d\bin\mysql.exe"
  )
)
if not defined MYSQL for /f "delims=" %%i in ('where mysql 2^>nul') do if not defined MYSQL set "MYSQL=%%i"

rem mysqldump 与 mysql.exe 同目录
set "MYSQLDUMP="
if defined MYSQL for %%d in ("%MYSQL%") do if exist "%%~dpdmysqldump.exe" set "MYSQLDUMP=%%~dpdmysqldump.exe"
if not defined MYSQLDUMP for /f "delims=" %%i in ('where mysqldump 2^>nul') do if not defined MYSQLDUMP set "MYSQLDUMP=%%i"

rem ---- 4. 时间戳（用于备份文件命名）----
rem %DATE% 在不同系统语言下格式不同，先用 token 1 取纯日期部分
for /f "tokens=1" %%a in ("%DATE%") do set "DS=%%a"
set "DS=%DS:/=%"
set "DS=%DS:-=%"
set "DS=%DS:.=%"
rem %TIME% 形如 " 9:05:12.34"，先去掉前导空格再取 时分秒
set "TS=%TIME: =0%"
set "STAMP=%DS%-%TS:~0,2%%TS:~3,2%%TS:~6,2%"

exit /b 0
