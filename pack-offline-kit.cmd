@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

if /i "%~1"=="__RUN__" goto :main
cmd /k call "%~f0" __RUN__
exit /b 0

:main
rem Rebuild offline-kit\*.zip using tar + robocopy (no .ps1 files).
echo.
echo [PACK] Building offline-kit
echo.

set "TAR=%SystemRoot%\System32\tar.exe"
if not exist "%TAR%" (
  echo [FAIL] tar.exe not found at %TAR%
  set "ERR=1"
  goto :done
)
where robocopy >nul 2>&1
if errorlevel 1 (
  echo [FAIL] robocopy not found.
  set "ERR=1"
  goto :done
)

set "ROOT=%CD%"
set "KIT=%ROOT%\offline-kit"
set "STAGING=%ROOT%\.pack-staging"
set "SIBLING=%ROOT%\..\1\offline-kit"

if not exist "%KIT%" mkdir "%KIT%"
if exist "%STAGING%" rmdir /s /q "%STAGING%"
mkdir "%STAGING%"

rem --- JDKs ---
for %%J in (jdk-8 jdk-11 jdk-17) do (
  if exist "%SIBLING%\%%J.zip" (
    echo [COPY] %%J.zip from sibling offline-kit
    copy /y "%SIBLING%\%%J.zip" "%KIT%\%%J.zip" >nul
  ) else if exist "%ROOT%\.runtime\%%J\bin\java.exe" (
    echo [ZIP ] %%J.zip from .runtime\%%J
    if exist "%STAGING%\jdkpack-%%J" rmdir /s /q "%STAGING%\jdkpack-%%J"
    mkdir "%STAGING%\jdkpack-%%J"
    robocopy "%ROOT%\.runtime\%%J" "%STAGING%\jdkpack-%%J\%%J" /E /NFL /NDL /NJH /NJS /nc /ns /np >nul
    if exist "%KIT%\%%J.zip" del /f /q "%KIT%\%%J.zip"
    pushd "%STAGING%\jdkpack-%%J"
    "%TAR%" -a -cf "%KIT%\%%J.zip" "%%J"
    popd
  ) else if exist "%KIT%\%%J.zip" (
    echo [KEEP] %%J.zip already in offline-kit
  ) else (
    echo [FAIL] Missing %%J - place %%J.zip in offline-kit or run setup first
    set "ERR=1"
    goto :done
  )
)

rem --- Maven ---
if exist "%SIBLING%\maven.zip" (
  echo [COPY] maven.zip from sibling offline-kit
  copy /y "%SIBLING%\maven.zip" "%KIT%\maven.zip" >nul
) else if exist "%ROOT%\.runtime\maven\bin\mvn.cmd" (
  echo [ZIP ] maven.zip from .runtime\maven
  if exist "%STAGING%\mavenpack" rmdir /s /q "%STAGING%\mavenpack"
  mkdir "%STAGING%\mavenpack"
  robocopy "%ROOT%\.runtime\maven" "%STAGING%\mavenpack\maven" /E /NFL /NDL /NJH /NJS /nc /ns /np >nul
  if exist "%KIT%\maven.zip" del /f /q "%KIT%\maven.zip"
  pushd "%STAGING%\mavenpack"
  "%TAR%" -a -cf "%KIT%\maven.zip" maven
  popd
) else if exist "%KIT%\maven.zip" (
  echo [KEEP] maven.zip already in offline-kit
) else (
  echo [FAIL] Missing maven.zip - place in offline-kit or sibling Eazy Bank kit
  set "ERR=1"
  goto :done
)

rem --- m2 ^(local Maven repo for offline builds^) ---
rem Seed from sibling / existing kit, then fill Food Order deps online into a staging repo and re-zip.
if exist "%STAGING%\m2seed" rmdir /s /q "%STAGING%\m2seed"
mkdir "%STAGING%\m2seed"
if exist "%SIBLING%\m2.zip" (
  echo [SEED] m2 from sibling offline-kit
  "%TAR%" -xf "%SIBLING%\m2.zip" -C "%STAGING%\m2seed"
) else if exist "%KIT%\m2.zip" (
  echo [SEED] m2 from existing offline-kit\m2.zip
  "%TAR%" -xf "%KIT%\m2.zip" -C "%STAGING%\m2seed"
) else if exist "%ROOT%\.runtime\m2\org\springframework\boot\spring-boot\2.7.18\spring-boot-2.7.18.jar" (
  echo [SEED] m2 from .runtime\m2
  robocopy "%ROOT%\.runtime\m2" "%STAGING%\m2seed\m2" /E /NFL /NDL /NJH /NJS /nc /ns /np >nul
) else (
  echo [FAIL] No m2 seed found. Need sibling m2.zip, offline-kit\m2.zip, or .runtime\m2
  set "ERR=1"
  goto :done
)
if not exist "%STAGING%\m2seed\m2" (
  echo [FAIL] m2 seed did not expand to m2\
  set "ERR=1"
  goto :done
)

