@echo off
rem ============================================================
rem  start.cmd   一键启动（MySQL检查 + 后端 + 前端）
rem ------------------------------------------------------------
rem  用法：双击本文件即可。
rem  顺序：1.检查MySQL  2.检查8080是否已占用  3.编译后端+拷贝依赖
rem        4.启动后端  5.启动前端  6.打开浏览器
rem
rem  2026-10-10 重要修复：
rem    旧版用 start ... cmd /k "set /p CP=<cp.txt & java ... %%CP%%"
rem    启动后端。cmd 会把整行命令一次性解析，%%CP%% 在 set /p 执行
rem    之前就被展开（结果为空），后端窗口报
rem    "Could not find or load main class"，怎么都起不来。
rem    现改为：dependency:copy-dependencies 把依赖 jar 拷到
rem    target\lib，直接 -cp "target\classes;target\lib\*" 启动，
rem    不再需要 cp.txt，也没有变量展开时序问题。
rem ============================================================
setlocal enabledelayedexpansion
chcp 936 >nul 2>&1
title 贪吃蛇项目 - 启动

call "%~dp0_env.cmd"

echo ============================================================
echo   贪吃蛇项目  一键启动
echo ============================================================
echo   项目根目录 : %ROOT%
echo   后端目录   : %BACKEND%
echo   前端目录   : %FRONTEND%
echo ------------------------------------------------------------

if not defined JAVA_HOME ( echo [错误] 没找到 JDK，无法启动后端。 & pause & exit /b 1 )
if not defined MVN       ( echo [错误] 没找到 Maven，无法启动后端。 & pause & exit /b 1 )
if not defined NODE      ( echo [错误] 没找到 Node，无法启动前端。 & pause & exit /b 1 )

rem ------------------------------------------------------------
rem  1. 检查 MySQL
rem ------------------------------------------------------------
echo [1/5] 检查 MySQL 数据库 ...
netstat -an | findstr /r /c:":3306 .*LISTENING" >nul 2>&1
if errorlevel 1 (
  echo       3306 端口没在监听，MySQL 可能没启动。
  echo       尝试通过 Windows 服务启动 MySQL ...
  net start MySQL80 >nul 2>&1
  if errorlevel 1 net start MySQL >nul 2>&1
  timeout /t 5 /nobreak >nul
  netstat -an | findstr /r /c:":3306 .*LISTENING" >nul 2>&1
  if errorlevel 1 (
    echo       [警告] MySQL 仍未启动，后端连不上数据库会报错。
    echo              请手动启动 MySQL 后重新运行本脚本。
  ) else (
    echo       MySQL 已启动 [OK]
  )
) else (
  echo       MySQL 正在运行 [OK]
)

rem ------------------------------------------------------------
rem  2. 检查后端端口
rem ------------------------------------------------------------
echo [2/5] 检查后端端口 8080 ...
set "BACKEND_RUNNING=0"
netstat -an | findstr /r /c:":8080 .*LISTENING" >nul 2>&1
if not errorlevel 1 (
  echo       8080 已在监听，后端应该已经在跑了，跳过启动。
  set "BACKEND_RUNNING=1"
)

