@echo off
setlocal EnableExtensions
cd /d "%~dp0"

if /i "%~1"=="__RUN__" goto :main
cmd /k call "%~f0" __RUN__
exit /b 0

:main
call "%~dp0scripts\offline-env.cmd"
if errorlevel 1 goto :fail

set "FOOD_ROOT=%CD%"
set "TMPPS=%TEMP%\food-start-%RANDOM%%RANDOM%.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$p='%~f0'; $o=$env:TMPPS; $lines=Get-Content -LiteralPath $p; $i=0; while ($i -lt $lines.Count -and $lines[$i] -ne 'rem === POWERSHELL ===') { $i++ }; if ($i -ge $lines.Count) { throw 'POWERSHELL marker not found' }; Set-Content -LiteralPath $o -Value (($lines[($i+1)..($lines.Count-1)]) -join [Environment]::NewLine)"
if errorlevel 1 goto :fail
powershell -NoProfile -ExecutionPolicy Bypass -File "%TMPPS%"
set "ERR=%ERRORLEVEL%"
del /f /q "%TMPPS%" >nul 2>&1
goto :done

:fail
set "ERR=1"

:done
echo.
if "%ERR%"=="0" (echo [INFO] Finished successfully.) else (echo [INFO] Finished with errors. Read the messages above.)
echo.
pause
exit /b %ERR%

rem === POWERSHELL ===
$ErrorActionPreference = 'Stop'
$Root = if ($env:FOOD_ROOT) { $env:FOOD_ROOT } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
Set-Location $Root

$Runtime = Join-Path $Root '.runtime'
$AppHome = if ($env:APP_HOME) { $env:APP_HOME } else { Join-Path $Runtime 'app' }
$JavaHome = if ($env:JAVA_HOME) { $env:JAVA_HOME } else { Join-Path $Runtime 'jdk-8' }
$Java = Join-Path $JavaHome 'bin\java.exe'
$NodeBin = if ($env:NODE_BIN) { $env:NODE_BIN } else { Join-Path $Runtime 'node\node.exe' }
$ImagesTar = if ($env:DOCKER_IMAGES_TAR) { $env:DOCKER_IMAGES_TAR } else { Join-Path $Runtime 'docker-images\01-docker-images.tar' }
$ComposeFile = Join-Path $AppHome 'docker-compose.yml'
$LogDir = Join-Path $Root 'logs'
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }

$RequiredImages = @(
  'mysql:8.0',
  'redis:7-alpine',
  'confluentinc/cp-zookeeper:7.5.0',
  'confluentinc/cp-kafka:7.5.0'
)

$Services = @(
  @{ Name = 'eureka-service';       Port = 8761; Color = 'Magenta' }
  @{ Name = 'user-service';         Port = 8081; Color = 'Cyan' }
  @{ Name = 'restaurant-service';   Port = 8082; Color = 'Yellow' }
  @{ Name = 'order-service';        Port = 8083; Color = 'Green' }
  @{ Name = 'notification-service'; Port = 8084; Color = 'White' }
  @{ Name = 'api-gateway';          Port = 9000; Color = 'Blue' }
)

$ServiceColor = @{}
foreach ($s in $Services) { $ServiceColor[$s.Name] = $s.Color }

function Say([string]$Tag, [string]$Msg, [string]$Name = '') {
  $tagColor = switch -Regex ($Tag.Trim()) {
    'FAIL' { 'Red' }
    'UP|DONE' { 'Green' }
    'WAIT|HINT' { 'Yellow' }
    'RUN|LOAD' { 'Cyan' }
    'STOP' { 'Magenta' }
    default { 'Gray' }
  }
  Write-Host -NoNewline '[' -ForegroundColor $tagColor
  Write-Host -NoNewline $Tag -ForegroundColor $tagColor
  Write-Host -NoNewline '] ' -ForegroundColor $tagColor
  if ($Name -and $ServiceColor.ContainsKey($Name) -and $Msg.StartsWith($Name)) {
    Write-Host -NoNewline $Name -ForegroundColor $ServiceColor[$Name]
    Write-Host $Msg.Substring($Name.Length)
  } else {
    Write-Host $Msg
  }
}

