@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

if /i "%~1"=="__RUN__" goto :main
cmd /k call "%~f0" __RUN__
exit /b 0

:main
call "%~dp0scripts\offline-env.cmd"
if errorlevel 1 goto :fail

set "ROOT=%CD%"

echo.
echo [RUN ] mvn -o clean package -DskipTests
echo        ^(offline: no network downloads^)
echo        JAVA_HOME=%JAVA_HOME%
echo        MVN=%MVN%
echo        M2_REPO=%M2_REPO%
echo.

for %%S in (eureka-service user-service restaurant-service order-service notification-service api-gateway) do (
  echo [BUILD] %%S
  pushd "%ROOT%\%%S"
  call "%MVN%" -o -s "%OFFLINE_SETTINGS%" -Dmaven.repo.local="%M2_REPO%" clean package -DskipTests
  if errorlevel 1 (
    popd
    echo [FAIL] Offline build failed for %%S
    echo        Ensure setup.cmd completed and offline-kit\m2.zip has this project's dependencies.
    echo        On an online PC: pack-offline-kit.cmd ^(refreshes m2^), then copy offline-kit\ to this machine.
    goto :fail
  )
  popd
  del /q "%ROOT%\%%S\target\*.jar.original" >nul 2>&1

  set "JAR="
  for %%F in ("%ROOT%\%%S\target\%%S-*-SNAPSHOT.jar") do (
    echo %%~nxF | findstr /I /C:".original" >nul
    if errorlevel 1 set "JAR=%%~fF"
  )
  if not defined JAR (
    echo [FAIL] No jar produced for %%S
    goto :fail
  )
  if not exist "%APP_HOME%\%%S\target" mkdir "%APP_HOME%\%%S\target"
  del /q "%APP_HOME%\%%S\target\%%S-*-SNAPSHOT.jar" >nul 2>&1
  copy /y "!JAR!" "%APP_HOME%\%%S\target\" >nul
  echo [COPY] %%S -^> .runtime\app\%%S\target
)

if exist "%ROOT%\frontend\src" if exist "%APP_HOME%\frontend" (
  echo [COPY] frontend sources -^> .runtime\app\frontend
  robocopy "%ROOT%\frontend\src" "%APP_HOME%\frontend\src" /E /NFL /NDL /NJH /NJS /nc /ns /np >nul
  for %%F in (angular.json package.json tsconfig.json tsconfig.app.json tsconfig.spec.json tailwind.config.js) do (
    if exist "%ROOT%\frontend\%%F" copy /y "%ROOT%\frontend\%%F" "%APP_HOME%\frontend\%%F" >nul
  )
)

echo.
echo [DONE] Offline build succeeded. Jars are in .runtime\app
echo        Next: stop.cmd   then   start.cmd
set "ERR=0"
goto :done

:fail
set "ERR=1"

:done
echo.
if "%ERR%"=="0" (echo [INFO] Finished successfully.) else (echo [INFO] Finished with errors. Read the messages above.)
echo.
pause
exit /b %ERR%
