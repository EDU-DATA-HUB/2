@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

if /i "%~1"=="__RUN__" goto :main
cmd /k call "%~f0" __RUN__
exit /b 0

:main
rem Expand offline-kit\*.zip into .runtime\ using tar (built into Windows 10/11).
echo.
echo [SETUP] Installing offline-kit into .runtime
echo.

if not exist "%~dp0offline-kit\manifest.txt" (
  echo [FAIL] offline-kit\ missing or incomplete.
  echo        Copy the full project including the offline-kit\ folder.
  set "ERR=1"
  goto :done
)

set "TAR=%SystemRoot%\System32\tar.exe"
if not exist "%TAR%" (
  echo [FAIL] tar.exe not found at %TAR%
  set "ERR=1"
  goto :done
)

if not exist "%~dp0.runtime" mkdir "%~dp0.runtime"
if not exist "%~dp0.runtime\.gitkeep" type nul > "%~dp0.runtime\.gitkeep"

for %%D in (jdk-8 jdk-11 jdk-17 maven m2 node docker-images app) do (
  if exist "%~dp0.runtime\%%D" (
    echo [CLEAN] %%D
    rmdir /s /q "%~dp0.runtime\%%D" 2>nul
  )
)

for %%Z in (
  jdk-8.zip
  jdk-11.zip
  jdk-17.zip
  maven.zip
  m2.zip
  node.zip
  docker-images.zip
  app.zip
) do (
  if not exist "%~dp0offline-kit\%%Z" (
    echo [FAIL] Missing offline-kit\%%Z
    set "ERR=1"
    goto :done
  )
  echo [RUN ] Expanding %%Z
  "%TAR%" -xf "%~dp0offline-kit\%%Z" -C "%~dp0.runtime"
  if errorlevel 1 (
    echo [FAIL] Failed to expand %%Z
    set "ERR=1"
    goto :done
  )
)

set "ERR=0"
call :require ".runtime\jdk-8\bin\java.exe"
call :require ".runtime\jdk-11\bin\java.exe"
call :require ".runtime\jdk-17\bin\java.exe"
call :require ".runtime\maven\bin\mvn.cmd"
call :require ".runtime\m2\org\springframework\boot\spring-boot\2.7.18\spring-boot-2.7.18.jar"
call :require ".runtime\node\node.exe"
call :require ".runtime\docker-images\01-docker-images.tar"
call :require ".runtime\app\docker-compose.yml"
call :require ".runtime\app\eureka-service\target\eureka-service-0.0.1-SNAPSHOT.jar"
call :require ".runtime\app\user-service\target\user-service-0.0.1-SNAPSHOT.jar"
call :require ".runtime\app\restaurant-service\target\restaurant-service-0.0.1-SNAPSHOT.jar"
call :require ".runtime\app\order-service\target\order-service-0.0.1-SNAPSHOT.jar"
call :require ".runtime\app\notification-service\target\notification-service-0.0.1-SNAPSHOT.jar"
call :require ".runtime\app\api-gateway\target\api-gateway-0.0.1-SNAPSHOT.jar"
call :require ".runtime\app\frontend\node_modules\@angular\cli\bin\ng.js"
if not "%ERR%"=="0" goto :done

echo.
echo [DONE] .runtime is ready.
echo        Next: build.cmd ^(optional^) then start.cmd
echo.
goto :done

:require
if not exist "%~dp0%~1" (
  echo [FAIL] Missing after setup: %~1
  set "ERR=1"
)
exit /b 0

:done
echo.
if "%ERR%"=="0" (echo [INFO] Finished successfully.) else (echo [INFO] Finished with errors. Read the messages above.)
echo.
pause
exit /b %ERR%