function Get-PidsOnPort([int]$Port) {
  $pids = New-Object 'System.Collections.Generic.HashSet[int]'
  try {
    Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
      ForEach-Object { if ($_.OwningProcess) { [void]$pids.Add([int]$_.OwningProcess) } }
  } catch {}
  if ($pids.Count -eq 0) {
    $lines = netstat -ano -p tcp 2>$null | Select-String -Pattern ":$Port\s+.*LISTENING\s+(\d+)\s*$"
    foreach ($m in $lines) {
      if ($m.Matches.Count -gt 0) {
        $id = [int]$m.Matches[0].Groups[1].Value
        if ($id -gt 0) { [void]$pids.Add($id) }
      }
    }
  }
  return @($pids)
}

function Test-PortUp([int]$Port) {
  return ((Get-PidsOnPort $Port).Count -gt 0)
}

function Find-Jar([string]$Module) {
  $dir = Join-Path $AppHome "$Module\target"
  if (-not (Test-Path $dir)) { return $null }
  $jars = Get-ChildItem -Path $dir -Filter "$Module-*-SNAPSHOT.jar" -File |
    Where-Object { $_.Name -notmatch 'sources|javadoc|\.original' } |
    Sort-Object Length -Descending
  if ($jars) { return $jars[0].FullName }
  return $null
}

function Wait-Port([int]$Port, [string]$Name) {
  Say 'WAIT' "$Name on :$Port" $Name
  for ($i = 1; $i -le 90; $i++) {
    if (Test-PortUp $Port) {
      Say ' UP ' "$Name ready on $Port" $Name
      return $true
    }
    $log = Join-Path $LogDir "$Name.log"
    if (Test-Path $log) {
      $tail = Get-Content -LiteralPath $log -Tail 30 -ErrorAction SilentlyContinue | Out-String
      if ($tail -match 'Unable to access jarfile|APPLICATION FAILED TO START|Port .* was already in use') {
        Say 'FAIL' "$Name failed to start. See $log" $Name
        return $false
      }
    }
    Start-Sleep -Seconds 2
  }
  Say 'FAIL' "$Name timed out on :$Port. See $(Join-Path $LogDir "$Name.log")" $Name
  return $false
}

function Ensure-Docker {
  try {
    & docker.exe info 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'docker info failed' }
  } catch {
    Say 'FAIL' 'Docker is not running. Install with install-docker.cmd, start Docker Desktop, then retry.'
    exit 1
  }
}

function Ensure-InfraImages {
  $present = @{}
  foreach ($r in @(& docker.exe images --format '{{.Repository}}:{{.Tag}}' 2>$null)) {
    if ($r) { $present[$r.Trim()] = $true }
  }
  $missing = @()
  foreach ($img in $RequiredImages) {
    if (-not $present.ContainsKey($img)) { $missing += $img }
  }
  if ($missing.Count -eq 0) {
    Say 'LOAD' 'Infra images already present - skip docker load'
    return
  }
  if (-not (Test-Path -LiteralPath $ImagesTar)) {
    Say 'FAIL' "Missing image tar: $ImagesTar"
    exit 1
  }
  Say 'LOAD' "Loading infra images from tar ($($missing.Count) missing) - can take several minutes"
  & docker.exe load -i $ImagesTar
  if ($LASTEXITCODE -ne 0) {
    Say 'FAIL' 'docker load failed'
    exit 1
  }
}

function Start-Infra {
  Say 'RUN ' "docker compose -f $ComposeFile up -d"
  Push-Location $AppHome
  try {
    & docker.exe compose -f $ComposeFile up -d
    if ($LASTEXITCODE -ne 0) { throw 'compose up failed' }
  } finally {
    Pop-Location
  }
  Say 'WAIT' 'Waiting for MySQL...'
  for ($i = 1; $i -le 40; $i++) {
    # Use cmd so mysqladmin's stderr password warning is not treated as a terminating error
    cmd.exe /c "docker exec food-mysql mysqladmin ping -h localhost -uroot -p1999 --silent >nul 2>&1"
    if ($LASTEXITCODE -eq 0) {
      Say ' UP ' 'MySQL ready'
      break
    }
    if ($i -eq 40) {
      Say 'FAIL' 'MySQL did not become ready'
      exit 1
    }
    Start-Sleep -Seconds 2
  }
}

