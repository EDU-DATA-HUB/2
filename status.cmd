@echo off
setlocal EnableExtensions
cd /d "%~dp0"

if /i "%~1"=="__RUN__" goto :main
cmd /k call "%~f0" __RUN__
exit /b 0

:main
echo ============================================
echo  Food Order - STATUS
echo ============================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$names=@{8761='eureka';8081='user';8082='restaurant';8083='order';8084='notification';9000='gateway';4200='frontend'}; foreach($p in 8761,8081,8082,8083,8084,9000,4200){ $c=Get-NetTCPConnection -LocalPort $p -State Listen -EA SilentlyContinue | Select-Object -First 1; if($c){ Write-Host ('  UP   :{0}  {1}' -f $p,$names[$p]) -ForegroundColor Green } else { Write-Host ('  DOWN :{0}  {1}' -f $p,$names[$p]) -ForegroundColor Red } }"

echo.
echo  UI:      http://localhost:4200
echo  Gateway: http://localhost:9000
echo  Login:   user / user123  ^|  admin / admin123
echo.
pause
exit /b 0
