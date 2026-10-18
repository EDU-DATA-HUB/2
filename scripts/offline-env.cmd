@echo off
rem Internal helper — toolchain under .runtime\ (created by setup.cmd).
rem Optional: set FOOD_JAVA_VERSION=8|11|17 before calling (default 8).

set "ROOT=%~dp0.."
for %%I in ("%ROOT%") do set "ROOT=%%~fI"

if not defined FOOD_JAVA_VERSION set "FOOD_JAVA_VERSION=8"
if "%FOOD_JAVA_VERSION%"=="1.8" set "FOOD_JAVA_VERSION=8"

if not "%FOOD_JAVA_VERSION%"=="8" if not "%FOOD_JAVA_VERSION%"=="11" if not "%FOOD_JAVA_VERSION%"=="17" (
  echo [FAIL] FOOD_JAVA_VERSION must be 8, 11, or 17 ^(got %FOOD_JAVA_VERSION%^)
  exit /b 1
)

set "RUNTIME=%ROOT%\.runtime"
set "JAVA_HOME=%RUNTIME%\jdk-%FOOD_JAVA_VERSION%"
set "MAVEN_HOME=%RUNTIME%\maven"
set "M2_REPO=%RUNTIME%\m2"
set "MVN=%MAVEN_HOME%\bin\mvn.cmd"
set "OFFLINE_SETTINGS=%ROOT%\.mvn\settings-offline.xml"
set "NODE_HOME=%RUNTIME%\node"
set "APP_HOME=%RUNTIME%\app"
set "DOCKER_IMAGES_TAR=%RUNTIME%\docker-images\01-docker-images.tar"
set "NODE_BIN=%NODE_HOME%\node.exe"

if not exist "%RUNTIME%\jdk-8\bin\java.exe" (
  echo [FAIL] .runtime is not set up.
  echo        Run setup.cmd once after copying this project ^(uses offline-kit\^).
  exit /b 1
)
if not exist "%JAVA_HOME%\bin\java.exe" (
  echo [FAIL] Bundled JDK not found at .runtime\jdk-%FOOD_JAVA_VERSION%
  echo        Run setup.cmd again.
  exit /b 1
)
if not exist "%MVN%" (
  echo [FAIL] Bundled Maven not found at .runtime\maven
  echo        Run setup.cmd again ^(needs offline-kit\maven.zip^).
  exit /b 1
)
if not exist "%M2_REPO%\org\springframework\boot\spring-boot\2.7.18\spring-boot-2.7.18.jar" (
  echo [FAIL] .runtime\m2 looks empty or incomplete.
  echo        Run setup.cmd again ^(needs offline-kit\m2.zip^).
  exit /b 1
)
if not exist "%OFFLINE_SETTINGS%" (
  echo [FAIL] Offline Maven settings missing: .mvn\settings-offline.xml
  exit /b 1
)
if not exist "%NODE_BIN%" (
  echo [FAIL] Bundled Node.js not found at .runtime\node\node.exe
  echo        Run setup.cmd again.
  exit /b 1
)
if not exist "%APP_HOME%\docker-compose.yml" (
  echo [FAIL] .runtime\app is missing.
  echo        Run setup.cmd again.
  exit /b 1
)
if not exist "%DOCKER_IMAGES_TAR%" (
  echo [FAIL] .runtime\docker-images\01-docker-images.tar missing.
  echo        Run setup.cmd again.
  exit /b 1
)

"%JAVA_HOME%\bin\java.exe" -version >nul 2>&1
if errorlevel 1 (
  echo [FAIL] java.exe failed to run from .runtime\jdk-%FOOD_JAVA_VERSION%
  exit /b 1
)

set "PATH=%JAVA_HOME%\bin;%MAVEN_HOME%\bin;%NODE_HOME%;%PATH%"
echo [INFO] Using JAVA_HOME=%JAVA_HOME%
echo [INFO] Using MAVEN_HOME=%MAVEN_HOME%
echo [INFO] Using M2_REPO=%M2_REPO%
echo [INFO] Using NODE_HOME=%NODE_HOME%
echo [INFO] Using APP_HOME=%APP_HOME%
exit /b 0
