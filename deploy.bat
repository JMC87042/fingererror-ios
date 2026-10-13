@echo off
cd /d "%~dp0"
call npx wrangler pages deploy . --project-name fingererror --branch fingererror
pause
