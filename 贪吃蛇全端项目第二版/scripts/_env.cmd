@echo off
rem ============================================================
rem  _env.cmd  环境自动探测脚本（被其他脚本 call 调用）
rem ------------------------------------------------------------
rem  作用：自动找到 java / maven / mysql / node 的路径，
rem        并清理掉会干扰 SpringBoot 的环境变量。
rem  设计原则：
rem    - 全部用相对路径，整个项目文件夹可以随便挪位置
rem    - 不依赖 node_modules、target 里面的任何内容
rem    - 路径探测失败会给出明确中文提示，不会静默失败
rem ============================================================

rem ---- 项目根目录（本脚本在 scripts\ 下，所以往上一层就是根目录）----
set "ROOT=%~dp0.."
pushd "%ROOT%" >nul 2>&1
set "ROOT=%CD%"
popd >nul 2>&1

set "FRONTEND=%ROOT%\frontend"
set "BACKEND=%ROOT%\backend\springBootTest"

rem ============================================================
rem  *** 关键：清理干扰变量 ***
rem  WorkBuddy / CodeBuddy 运行时会设置 SERVER__PORT=58049，
rem  Spring Boot 的"松散绑定"会把它当成 server.port，
rem  优先级高于 application.properties，导致后端抢不到 8080 而启动失败。
rem  这里必须清掉（application.properties 里也做了 SNAKE_PORT 兜底）。
rem ============================================================
set "SERVER__PORT="
set "SERVER__HOST="

rem ============================================================
rem  1. JDK（Java 21 优先；java.version=17 但 21 完全兼容）
rem ============================================================
set "JAVA_HOME="
if exist "C:\Program Files\Zulu\zulu-21\bin\java.exe" set "JAVA_HOME=C:\Program Files\Zulu\zulu-21"
if not defined JAVA_HOME if exist "C:\Program Files\Java\jdk-21\bin\java.exe" set "JAVA_HOME=C:\Program Files\Java\jdk-21"
if not defined JAVA_HOME if exist "C:\Program Files\Eclipse Adoptium\jdk-21.0.5.11-hotspot\bin\java.exe" set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-21.0.5.11-hotspot"
rem 兜底：如果都不在，尝试用 PATH 里的 java
if not defined JAVA_HOME (
  for /f "delims=" %%i in ('where java 2^>nul') do (
    if not defined JAVA_HOME (
      set "JAVA_HOME=%%~dpi.."
    )
  )
)
if defined JAVA_HOME set "PATH=%JAVA_HOME%\bin;%PATH%"

rem ============================================================
rem  2. Maven
rem  本机没有独立安装 maven，用 IntelliJ IDEA 自带的 maven。
rem  如果 IDEA 版本升级/换路径了，就在下面加一行新的 if exist。
rem ============================================================
set "MVN="
if exist "D:\IntelliJ IDEA 2024.3.2.2\plugins\maven\lib\maven3\bin\mvn.cmd" set "MVN=D:\IntelliJ IDEA 2024.3.2.2\plugins\maven\lib\maven3\bin\mvn.cmd"
if not defined MVN if exist "C:\Program Files\JetBrains\IntelliJ IDEA 2024.3.2\plugins\maven\lib\maven3\bin\mvn.cmd" set "MVN=C:\Program Files\JetBrains\IntelliJ IDEA 2024.3.2\plugins\maven\lib\maven3\bin\mvn.cmd"
if not defined MVN (
  for /d %%d in ("D:\IntelliJ IDEA*") do (
    if not defined MVN if exist "%%d\plugins\maven\lib\maven3\bin\mvn.cmd" set "MVN=%%d\plugins\maven\lib\maven3\bin\mvn.cmd"
  )
)
if not defined MVN (
  for /d %%d in ("C:\Program Files\JetBrains\IntelliJ IDEA*") do (
    if not defined MVN if exist "%%d\plugins\maven\lib\maven3\bin\mvn.cmd" set "MVN=%%d\plugins\maven\lib\maven3\bin\mvn.cmd"
  )
)
rem 兜底：PATH 里如果有 mvn
if not defined MVN for /f "delims=" %%i in ('where mvn 2^>nul') do if not defined MVN set "MVN=%%i"

rem ============================================================
rem  3. MySQL 客户端（只在需要导入/备份数据库时用到）
rem ============================================================
set "MYSQL="
if exist "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" set "MYSQL=C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
if not defined MYSQL (
  for /d %%d in ("C:\Program Files\MySQL\*") do (
    if not defined MYSQL if exist "%%d\bin\mysql.exe" set "MYSQL=%%d\bin\mysql.exe"
  )
)
if not defined MYSQL for /f "delims=" %%i in ('where mysql 2^>nul') do if not defined MYSQL set "MYSQL=%%i"

rem mysqldump: 备份脚本用；它和 mysql.exe 同目录
set "MYSQLDUMP="
if defined MYSQL for %%d in ("%MYSQL%") do if exist "%%~dpdmysqldump.exe" set "MYSQLDUMP=%%~dpdmysqldump.exe"
if not defined MYSQLDUMP for /f "delims=" %%i in ('where mysqldump 2^>nul') do if not defined MYSQLDUMP set "MYSQLDUMP=%%i"

rem ============================================================
rem  4. Node（优先 WorkBuddy 自带的，其次系统安装的）
rem ============================================================
set "NODE="
set "NPM="
if exist "C:\Users\Administrator\.workbuddy\binaries\node\versions\22.22.2-2\node.exe" (
  set "NODE=C:\Users\Administrator\.workbuddy\binaries\node\versions\22.22.2-2\node.exe"
  set "NPM=C:\Users\Administrator\.workbuddy\binaries\node\versions\22.22.2-2\npm.cmd"
)
if not defined NODE if exist "D:\Program Files\nodejs\node.exe" (
  set "NODE=D:\Program Files\nodejs\node.exe"
  set "NPM=D:\Program Files\nodejs\npm.cmd"
)

rem ---- 如果 node 官方目录里没有 npm.cmd（便携版常见），兜底找一下 ----
if defined NODE if not exist "%NPM%" (
  for /f "delims=" %%i in ('where npm 2^>nul') do if not defined NPM_ALT set "NPM_ALT=%%i"
  if defined NPM_ALT set "NPM=%NPM_ALT%"
)

rem ============================================================
rem  5. 报告探测结果
rem ============================================================
if not defined JAVA_HOME echo [环境] [X] 没找到 JDK，请检查 _env.cmd 里的 JAVA_HOME 配置
if not defined MVN       echo [环境] [X] 没找到 Maven，请检查 _env.cmd 里的 MVN 配置
if not defined NODE      echo [环境] [X] 没找到 Node，请检查 _env.cmd 里的 NODE 配置
if not defined MYSQL     echo [环境] ! 没找到 MySQL 客户端（仅影响数据库导入/备份，不影响启动）
