@echo off
setlocal EnableExtensions
cd /d "%~dp0"

if /i "%~1"=="__RUN__" goto :main
cmd /k call "%~f0" __RUN__
exit /b 0

:main
set "PREREQS=%~dp0offline-kit\prereqs"
set "WSL_MSI=%PREREQS%\wsl.x64.msi"
set "DOCKER_ZIP=%PREREQS%\DockerDesktopInstaller.zip"
set "STAGE=%TEMP%\food-docker-prereq-install"

if not exist "%WSL_MSI%" (
  echo [FAIL] Missing %WSL_MSI%
  set "ERR=1"
  goto :done
)
if not exist "%DOCKER_ZIP%" (
  echo [FAIL] Missing %DOCKER_ZIP%
  set "ERR=1"
  goto :done
)

echo ============================================
echo  Install WSL + Docker Desktop ^(manual UI^)
echo ============================================
echo.
echo  1^) WSL MSI
echo  2^) Docker Desktop installer
echo  Finish each wizard, reboot if asked, then start Docker Desktop.
echo.
pause

echo [RUN ] Starting WSL installer...
start "" msiexec /i "%WSL_MSI%"
echo        Complete the WSL install window, then press a key here.
pause

if exist "%STAGE%" rmdir /s /q "%STAGE%" 2>nul
mkdir "%STAGE%"
echo [RUN ] Unzipping DockerDesktopInstaller.zip ...
tar -xf "%DOCKER_ZIP%" -C "%STAGE%"
if errorlevel 1 (
  echo [FAIL] Could not unzip DockerDesktopInstaller.zip
  set "ERR=1"
  goto :done
)
if not exist "%STAGE%\DockerDesktopInstaller.exe" (
  echo [FAIL] DockerDesktopInstaller.exe not found inside the zip
  set "ERR=1"
  goto :done
)

echo [RUN ] Starting Docker Desktop installer...
start "" "%STAGE%\DockerDesktopInstaller.exe"
echo.
echo [INFO] Complete the Docker installer, reboot if asked,
echo        start Docker Desktop, then run setup.cmd / start.cmd
echo.
set "ERR=0"

:done
echo.
if "%ERR%"=="0" (echo [INFO] Finished successfully.) else (echo [INFO] Finished with errors. Read the messages above.)
echo.
pause
exit /b %ERR%
