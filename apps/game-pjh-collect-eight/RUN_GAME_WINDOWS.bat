@echo off
setlocal
where godot >nul 2>nul
if %errorlevel%==0 (
  godot --path "%~dp0project"
  exit /b %errorlevel%
)
where godot4 >nul 2>nul
if %errorlevel%==0 (
  godot4 --path "%~dp0project"
  exit /b %errorlevel%
)
echo Godot 4.7.1 executable was not found in PATH.
echo Open project\project.godot from Godot Project Manager instead.
exit /b 1