if "!BACKEND_RUNNING!"=="0" (
  rem ----------------------------------------------------------
  rem  3. 编译后端 + 拷贝依赖到 target\lib
  rem     每次开机 target 都会被删掉，所以必须重新编译
  rem ----------------------------------------------------------
  echo [3/5] 编译后端（首次或清理后需要一点时间）...
  pushd "%BACKEND%"
  call "%MVN%" -o -q clean compile > "%ROOT%\scripts\backend-build.log" 2>&1
  if errorlevel 1 (
    echo       离线编译失败，尝试联网编译 ...
    call "%MVN%" -q clean compile > "%ROOT%\scripts\backend-build.log" 2>&1
  )
  if errorlevel 1 (
    popd
    echo       [错误] 后端编译失败！详细日志：
    echo              %ROOT%\scripts\backend-build.log
    pause
    exit /b 1
  )
  popd
  echo       编译成功 [OK]

  echo       拷贝运行时依赖到 target\lib ...
  pushd "%BACKEND%"
  call "%MVN%" -o -q org.apache.maven.plugins:maven-dependency-plugin:3.5.0:copy-dependencies -DoutputDirectory=target\lib -DincludeScope=runtime >> "%ROOT%\scripts\backend-build.log" 2>&1
  if errorlevel 1 (
    echo       离线拷贝失败，尝试联网 ...
    call "%MVN%" -q org.apache.maven.plugins:maven-dependency-plugin:3.5.0:copy-dependencies -DoutputDirectory=target\lib -DincludeScope=runtime >> "%ROOT%\scripts\backend-build.log" 2>&1
  )
  if errorlevel 1 (
    popd
    echo       [错误] 依赖拷贝失败！详细日志：
    echo              %ROOT%\scripts\backend-build.log
    pause
    exit /b 1
  )
  popd
  if not exist "%BACKEND%\target\lib" (
    echo       [错误] target\lib 没生成，请看 backend-build.log
    pause
    exit /b 1
  )
  echo       依赖就绪 [OK]

  rem ----------------------------------------------------------
  rem  4. 启动后端
  rem     -cp "target\classes;target\lib\*"  java 会自己展开 *
  rem ----------------------------------------------------------
  echo       正在新窗口启动后端（端口 8080）...
  start "贪吃蛇-后端 8080" cmd /k "cd /d "%BACKEND%" & "%JAVA_HOME%\bin\java.exe" -Dfile.encoding=UTF-8 -cp "target\classes;target\lib\*" com.fenglin.springboottest.SpringBootTestApplication"

  rem 等后端就绪（最多 60 秒）
  echo       等待后端就绪 ...
  set "BACKEND_UP=0"
  for /l %%i in (1,1,60) do (
    if "!BACKEND_UP!"=="0" (
      timeout /t 1 /nobreak >nul
      netstat -an | findstr /r /c:":8080 .*LISTENING" >nul 2>&1
      if not errorlevel 1 set "BACKEND_UP=1"
    )
  )
  if "!BACKEND_UP!"=="1" ( echo       后端已就绪 [OK] ) else ( echo       [警告] 后端 60 秒内没起来，请看"贪吃蛇-后端"窗口的报错。 )
)

rem ------------------------------------------------------------
rem  5. 前端
rem     缺 node_modules 时自动 npm install（开机重置后必然缺）
rem ------------------------------------------------------------
echo [4/5] 准备前端 ...
if not exist "%FRONTEND%\node_modules" (
  echo       没找到 node_modules，正在执行 npm install（需要联网，稍等）...
  pushd "%FRONTEND%"
  call "%NPM%" install --no-audit --no-fund --registry https://registry.npmmirror.com > "%ROOT%\scripts\frontend-install.log" 2>&1
  popd
  if not exist "%FRONTEND%\node_modules" (
    echo       [错误] npm install 失败！详细日志：
    echo              %ROOT%\scripts\frontend-install.log
    pause
    exit /b 1
  )
  echo       依赖安装完成 [OK]
) else (
  echo       node_modules 已存在 [OK]
)

echo       正在新窗口启动前端（端口 5173）...
start "贪吃蛇-前端 5173" cmd /k "cd /d "%FRONTEND%" & "%NODE%" node_modules\vite\bin\vite.js --host 127.0.0.1"

echo       等待前端就绪 ...
set "FRONTEND_UP=0"
for /l %%i in (1,1,30) do (
  if "!FRONTEND_UP!"=="0" (
    timeout /t 1 /nobreak >nul
    netstat -an | findstr /r /c:":5173 .*LISTENING" >nul 2>&1
    if not errorlevel 1 set "FRONTEND_UP=1"
  )
)
if "!FRONTEND_UP!"=="1" ( echo       前端已就绪 [OK] ) else ( echo       [警告] 前端 30 秒内没起来，请看"贪吃蛇-前端"窗口的报错。 )

rem ------------------------------------------------------------
rem  6. 打开浏览器
rem ------------------------------------------------------------
echo [5/5] 打开浏览器 ...
start "" "http://127.0.0.1:5173/"

echo ------------------------------------------------------------
echo   启动完成！
echo     前端页面 : http://127.0.0.1:5173/
echo     后端接口 : http://127.0.0.1:8080/api/user/login
echo     测试账号 : admin / 123456
echo   停止服务 : 关闭两个新开的窗口，或运行 stop.cmd
echo ============================================================
echo.
pause
