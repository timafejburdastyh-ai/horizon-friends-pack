@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1" -Action Launcher
if errorlevel 1 pause