set "PACK_JAVA="
if exist "%ROOT%\.runtime\jdk-8\bin\java.exe" set "PACK_JAVA=%ROOT%\.runtime\jdk-8"
if not defined PACK_JAVA if exist "%ROOT%\..\1\.runtime\jdk-8\bin\java.exe" set "PACK_JAVA=%ROOT%\..\1\.runtime\jdk-8"
if not defined PACK_JAVA (
  echo [FAIL] JDK 8 needed to refresh m2 dependencies
  set "ERR=1"
  goto :done
)
set "PACK_MVN="
if exist "%ROOT%\.runtime\maven\bin\mvn.cmd" set "PACK_MVN=%ROOT%\.runtime\maven\bin\mvn.cmd"
if not defined PACK_MVN if exist "%ROOT%\..\1\.runtime\maven\bin\mvn.cmd" set "PACK_MVN=%ROOT%\..\1\.runtime\maven\bin\mvn.cmd"
if not defined PACK_MVN (
  rem Expand just-copied maven.zip into staging for this pack run
  if exist "%STAGING%\mvnrun" rmdir /s /q "%STAGING%\mvnrun"
  mkdir "%STAGING%\mvnrun"
  "%TAR%" -xf "%KIT%\maven.zip" -C "%STAGING%\mvnrun"
  set "PACK_MVN=%STAGING%\mvnrun\maven\bin\mvn.cmd"
)
if not exist "!PACK_MVN!" (
  echo [FAIL] mvn.cmd not found for m2 refresh
  set "ERR=1"
  goto :done
)

echo [M2  ] Resolving Food Order dependencies into local repo ^(online, one-time for pack^)
set "JAVA_HOME=!PACK_JAVA!"
set "PATH=!PACK_JAVA!\bin;%PATH%"
for %%S in (eureka-service user-service restaurant-service order-service notification-service api-gateway) do (
  echo [M2  ] %%S
  pushd "%ROOT%\%%S"
  call "!PACK_MVN!" -s "%ROOT%\.mvn\settings.xml" -Dmaven.repo.local="%STAGING%\m2seed\m2" -DskipTests dependency:go-offline package
  if errorlevel 1 (
    popd
    echo [FAIL] Could not resolve dependencies for %%S
    set "ERR=1"
    goto :done
  )
  popd
)
if exist "%KIT%\m2.zip" del /f /q "%KIT%\m2.zip"
pushd "%STAGING%\m2seed"
"%TAR%" -a -cf "%KIT%\m2.zip" m2
popd
for %%A in ("%KIT%\m2.zip") do echo [ZIP ] m2.zip  %%~zA bytes

rem --- Node ---
set "NODE_HOME="
if defined FOOD_NODE_HOME if exist "%FOOD_NODE_HOME%\node.exe" set "NODE_HOME=%FOOD_NODE_HOME%"
if not defined NODE_HOME if exist "%LOCALAPPDATA%\nvm\v24.14.1\node.exe" set "NODE_HOME=%LOCALAPPDATA%\nvm\v24.14.1"
if not defined NODE_HOME if exist "C:\nvm4w\nodejs\node.exe" set "NODE_HOME=C:\nvm4w\nodejs"
if not defined NODE_HOME if exist "%ProgramFiles%\nodejs\node.exe" set "NODE_HOME=%ProgramFiles%\nodejs"
if not defined NODE_HOME (
  echo [FAIL] Node.js not found. Set FOOD_NODE_HOME to a folder with node.exe
  set "ERR=1"
  goto :done
)
echo [NODE] !NODE_HOME!
if exist "%STAGING%\nodepack" rmdir /s /q "%STAGING%\nodepack"
mkdir "%STAGING%\nodepack\node"
robocopy "!NODE_HOME!" "%STAGING%\nodepack\node" /E /XD node_modules .cache /NFL /NDL /NJH /NJS /nc /ns /np >nul
if not exist "%STAGING%\nodepack\node\node.exe" (
  echo [FAIL] node.exe missing after copy
  set "ERR=1"
  goto :done
)
if exist "%KIT%\node.zip" del /f /q "%KIT%\node.zip"
pushd "%STAGING%\nodepack"
"%TAR%" -a -cf "%KIT%\node.zip" node
popd
for %%A in ("%KIT%\node.zip") do echo [ZIP ] node.zip  %%~zA bytes

