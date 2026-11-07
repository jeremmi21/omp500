@echo off
REM OMP500 install wrapper for Windows — delegates to bash via Git Bash
where bash >nul 2>nul
if %ERRORLEVEL% neq 0 (
  echo [FAIL] bash not found. Install Git for Windows (includes Git Bash) from https://git-scm.com/download/win
  exit /b 1
)
bash "%~dp0install.sh" %*
