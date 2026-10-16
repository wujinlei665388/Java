@echo off
rem ============================================================
rem  restore-db.cmd  （转发入口，真正的恢复逻辑已迁到独立备份仓）
rem ------------------------------------------------------------
rem  2026-10-14 起，恢复统一走 db-backup\restore-db.cmd，
rem  它会列出 db-backup\snapshots\ 下所有备份供你选择。
rem  见 db-backup\README.md。
rem  本文件保留只是为了兼容老习惯：双击它 = 双击 db-backup\restore-db.cmd
rem ============================================================
chcp 936 >nul 2>&1
call "%~dp0..\db-backup\restore-db.cmd"
