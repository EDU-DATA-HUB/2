@echo off
setlocal EnableExtensions
cd /d "%~dp0"

if /i "%~1"=="__RUN__" goto :main
cmd /k call "%~f0" __RUN__
exit /b 0

:main
echo ============================================
echo  Food Order - CLEAN generated files
echo ============================================
echo.
echo  Will remove:
echo    .runtime\*   ^(keeps .gitkeep^)
echo    frontend\node_modules, dist, .angular
echo    */target
echo    logs, scripts\logs, scripts\pids
echo    .pack-staging
echo.
echo  Will KEEP:
echo    offline-kit\  ^(all .zip archives^)
echo    source code
echo.
echo  Tip: run stop.cmd first if the stack is up.
echo.
pause

echo.
echo [CLEAN] Removing generated files ^(offline-kit kept^)
echo.

rem Best-effort stop of listeners on app ports
for %%P in (4200 9000 8761 8081 8082 8083 8084) do (
  for /f "tokens=5" %%A in ('netstat -ano ^| findstr /R /C:":%%P .*LISTENING"') do (
    echo [STOP] PID %%A on :%%P
    taskkill /F /PID %%A >nul 2>&1
  )
)

if exist "%~dp0.runtime" (
  echo [DEL ] .runtime\* ^(keep .gitkeep^)
  for /d %%D in ("%~dp0.runtime\*") do (
    if /i not "%%~nxD"==".gitkeep" rmdir /s /q "%%~fD" 2>nul
  )
  for %%F in ("%~dp0.runtime\*") do (
    if /i not "%%~nxF"==".gitkeep" del /f /q "%%~fF" 2>nul
  )
) else (
  echo [SKIP] .runtime
)
if not exist "%~dp0.runtime" mkdir "%~dp0.runtime"
if not exist "%~dp0.runtime\.gitkeep" type nul > "%~dp0.runtime\.gitkeep"

call :rm "frontend\node_modules"
call :rm "frontend\dist"
call :rm "frontend\.angular"
call :rm "eureka-service\target"
call :rm "user-service\target"
call :rm "restaurant-service\target"
call :rm "order-service\target"
call :rm "notification-service\target"
call :rm "api-gateway\target"
call :rm "logs"
call :rm "scripts\logs"
call :rm "scripts\pids"
call :rm ".pack-staging"
if exist "%~dp0scripts\.run-frontend.cmd" (
  echo [DEL ] scripts\.run-frontend.cmd
  del /f /q "%~dp0scripts\.run-frontend.cmd" 2>nul
)

for /d /r "%~dp0" %%D in (uploads) do (
  echo "%%~fD" | findstr /I /C:"\src\main\resources\uploads" >nul
  if not errorlevel 1 (
    echo [DEL ] %%~fD
    rmdir /s /q "%%~fD" 2>nul
  )
)

echo.
echo [DONE] Clean complete.
echo        Kept: offline-kit\, source, .runtime\.gitkeep
echo        Next: setup.cmd
echo.
set "ERR=0"
goto :done

:rm
if exist "%~dp0%~1" (
  echo [DEL ] %~1
  rmdir /s /q "%~dp0%~1" 2>nul
  if exist "%~dp0%~1" del /f /q "%~dp0%~1" 2>nul
) else (
  echo [SKIP] %~1
)
exit /b 0

:done
echo.
if "%ERR%"=="0" (echo [INFO] Finished successfully.) else (echo [INFO] Finished with errors. Read the messages above.)
echo.
pause
exit /b %ERR%
