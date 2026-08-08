@echo off
setlocal
where godot >nul 2>nul
if %errorlevel%==0 (
  godot --headless --path "%~dp0project" --script res://tests/smoke_test.gd
  exit /b %errorlevel%
)
where godot4 >nul 2>nul
if %errorlevel%==0 (
  godot4 --headless --path "%~dp0project" --script res://tests/smoke_test.gd
  exit /b %errorlevel%
)
echo Godot 4.7.1 executable was not found in PATH.
exit /b 1
