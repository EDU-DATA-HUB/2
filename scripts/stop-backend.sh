#!/usr/bin/env bash
# Stop backend services. Works when started from WSL/Git Bash against Windows java.exe
# by also freeing known ports (pid files alone are not enough for Windows JVMs).
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PID_DIR="$ROOT_DIR/scripts/pids"

PORTS=(8761 8081 8082 8083 8084 9000)

echo "==> Stopping backend (pid files + ports ${PORTS[*]})..."

# 1) Best-effort kill from pid files (WSL pids / nohup wrappers)
if [[ -d "$PID_DIR" ]]; then
  for pidfile in "$PID_DIR"/*.pid; do
    [[ -e "$pidfile" ]] || continue
    name="$(basename "$pidfile" .pid)"
    pid="$(cat "$pidfile" 2>/dev/null || true)"
    if [[ -n "${pid:-}" ]] && kill -0 "$pid" 2>/dev/null; then
      echo "  stop $name (shell pid $pid)"
      kill "$pid" 2>/dev/null || true
      sleep 0.5
      kill -9 "$pid" 2>/dev/null || true
    fi
    rm -f "$pidfile"
  done
fi

# 2) Free ports held by Windows java.exe (typical when using WSL → java.exe)
free_ports_windows() {
  local port_list
  port_list="$(IFS=','; echo "${PORTS[*]}")"
  powershell.exe -NoProfile -Command "
\$ports = @(${port_list})
foreach (\$p in \$ports) {
  Get-NetTCPConnection -LocalPort \$p -State Listen -ErrorAction SilentlyContinue |
    ForEach-Object {
      \$procId = \$_.OwningProcess
      \$proc = Get-Process -Id \$procId -ErrorAction SilentlyContinue
      if (\$null -eq \$proc) { return }
      # Only stop Java backends — never kill unrelated listeners
      if (\$proc.ProcessName -notin @('java','javaw')) {
        Write-Output \"  skip port \$p PID \$procId (\$(\$proc.ProcessName)) — not java\"
        return
      }
      Write-Output \"  kill port \$p PID \$procId (\$(\$proc.ProcessName))\"
      Stop-Process -Id \$procId -Force -ErrorAction SilentlyContinue
    }
}
" 2>/dev/null || true
}

free_ports_windows

# 3) Linux/WSL listeners (if any native java holds the port)
for p in "${PORTS[@]}"; do
  if command -v fuser >/dev/null 2>&1; then
    fuser -k "${p}/tcp" 2>/dev/null || true
  fi
done

sleep 1
echo "Backend stop requested. Ports should be free for a new start."
echo "  Re-check: bash ./scripts/start-backend.sh"
