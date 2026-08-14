@echo off
setlocal
set "EXE=%~1"
if "%EXE%"=="" set "EXE=build\windows\Plakorov2.exe"

if not exist "%EXE%" (
  echo Executable not found: %EXE%
  echo Usage: %~nx0 [path\to\Plakorov2.exe]
  exit /b 2
)

echo [12.6b] Windows phase 1/2: write persistence probe
"%EXE%" -- --m12.6b-gate --phase=write
if errorlevel 1 exit /b %errorlevel%

echo [12.6b] Windows phase 2/2: restart and verify persistence probe
"%EXE%" -- --m12.6b-gate --phase=verify
if errorlevel 1 exit /b %errorlevel%

echo [12.6b] Windows export gate PASSED
exit /b 0
