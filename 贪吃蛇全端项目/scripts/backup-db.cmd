@echo off
rem ============================================================
rem  backup-db.cmd   （转发入口，真正的备份逻辑已迁到独立备份仓）
rem ------------------------------------------------------------
rem  2026-10-14 起，备份文件统一存放于 db-backup\snapshots\，
rem  见 db-backup\README.md。
rem  本文件保留只是为了兼容老习惯：双击它 = 双击 db-backup\backup-db.cmd
rem ============================================================
chcp 936 >nul 2>&1
call "%~dp0..\db-backup\backup-db.cmd"
