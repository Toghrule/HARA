@echo off
setlocal enabledelayedexpansion

rem =====================================================================
rem  HARA pilot (test with real people)
rem  Starts a SEPARATE environment next to the dev one, so nothing of the
rem  dev data is touched:
rem    - database   hara_pilot             (own database, same Postgres)
rem    - API        http://localhost:5082  (Production mode, not 5080)
rem    - admin      http://localhost:5175  (admin panel for the pilot data)
rem    - tunnel     https://....trycloudflare.com (the address the phones use)
rem  Needs: Docker running, backend\secrets\local-settings.json, and
rem  tools\cloudflared\cloudflared.exe. Stop everything by closing the windows.
rem =====================================================================

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

set "PILOT_DB=hara_pilot"
set "API_PORT=5082"
set "ADMIN_PORT=5175"
set "API_DIR=%ROOT%\backend\src\ui\Hara.Api"
set "CLOUDFLARED=%ROOT%\tools\cloudflared\cloudflared.exe"
set "CS=Host=localhost;Port=5432;Database=%PILOT_DB%;Username=postgres;Password=postgres"

echo ============================================================
echo  HARA pilot
echo ============================================================

if not exist "%ROOT%\backend\secrets\local-settings.json" (
    echo   [X] backend\secrets\local-settings.json is missing ^(the JWT key and admin password live there^).
    goto :end
)
if not exist "%CLOUDFLARED%" (
    echo   [X] tools\cloudflared\cloudflared.exe is missing.
    goto :end
)

echo.
echo  Step 1/5: Database
docker info >nul 2>&1
if errorlevel 1 (
    echo   [X] Docker is not running. Start Docker, then run this again.
    goto :end
)
docker compose -f "%ROOT%\docker-compose.yml" up -d >nul 2>&1
rem  Wait until Postgres answers
set "TRIES=0"
:waitdb
docker exec hara-postgres pg_isready -U postgres >nul 2>&1
if errorlevel 1 (
    set /a TRIES+=1
    if !TRIES! GEQ 30 (
        echo   [X] Postgres did not start.
        goto :end
    )
    ping -n 2 127.0.0.1 >nul
    goto :waitdb
)
docker exec hara-postgres psql -U postgres -tAc "SELECT 1 FROM pg_database WHERE datname='%PILOT_DB%'" | findstr 1 >nul
if errorlevel 1 (
    docker exec hara-postgres psql -U postgres -c "CREATE DATABASE %PILOT_DB%" >nul 2>&1
    echo   [OK] Created database %PILOT_DB%.
) else (
    echo   [OK] Database %PILOT_DB% exists.
)

echo.
echo  Step 2/5: Build the API ^(Release^)
rem  Stop an older pilot API first, it locks the files being built.
call :KillPort %API_PORT%
dotnet build "%API_DIR%\Hara.Api.csproj" -c Release -v q --nologo >nul
if errorlevel 1 (
    echo   [X] The build failed. Run:  dotnet build "%API_DIR%\Hara.Api.csproj" -c Release
    goto :end
)
echo   [OK] Built.

echo.
echo  Step 3/5: Bring the pilot database up to date
dotnet ef database update --connection "%CS%" --project "%ROOT%\backend\src\external\Hara.Persistence" --startup-project "%API_DIR%" --context ApplicationDbContext --configuration Release --no-build >nul 2>&1
if errorlevel 1 (
    echo   [X] Could not update the database. Run the same command without ">nul" to see why.
    goto :end
)
echo   [OK] Database is up to date.

echo.
echo  Step 4/5: API and admin panel
start "HARA Pilot API" /D "%API_DIR%" cmd /k "set ASPNETCORE_ENVIRONMENT=Production&& set ConnectionStrings__DefaultConnection=%CS%&& set Cors__AllowedOrigins__0=http://localhost:%ADMIN_PORT%&& dotnet bin\Release\net9.0\Hara.Api.dll --urls http://localhost:%API_PORT%"
call :KillPort %ADMIN_PORT%
start "HARA Pilot Admin" /D "%ROOT%\frontend" cmd /k "set VITE_API_BASE_URL=http://localhost:%API_PORT%&& npm run dev -- --port %ADMIN_PORT% --strictPort"

set "TRIES=0"
:waitapi
netstat -ano | findstr /R /C:":%API_PORT% .*LISTENING" >nul
if errorlevel 1 (
    set /a TRIES+=1
    if !TRIES! GEQ 30 (
        echo   [X] The API did not start. Look at the "HARA Pilot API" window.
        goto :end
    )
    ping -n 3 127.0.0.1 >nul
    goto :waitapi
)
echo   [OK] API is up on port %API_PORT%.

echo.
echo  Step 5/5: Tunnel ^(the public address^)
set "TUNNEL_LOG=%ROOT%\tools\cloudflared\tunnel.log"
set "TUNNEL_URL_FILE=%ROOT%\tools\cloudflared\current-url.txt"
del "%TUNNEL_LOG%" "%TUNNEL_URL_FILE%" >nul 2>&1
start "HARA Pilot Tunnel" cmd /k ""%CLOUDFLARED%" tunnel --url http://localhost:%API_PORT% --logfile "%TUNNEL_LOG%""

set "TRIES=0"
:waiturl
if exist "%TUNNEL_LOG%" powershell -NoProfile -Command "$m = Select-String -Path '%TUNNEL_LOG%' -Pattern 'https://[a-z0-9-]+\.trycloudflare\.com' -ErrorAction SilentlyContinue | Select-Object -First 1; if ($m) { $m.Matches[0].Value | Set-Content -NoNewline '%TUNNEL_URL_FILE%' }"
if not exist "%TUNNEL_URL_FILE%" (
    set /a TRIES+=1
    if !TRIES! GEQ 20 goto :nourl
    ping -n 3 127.0.0.1 >nul
    goto :waiturl
)
set /p PUBLIC_URL=<"%TUNNEL_URL_FILE%"
goto :summary
:nourl
set "PUBLIC_URL=(not found yet, look in the HARA Pilot Tunnel window)"
:summary

echo.
echo ============================================================
echo  Pilot is starting.
echo    Admin panel (pilot data):  http://localhost:%ADMIN_PORT%
echo    Public address:            !PUBLIC_URL!
echo  The address is also saved in tools\cloudflared\current-url.txt.
echo  It changes every time the tunnel restarts, and the phone app must be built with the current one.
echo  Keep this PC awake while testing.
echo ============================================================

:end
echo.
pause
exit /b 0

rem Kill whatever process is listening on %1
:KillPort
set "KP_PID="
for /f "tokens=5" %%P in ('netstat -ano ^| findstr /R /C:":%~1 .*LISTENING"') do (
    if not defined KP_PID set "KP_PID=%%P"
)
if defined KP_PID (
    taskkill /PID !KP_PID! /F >nul 2>&1
    ping -n 2 127.0.0.1 >nul
)
goto :eof
