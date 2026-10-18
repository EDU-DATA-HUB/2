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
set "TMPPS=%TEMP%\food-stop-%RANDOM%%RANDOM%.ps1"
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

$LogDir = Join-Path $Root 'logs'
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }

$InfraNames = @('food-kafka', 'food-zookeeper', 'food-mysql', 'food-redis')

$ServiceColor = @{
  'eureka-service'       = 'Magenta'
  'user-service'         = 'Cyan'
  'restaurant-service'   = 'Yellow'
  'order-service'        = 'Green'
  'notification-service' = 'White'
  'api-gateway'          = 'Blue'
  'frontend'             = 'Cyan'
}

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

function Stop-ServiceByName([string]$Name, [int]$Port = 0) {
  $killed = New-Object 'System.Collections.Generic.HashSet[int]'
  $pidFile = Join-Path $LogDir "$Name.pid"
  if (Test-Path $pidFile) {
    $procId = (Get-Content $pidFile -ErrorAction SilentlyContinue | Select-Object -First 1).Trim()
    if ($procId) {
      $id = 0
      if ([int]::TryParse($procId, [ref]$id) -and $id -gt 0) {
        Say 'STOP' "$Name pid $id" $Name
        cmd.exe /c "taskkill /F /T /PID $id >nul 2>&1"
        [void]$killed.Add($id)
      }
    }
    Remove-Item -Force $pidFile -ErrorAction SilentlyContinue
  }
  if ($Port -gt 0) {
    foreach ($id in (Get-PidsOnPort $Port)) {
      if ($killed.Contains($id)) { continue }
      Say 'STOP' "$Name port $Port pid $id" $Name
      cmd.exe /c "taskkill /F /T /PID $id >nul 2>&1"
      [void]$killed.Add($id)
    }
  }
}

function Stop-OneContainer([string]$Name) {
  # Same pattern as Sakai stop: inspect, then docker stop. Do not remove the container.
  & docker.exe inspect $Name 2>$null | Out-Null
  if ($LASTEXITCODE -ne 0) {
    Say 'HINT' "$Name container does not exist"
    return $true
  }
  Say 'STOP' "docker stop $Name"
  & docker.exe stop $Name
  if ($LASTEXITCODE -ne 0) {
    Say 'FAIL' "docker stop $Name failed. Try: docker ps -a"
    return $false
  }
  Say 'DONE' "$Name stopped"
  return $true
}

function Stop-Infra {
  Say 'STOP' 'Docker infra'
  & docker.exe info 2>$null | Out-Null
  if ($LASTEXITCODE -ne 0) {
    Say 'HINT' 'Docker is not running. DB containers left as-is'
    return $true
  }
  foreach ($n in $InfraNames) {
    if (-not (Stop-OneContainer $n)) { return $false }
  }
  return $true
}

Write-Host ''
Write-Host ' Food Order  ' -NoNewline
Write-Host 'stopping' -ForegroundColor Magenta
Write-Host ''

Stop-ServiceByName 'frontend' 4200
foreach ($svc in @(
  @{ Name = 'api-gateway'; Port = 9000 },
  @{ Name = 'notification-service'; Port = 8084 },
  @{ Name = 'order-service'; Port = 8083 },
  @{ Name = 'restaurant-service'; Port = 8082 },
  @{ Name = 'user-service'; Port = 8081 },
  @{ Name = 'eureka-service'; Port = 8761 }
)) {
  Stop-ServiceByName $svc.Name $svc.Port
}

$infraOk = Stop-Infra
if (-not $infraOk) {
  Say 'FAIL' 'Apps stopped, but Docker infra was not fully stopped.'
  exit 1
}

Say 'DONE' 'Stopped apps + Docker infra.'
exit 0
