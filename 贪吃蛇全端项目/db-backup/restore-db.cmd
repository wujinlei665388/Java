@echo off
rem ============================================================
rem  restore-db.cmd   从 db-backup 独立备份仓恢复数据库
rem ------------------------------------------------------------
rem  这是"备份文件夹 -> 数据库"的反向通道。
rem  备份仓 / 数据库之间可以来回倒：backup-db.cmd 导出，
rem  restore-db.cmd 导入，两边数据始终对得上。
rem
rem  用法：双击运行 -> 列表里输入序号 -> 输入 Y 确认。
rem        直接回车 = 用最新一份（snapshots\latest\..._latest.sql）
rem  注意：恢复会先 DROP TABLE 再重建，当前库里的数据会被备份内容覆盖。
rem ============================================================
setlocal enabledelayedexpansion
chcp 936 >nul 2>&1
title 贪吃蛇项目 - 恢复数据库（独立备份仓）

call "%~dp0_db.cmd"

if not defined MYSQL (
  echo [错误] 没找到 mysql.exe，无法恢复。
  pause
  exit /b 1
)

echo ============================================================
echo   从备份恢复数据库   %DB_NAME%
echo ============================================================
echo   备份仓 : %VAULT%
echo.

rem ------------------------------------------------------------
rem  列出所有可选备份（手动在前、自动在后，各自按时间倒序）
rem ------------------------------------------------------------
set /a N=0
set "GOT=0"

echo   --- 手动备份  snapshots\manual ---
if exist "%SNAP_MANUAL%\*.sql" (
  for /f "delims=" %%f in ('dir /b /a-d /o-d "%SNAP_MANUAL%\*.sql" 2^>nul') do (
    set /a N+=1
    set "B!N!=%SNAP_MANUAL%\%%f"
    echo     [!N!] %%f   ^( %%~zf 字节 ^)
    set "GOT=1"
  )
)
if "!GOT!"=="0" echo     （暂无手动备份，可运行 backup-db.cmd 生成）

set "GOT=0"
echo.
echo   --- 自动快照  snapshots\auto ---
if exist "%SNAP_AUTO%\*.sql" (
  for /f "delims=" %%f in ('dir /b /a-d /o-d "%SNAP_AUTO%\*.sql" 2^>nul') do (
    set /a N+=1
    set "B!N!=%SNAP_AUTO%\%%f"
    echo     [!N!] %%f   ^( %%~zf 字节 ^)
    set "GOT=1"
  )
)
if "!GOT!"=="0" echo     （暂无自动快照，start.cmd 启动时会自动生成）

if !N!==0 (
  echo.
  echo   [提示] 备份仓里还没有任何备份，请先运行 backup-db.cmd。
  echo.
  echo ------------------------------------------------------------
  pause
  exit /b 1
)

echo.
echo   ----------------------------------------------------------
set /p PICK=  请输入要恢复的序号（直接回车 = 最新一份）:
if not defined PICK goto use_latest
if "!PICK!"=="0" goto use_latest
if not defined B!PICK! (
  echo.
  echo   [错误] 序号 !PICK! 不在列表里。
  echo.
  echo ------------------------------------------------------------
  pause
  exit /b 1
)
set "FILE=!B%PICK%!"
goto do_restore

:use_latest
if not exist "%SNAP_LATEST%\snake_game_latest.sql" (
  echo.
  echo   [错误] 没有最新副本，请从上面的列表里输入序号。
  echo.
  echo ------------------------------------------------------------
  pause
  exit /b 1
)
set "FILE=%SNAP_LATEST%\snake_game_latest.sql"

:do_restore
echo.
echo   恢复来源 : !FILE!
for %%f in ("!FILE!") do echo   文件大小 : %%~zf 字节
echo.
echo   --- 恢复前，当前库里的数据 ---
"%MYSQL%" -u%DB_USER% -p%DB_PASS% -e "USE %DB_NAME%; SELECT id, username, score FROM user ORDER BY id;" 2>nul
if errorlevel 1 echo     （读不到，可能是库还不存在）
echo.
set /p CONFIRM=  确定要用它覆盖当前数据库吗？（输入 Y 继续）:
if /i not "%CONFIRM%"=="Y" (
  echo.
  echo   已取消，数据库没有任何改动。
  echo.
  echo ------------------------------------------------------------
  pause
  exit /b 0
)

echo.
echo   正在恢复 ...
"%MYSQL%" -u%DB_USER% -p%DB_PASS% < "!FILE!" 2>"%ERRLOG%"
if errorlevel 1 (
  echo.
  echo   [错误] 恢复失败！错误信息：
  if exist "%ERRLOG%" type "%ERRLOG%"
  echo.
  echo   常见原因：MySQL 服务没启动 / 密码不是 %DB_PASS%。
  echo.
  echo ------------------------------------------------------------
  pause
  exit /b 1
)

rem ---- 恢复后刷新 latest 副本，保持"最新一份"始终指向上次用过的备份 ----
copy /y "!FILE!" "%SNAP_LATEST%\snake_game_latest.sql" >nul 2>&1

rem ---- 恢复后核对条数 ----
rem 不能把带引号的 mysql 路径塞进 for /f 的 '...'，改用临时文件再读
set "CNT=?"
del /q "%QOUT%" >nul 2>&1
"%MYSQL%" -u%DB_USER% -p%DB_PASS% -N -B -e "SELECT COUNT(*) FROM %DB_NAME%.user;" >"%QOUT%" 2>nul
if exist "%QOUT%" for /f "delims=" %%r in ("%QOUT%") do set "CNT=%%r"

set "NOW=%DS:~0,4%-%DS:~4,2%-%DS:~6,2% %TS:~0,2%:%TS:~3,2%:%TS:~6,2%"
>>"%HISTORY%" echo %NOW%  ^|  RESTORE  ^|  !FILE!  ^|  用户数 %CNT%

echo.
echo   恢复完成 [OK]   当前用户数据 %CNT% 条：
echo.
"%MYSQL%" -u%DB_USER% -p%DB_PASS% -e "USE %DB_NAME%; SELECT id, username, score FROM user ORDER BY score DESC, id ASC;" 2>nul
echo.
echo ------------------------------------------------------------
pause
