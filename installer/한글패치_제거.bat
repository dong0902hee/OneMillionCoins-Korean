@echo off
title One Million Coins Korean Patch - Uninstall
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0patch\install.ps1" -Uninstall
echo.
pause
