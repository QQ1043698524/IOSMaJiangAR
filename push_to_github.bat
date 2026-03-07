@echo off
REM 此脚本用于绕过 PowerShell 执行策略限制，启动 Git 推送流程

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0push_to_github.ps1"
pause