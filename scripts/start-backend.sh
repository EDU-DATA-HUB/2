#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "$SCRIPT_DIR/env.sh"

LOG_DIR="$ROOT_DIR/scripts/logs"
PID_DIR="$ROOT_DIR/scripts/pids"
mkdir -p "$LOG_DIR" "$PID_DIR"

JAVA_BIN="${JAVA_BIN:-$JAVA_HOME/bin/java}"
if [[ ! -x "$JAVA_BIN" && -f "$JAVA_HOME/bin/java.exe" ]]; then
  JAVA_BIN="$JAVA_HOME/bin/java.exe"
fi

path_for_java() {
  local p="$1"
  case "$JAVA_BIN" in
    *.exe|*/java.exe)
      if command -v wslpath >/dev/null 2>&1; then
        wslpath -w "$p"
      elif command -v cygpath >/dev/null 2>&1; then
        cygpath -w "$p"
      else
        if [[ "$p" =~ ^/mnt/([a-zA-Z])/(.*)$ ]]; then
          echo "${BASH_REMATCH[1]^}:\\${BASH_REMATCH[2]//\//\\}"
        elif [[ "$p" =~ ^/([a-zA-Z])/(.*)$ ]]; then
          echo "${BASH_REMATCH[1]^}:\\${BASH_REMATCH[2]//\//\\}"
        else
          echo "$p"
        fi
      fi
      ;;
    *)
      echo "$p"
      ;;
  esac
}

# True if a TCP port is listening (works for Windows java from WSL)
port_is_up() {
  local port="$1"
  if command -v curl >/dev/null 2>&1; then
    # Any HTTP response (even 401/404) means the port accepts connections
    curl -s -m 1 -o /dev/null "http://127.0.0.1:${port}/" && return 0
    # curl failure can still mean connection refused vs other — try powershell
  fi
  if command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -NoProfile -Command \
      "if (Get-NetTCPConnection -LocalPort ${port} -State Listen -EA SilentlyContinue) { exit 0 } else { exit 1 }" \
      >/dev/null 2>&1 && return 0
  fi
  (echo >/dev/tcp/127.0.0.1/"$port") >/dev/null 2>&1
}

start_service() {
  local name="$1"
  local port="$2"
  local jar jar_arg

  if port_is_up "$port"; then
    echo "Already listening on :$port — skip starting $name"
    return 0
  fi

  jar="$(ls "$ROOT_DIR/$name/target/"*-SNAPSHOT.jar 2>/dev/null | grep -v original | head -1 || true)"
  if [[ -z "$jar" || ! -f "$jar" ]]; then
    echo "Missing JAR for $name under $ROOT_DIR/$name/target/"
    exit 1
  fi
  jar_arg="$(path_for_java "$jar")"

  echo "==> Starting $name on port $port..."
  echo "    jar: $jar_arg"
  nohup "$JAVA_BIN" -jar "$jar_arg" >"$LOG_DIR/$name.log" 2>&1 &
  echo $! >"$PID_DIR/$name.pid"
  echo "    shell-pid $(cat "$PID_DIR/$name.pid")  log: scripts/logs/$name.log"
}

wait_port() {
  local port="$1"
  local name="$2"
  local i
  for i in $(seq 1 90); do
    if port_is_up "$port"; then
      echo "Ready: $name (:$port)"
      return 0
    fi
    # Only fail fast on clear jar errors (do NOT trust WSL shell pid — java.exe detaches)
    if [[ -f "$LOG_DIR/$name.log" ]] && grep -qiE 'Unable to access jarfile|Port .* was already in use|APPLICATION FAILED TO START' "$LOG_DIR/$name.log" 2>/dev/null; then
      # Give a moment in case log is mid-write from a previous run
      if ! port_is_up "$port"; then
        echo "Startup failure detected for $name. Last log lines:"
        tail -40 "$LOG_DIR/$name.log" || true
        return 1
      fi
    fi
    sleep 2
  done
  echo "Timed out waiting for $name on port $port. Check scripts/logs/$name.log"
  tail -40 "$LOG_DIR/$name.log" || true
  return 1
}

echo "==> Starting backend services..."

start_service eureka-service 8761
wait_port 8761 eureka-service || true

start_service user-service 8081
start_service restaurant-service 8082
start_service order-service 8083
start_service notification-service 8084

wait_port 8081 user-service
wait_port 8082 restaurant-service
wait_port 8083 order-service
wait_port 8084 notification-service

start_service api-gateway 9000
wait_port 9000 api-gateway

echo
echo "Backend is up."
echo "  Gateway:      http://localhost:9000   ← frontend uses this"
echo "  Eureka:       http://localhost:8761"
echo "  User Swagger: http://localhost:8081/swagger-ui.html"
echo
echo "Seeded logins:"
echo "  admin / admin123  (ROLE_ADMIN)"
echo "  user  / user123   (ROLE_USER)"
echo
echo "Logs: $LOG_DIR"
echo "Stop with: ./scripts/stop-backend.sh"