function Start-OneService($Svc) {
  $name = $Svc.Name
  $port = $Svc.Port
  if (Test-PortUp $port) {
    Say ' UP ' "$name already on :$port" $name
    return $true
  }
  $jar = Find-Jar $name
  if (-not $jar) {
    Say 'FAIL' "No jar for $name under .runtime\app\$name\target" $name
    return $false
  }
  $log = Join-Path $LogDir "$name.log"
  $pidFile = Join-Path $LogDir "$name.pid"
  $launcher = Join-Path $LogDir "$name-run.cmd"
  Say 'RUN ' "$name" $name
  if (Test-Path $log) { Remove-Item -Force $log -ErrorAction SilentlyContinue }
  $lines = @(
    '@echo off',
    "cd /d `"$AppHome`"",
    "`"$Java`" -jar `"$jar`" > `"$log`" 2>&1"
  )
  Set-Content -LiteralPath $launcher -Value $lines -Encoding ASCII
  $p = Start-Process -FilePath $launcher -WorkingDirectory $AppHome -WindowStyle Hidden -PassThru
  if (-not $p) {
    Say 'FAIL' "Could not start $name" $name
    return $false
  }
  Set-Content -Path $pidFile -Value $p.Id
  Start-Sleep -Seconds 2
  return (Wait-Port $port $name)
}

function Start-Frontend {
  if (Test-PortUp 4200) {
    Say ' UP ' 'frontend already on :4200'
    return $true
  }
  $frontend = Join-Path $AppHome 'frontend'
  $ng = Join-Path $frontend 'node_modules\@angular\cli\bin\ng.js'
  if (-not (Test-Path $ng)) {
    Say 'FAIL' 'Angular CLI missing under .runtime\app\frontend\node_modules'
    return $false
  }
  $log = Join-Path $LogDir 'frontend.log'
  $pidFile = Join-Path $LogDir 'frontend.pid'
  $launcher = Join-Path $LogDir 'frontend-run.cmd'
  Say 'RUN ' 'frontend'
  if (Test-Path $log) { Remove-Item -Force $log -ErrorAction SilentlyContinue }
  $lines = @(
    '@echo off',
    "cd /d `"$frontend`"",
    "`"$NodeBin`" `"$ng`" serve --host 0.0.0.0 --port 4200 > `"$log`" 2>&1"
  )
  Set-Content -LiteralPath $launcher -Value $lines -Encoding ASCII
  $p = Start-Process -FilePath $launcher -WorkingDirectory $frontend -WindowStyle Hidden -PassThru
  Set-Content -Path $pidFile -Value $p.Id
  return (Wait-Port 4200 'frontend')
}

if (-not (Test-Path $Java)) {
  Say 'FAIL' "Bundled JDK not found at $JavaHome - run setup.cmd"
  exit 1
}

Write-Host ''
Write-Host ' Food Order  ' -NoNewline
Write-Host "starting from $AppHome" -ForegroundColor Cyan
Write-Host ''

Ensure-Docker
Ensure-InfraImages
Start-Infra

if (-not (Start-OneService $Services[0])) { exit 1 }
foreach ($svc in $Services[1..4]) {
  if (-not (Start-OneService $svc)) { exit 1 }
}
if (-not (Start-OneService $Services[5])) { exit 1 }
if (-not (Start-Frontend)) { exit 1 }

Write-Host ''
Write-Host ' Food Order  ' -NoNewline
Write-Host 'READY' -ForegroundColor Green
Write-Host ''
Write-Host '  UI:      http://localhost:4200'
Write-Host '  Gateway: http://localhost:9000'
Write-Host '  Eureka:  http://localhost:8761'
Write-Host '  Login:   user / user123'
Write-Host '           admin / admin123'
Write-Host ''
Say 'LOGS' $LogDir
Say 'HINT' 'Stop with stop.cmd'
exit 0
