@echo off
setlocal enabledelayedexpansion

rem =====================================================================
rem  HARA dev environment restart
rem  Restarts: 1) Postgres DB (docker), 2) Backend API, 3) Frontend admin,
rem            4) Mobile app (Flutter, served to the browser)
rem  Portable: paths are resolved relative to this script's own location,
rem  so it works from any drive/user/machine as long as the repo layout
rem  (backend/, frontend/) is intact next to this file.
rem =====================================================================

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

set "FRONTEND_DIR=%ROOT%\frontend"
set "MOBILE_DIR=%ROOT%\mobile"
set "BACKEND_PORT=5080"
set "FRONTEND_PORT=5173"
rem  5174 is fixed on purpose: the backend only allows browser calls from this port (CORS).
set "MOBILE_PORT=5174"
set "DB_PORT=5432"

set "DB_OK=0"
set "BACKEND_OK=0"
set "FRONTEND_OK=0"
set "MOBILE_OK=0"

rem --- locate the backend .csproj dynamically (don't hardcode the path) ---
set "BACKEND_CSPROJ="
for /f "delims=" %%F in ('dir "%ROOT%\backend" /s /b /a-d 2^>nul ^| findstr /I "Api\.csproj$"') do (
    if not defined BACKEND_CSPROJ set "BACKEND_CSPROJ=%%F"
)

echo ============================================================
echo  HARA Dev Environment Restart
echo ============================================================
echo   Started: %DATE% %TIME%
echo   Root:    %ROOT%
echo.

call :RestartDatabase
call :RestartBackend
call :RestartFrontend
call :RestartMobile

echo.
echo ============================================================
echo  Summary
echo ============================================================
if "%DB_OK%"=="1"       (echo   [OK] Database  - up on port %DB_PORT%)       else (echo   [X]  Database  - FAILED, see log above)
if "%BACKEND_OK%"=="1"  (echo   [OK] Backend   - up on http://localhost:%BACKEND_PORT%) else (echo   [X]  Backend   - FAILED, see log above)
if "%FRONTEND_OK%"=="1" (echo   [OK] Frontend  - up on http://localhost:%FRONTEND_PORT%) else (echo   [X]  Frontend  - FAILED, see log above)
if "%MOBILE_OK%"=="1"   (echo   [OK] Mobile    - open http://localhost:%MOBILE_PORT% in your browser) else (echo   [X]  Mobile    - FAILED, see log above)
echo.
echo Done. Backend, admin panel and mobile app are running in their own windows.
echo The mobile app compiles on first start: if its page is blank, wait a minute and refresh.
pause
exit /b 0


rem =====================================================================
rem  Step 1: Database (docker CLI only - never touches Docker Desktop UI)
rem =====================================================================
:RestartDatabase
echo ============================================================
echo  Step 1/4: Database (Postgres in Docker)
echo ============================================================

where docker >nul 2>&1
if errorlevel 1 (
    echo   [X] "docker" was not found on PATH. Install Docker / add it to PATH.
    goto :eof
)

echo   -^> Checking docker daemon via CLI...
docker info >nul 2>&1
if errorlevel 1 (
    echo   [X] Docker daemon is not reachable ^("docker info" failed^).
    echo       Start Docker on this machine, then re-run this script.
    goto :eof
)
echo   [OK] Docker daemon is reachable.

echo   -^> Starting Postgres via docker compose ^(creates the container on first run^)...
docker compose -f "%ROOT%\docker-compose.yml" up -d >nul 2>&1
if errorlevel 1 (
    echo   [X] "docker compose up -d" failed. Run it manually to see details:
    echo       docker compose -f "%ROOT%\docker-compose.yml" up -d
    goto :eof
)

echo   [OK] Database container ^(hara-postgres^) is starting.
call :WaitForPort %DB_PORT% "Postgres DB" 30
set "DB_OK=1"
goto :eof


rem =====================================================================
rem  Step 2: Backend API (dotnet run)
rem =====================================================================
:RestartBackend
echo.
echo ============================================================
echo  Step 2/4: Backend API
echo ============================================================

where dotnet >nul 2>&1
if errorlevel 1 (
    echo   [X] "dotnet" was not found on PATH. Install the .NET SDK.
    goto :eof
)

if not defined BACKEND_CSPROJ (
    echo   [X] Could not locate a backend *Api.csproj under "%ROOT%\backend".
    goto :eof
)
echo   [OK] Backend project: !BACKEND_CSPROJ!

call :KillPort %BACKEND_PORT% "Backend API"

echo   -^> Starting backend ^(dotnet run^) in a new window...
start "HARA Backend API" /D "%ROOT%" cmd /k dotnet run --project "!BACKEND_CSPROJ!"

call :WaitForPort %BACKEND_PORT% "Backend API" 60
set "BACKEND_OK=1"
goto :eof


rem =====================================================================
rem  Step 3: Frontend admin app (vite dev server)
rem =====================================================================
:RestartFrontend
echo.
echo ============================================================
echo  Step 3/4: Frontend Admin App
echo ============================================================

where npm >nul 2>&1
if errorlevel 1 (
    echo   [X] "npm" was not found on PATH. Install Node.js.
    goto :eof
)

if not exist "%FRONTEND_DIR%" (
    echo   [X] Frontend directory not found: %FRONTEND_DIR%
    goto :eof
)

call :KillPort %FRONTEND_PORT% "Frontend Admin App"

if not exist "%FRONTEND_DIR%\node_modules" (
    echo   [WARN] node_modules missing - run "npm install" in %FRONTEND_DIR% first.
)

echo   -^> Starting frontend ^(npm run dev^) in a new window...
start "HARA Frontend Admin" /D "%FRONTEND_DIR%" cmd /k npm run dev

call :WaitForPort %FRONTEND_PORT% "Frontend Admin App" 45
set "FRONTEND_OK=1"
goto :eof


rem =====================================================================
rem  Step 4: Mobile app (flutter run, served to the browser)
rem =====================================================================
:RestartMobile
echo.
echo ============================================================
echo  Step 4/4: Mobile app ^(Flutter, in the browser^)
echo ============================================================

set "FLUTTER_BAT="
for /f "delims=" %%F in ('where flutter.bat 2^>nul') do (
    if not defined FLUTTER_BAT set "FLUTTER_BAT=%%F"
)
if not defined FLUTTER_BAT if exist "%USERPROFILE%\Desktop\flutter\bin\flutter.bat" set "FLUTTER_BAT=%USERPROFILE%\Desktop\flutter\bin\flutter.bat"
if not defined FLUTTER_BAT (
    echo   [X] Flutter was not found. Add its "bin" folder to PATH, or install it in %USERPROFILE%\Desktop\flutter
    goto :eof
)
echo   [OK] Flutter: !FLUTTER_BAT!

if not exist "%MOBILE_DIR%\pubspec.yaml" (
    echo   [X] Mobile project not found: %MOBILE_DIR%
    goto :eof
)

call :KillPort %MOBILE_PORT% "Mobile app"

echo   -^> Starting the mobile app ^(flutter run, web^) in a new window...
echo       The first start compiles the app and can take 1-2 minutes.
start "HARA Mobile (Flutter web)" /D "%MOBILE_DIR%" cmd /k ""!FLUTTER_BAT!" run -d web-server --web-port %MOBILE_PORT%"

call :WaitForPort %MOBILE_PORT% "Mobile app" 240
netstat -ano | findstr /R /C:":%MOBILE_PORT% .*LISTENING" >nul
if not errorlevel 1 set "MOBILE_OK=1"
goto :eof


rem =====================================================================
rem  Helpers
rem =====================================================================

rem Kill whatever process is listening on %1, labeled %2 (for messages)
:KillPort
set "KP_PORT=%~1"
set "KP_LABEL=%~2"
set "KP_PID="
for /f "tokens=5" %%P in ('netstat -ano ^| findstr /R /C:":%KP_PORT% .*LISTENING"') do (
    if not defined KP_PID set "KP_PID=%%P"
)
if defined KP_PID (
    echo   -^> Stopping existing %KP_LABEL% process ^(PID !KP_PID!^) on port %KP_PORT%...
    taskkill /PID !KP_PID! /F >nul 2>&1
    ping -n 2 127.0.0.1 >nul
    echo   [OK] %KP_LABEL% process stopped.
) else (
    echo   -^> %KP_LABEL% is not currently running ^(nothing listening on port %KP_PORT%^).
)
goto :eof

rem Poll localhost:%1 until it accepts connections, or %3 seconds pass
:WaitForPort
set "WP_PORT=%~1"
set "WP_LABEL=%~2"
set "WP_MAX=%~3"
set "WP_ELAPSED=0"
echo   -^> Waiting for %WP_LABEL% on port %WP_PORT%...

:WaitForPortLoop
netstat -ano | findstr /R /C:":%WP_PORT% .*LISTENING" >nul
if not errorlevel 1 (
    echo.
    echo   [OK] %WP_LABEL% is up on port %WP_PORT% ^(took !WP_ELAPSED!s^).
    goto :eof
)
if !WP_ELAPSED! GEQ %WP_MAX% (
    echo.
    echo   [WARN] %WP_LABEL% did not respond on port %WP_PORT% within %WP_MAX%s ^(it may still be starting^).
    goto :eof
)
ping -n 3 127.0.0.1 >nul
set /a WP_ELAPSED+=2
<nul set /p ".=."
goto :WaitForPortLoop