rem --- Prereqs: WSL MSI + Docker Desktop installer zip ---
if not exist "%KIT%\prereqs" mkdir "%KIT%\prereqs"

set "SAKAI_PREREQS=E:\Offline\4-main\sakai\sakai\offline-kit\prereqs"

set "WSL_MSI="
if defined FOOD_WSL_MSI if exist "%FOOD_WSL_MSI%" set "WSL_MSI=%FOOD_WSL_MSI%"
if not defined WSL_MSI if exist "%SAKAI_PREREQS%\wsl.x64.msi" set "WSL_MSI=%SAKAI_PREREQS%\wsl.x64.msi"
if not defined WSL_MSI if exist "%KIT%\prereqs\wsl.x64.msi" set "WSL_MSI=%KIT%\prereqs\wsl.x64.msi"
if not defined WSL_MSI if exist "%USERPROFILE%\Downloads\wsl.x64.msi" set "WSL_MSI=%USERPROFILE%\Downloads\wsl.x64.msi"
if not defined WSL_MSI if exist "%USERPROFILE%\Downloads\wsl_update_x64.msi" set "WSL_MSI=%USERPROFILE%\Downloads\wsl_update_x64.msi"
if not defined WSL_MSI (
  echo [FAIL] wsl.x64.msi not found. Set FOOD_WSL_MSI or place it in offline-kit\prereqs\
  set "ERR=1"
  goto :done
)
echo [WSL ] !WSL_MSI!
copy /y "!WSL_MSI!" "%KIT%\prereqs\wsl.x64.msi" >nul

rem Prefer an existing DockerDesktopInstaller.zip; else zip a .exe
if defined FOOD_DOCKER_ZIP if exist "%FOOD_DOCKER_ZIP%" (
  echo [DOCK] !FOOD_DOCKER_ZIP!
  copy /y "!FOOD_DOCKER_ZIP!" "%KIT%\prereqs\DockerDesktopInstaller.zip" >nul
  goto :dock_done
)
if exist "%SAKAI_PREREQS%\DockerDesktopInstaller.zip" (
  echo [DOCK] %SAKAI_PREREQS%\DockerDesktopInstaller.zip
  copy /y "%SAKAI_PREREQS%\DockerDesktopInstaller.zip" "%KIT%\prereqs\DockerDesktopInstaller.zip" >nul
  goto :dock_done
)
if exist "%KIT%\prereqs\DockerDesktopInstaller.zip" (
  echo [KEEP] prereqs\DockerDesktopInstaller.zip
  goto :dock_done
)

set "INSTALLER="
if defined FOOD_DOCKER_INSTALLER if exist "%FOOD_DOCKER_INSTALLER%" set "INSTALLER=%FOOD_DOCKER_INSTALLER%"
if not defined INSTALLER if exist "%USERPROFILE%\Downloads\Docker Desktop Installer.exe" set "INSTALLER=%USERPROFILE%\Downloads\Docker Desktop Installer.exe"
if not defined INSTALLER (
  echo [FAIL] Docker Desktop installer not found. Set FOOD_DOCKER_INSTALLER or FOOD_DOCKER_ZIP
  set "ERR=1"
  goto :done
)
echo [DOCK] !INSTALLER!
if exist "%STAGING%\dockpack" rmdir /s /q "%STAGING%\dockpack"
mkdir "%STAGING%\dockpack"
copy /y "!INSTALLER!" "%STAGING%\dockpack\DockerDesktopInstaller.exe" >nul
if exist "%KIT%\prereqs\DockerDesktopInstaller.zip" del /f /q "%KIT%\prereqs\DockerDesktopInstaller.zip"
pushd "%STAGING%\dockpack"
"%TAR%" -a -cf "%KIT%\prereqs\DockerDesktopInstaller.zip" DockerDesktopInstaller.exe
popd

:dock_done
echo [ZIP ] prereqs\DockerDesktopInstaller.zip
if exist "%KIT%\docker-desktop.zip" del /f /q "%KIT%\docker-desktop.zip"

rem --- Docker infra images (saved only into staging / offline-kit, never project root) ---
where docker >nul 2>&1
if errorlevel 1 (
  echo [FAIL] Docker not found. Start Docker Desktop to pack infra images.
  set "ERR=1"
  goto :done
)
docker info >nul 2>&1
if errorlevel 1 (
  echo [FAIL] Docker is not running. Start Docker Desktop, then retry.
  set "ERR=1"
  goto :done
)
echo [IMG ] docker save mysql/redis/kafka/zookeeper -^> staging ^(then zip^)
if exist "%STAGING%\imgpack" rmdir /s /q "%STAGING%\imgpack"
mkdir "%STAGING%\imgpack\docker-images"
for %%I in (mysql:8.0 redis:7-alpine confluentinc/cp-zookeeper:7.5.0 confluentinc/cp-kafka:7.5.0) do (
  docker image inspect %%I >nul 2>&1
  if errorlevel 1 (
    echo [PULL] %%I
    docker pull %%I
    if errorlevel 1 (
      echo [FAIL] Could not pull %%I
      set "ERR=1"
      goto :done
    )
  ) else (
    echo [OK  ] %%I
  )
)
docker save mysql:8.0 redis:7-alpine confluentinc/cp-zookeeper:7.5.0 confluentinc/cp-kafka:7.5.0 -o "%STAGING%\imgpack\docker-images\01-docker-images.tar"
if errorlevel 1 (
  echo [FAIL] docker save failed
  set "ERR=1"
  goto :done
)
if exist "%KIT%\docker-images.zip" del /f /q "%KIT%\docker-images.zip"
pushd "%STAGING%\imgpack"
"%TAR%" -a -cf "%KIT%\docker-images.zip" docker-images
popd
echo [ZIP ] docker-images.zip

rem --- App ---
echo [APP ] assembling app payload
if exist "%STAGING%\apppack" rmdir /s /q "%STAGING%\apppack"
mkdir "%STAGING%\apppack\app"
copy /y "%ROOT%\docker-compose.yml" "%STAGING%\apppack\app\docker-compose.yml" >nul

for %%S in (eureka-service user-service restaurant-service order-service notification-service api-gateway) do (
  set "JAR="
  for %%F in ("%ROOT%\%%S\target\%%S-*-SNAPSHOT.jar") do (
    echo %%~nxF | findstr /I /C:".original" >nul
    if errorlevel 1 set "JAR=%%~fF"
  )
  if not defined JAR (
    echo [FAIL] Missing JAR for %%S
    set "ERR=1"
    goto :done
  )
  mkdir "%STAGING%\apppack\app\%%S\target" 2>nul
  copy /y "!JAR!" "%STAGING%\apppack\app\%%S\target\" >nul
)

if not exist "%ROOT%\frontend\node_modules" (
  echo [FAIL] frontend\node_modules missing - run npm install online first
  set "ERR=1"
  goto :done
)
echo [APP ] copying frontend ^(can take a few minutes^)
rem Do NOT use /XD dist here - that drops every package's dist\ folder under node_modules.
robocopy "%ROOT%\frontend" "%STAGING%\apppack\app\frontend" /E /XD .angular .cache /NFL /NDL /NJH /NJS /nc /ns /np >nul
if exist "%STAGING%\apppack\app\frontend\dist" rmdir /s /q "%STAGING%\apppack\app\frontend\dist" 2>nul
if not exist "%STAGING%\apppack\app\frontend\node_modules\@angular\cli\bin\ng.js" (
  echo [FAIL] frontend copy incomplete
  set "ERR=1"
  goto :done
)
if not exist "%STAGING%\apppack\app\frontend\node_modules\ajv\dist\ajv.js" (
  echo [FAIL] frontend\node_modules looks incomplete ^(ajv\dist missing^)
  set "ERR=1"
  goto :done
)

mkdir "%STAGING%\apppack\app\scripts" 2>nul
if exist "%ROOT%\scripts\mysql-init.sql" copy /y "%ROOT%\scripts\mysql-init.sql" "%STAGING%\apppack\app\scripts\" >nul

if exist "%KIT%\app.zip" del /f /q "%KIT%\app.zip"
pushd "%STAGING%\apppack"
"%TAR%" -a -cf "%KIT%\app.zip" app
popd
echo [ZIP ] app.zip

rem --- manifest ---
(
  echo Food Order offline-kit
  echo Created: %DATE% %TIME%
  echo.
  echo prereqs\
  dir /b "%KIT%\prereqs"
  echo.
  for %%F in ("%KIT%\*.zip") do echo %%~nxF	%%~zF bytes
) > "%KIT%\manifest.txt"

if exist "%STAGING%" rmdir /s /q "%STAGING%"

echo.
echo [DONE] offline-kit ready:
type "%KIT%\manifest.txt"
echo.
echo Next: setup.cmd
echo       install-docker.cmd
echo       start.cmd
set "ERR=0"

:done
echo.
if "%ERR%"=="0" (echo [INFO] Finished successfully.) else (echo [INFO] Finished with errors. Read the messages above.)
echo.
pause
exit /b %ERR%
