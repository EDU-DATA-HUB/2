#!/usr/bin/env bash
# =============================================================================
# checklist.sh — smoke / health checklist for food-order-microservice
# Run via test-al.bat or:  bash ./scripts/checklist.sh
# Exit 0 = all critical checks passed; 1 = one or more FAIL
#
# Supports two modes:
#   HOST   — start.cmd (infra ports published; Java on :8081-8084)
#   DOCKER — docker-start.bat (apps only via :9000/:4200/:8761; infra internal)
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

PASS=0
FAIL=0
WARN=0

ok()   { PASS=$((PASS + 1)); printf '  [PASS] %s\n' "$*"; }
bad()  { FAIL=$((FAIL + 1)); printf '  [FAIL] %s\n' "$*"; }
warn() { WARN=$((WARN + 1)); printf '  [WARN] %s\n' "$*"; }
sec()  { echo; echo "==> $*"; }

port_up() {
  local port="$1"
  if command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -NoProfile -Command \
      "if (Get-NetTCPConnection -LocalPort ${port} -State Listen -EA SilentlyContinue) { exit 0 } else { exit 1 }" \
      >/dev/null 2>&1 && return 0
  fi
  if command -v curl >/dev/null 2>&1; then
    curl -s -m 1 -o /dev/null "http://127.0.0.1:${port}/" 2>/dev/null && return 0
  fi
  (echo >/dev/tcp/127.0.0.1/"$port") >/dev/null 2>&1
}

http_code() {
  local url="$1"; shift
  local code
  code="$(curl -sS --noproxy '*' --connect-timeout 3 -m 10 -o /tmp/food-check-body.$$ -w '%{http_code}' "$@" "$url" 2>/dev/null)" || true
  if [[ -z "$code" || ! "$code" =~ ^[0-9]{3}$ ]]; then
    printf '%s' "000"
  else
    printf '%s' "$code"
  fi
}

jar_boot_version() {
  local jar="$1"
  unzip -p "$jar" META-INF/MANIFEST.MF 2>/dev/null | tr -d '\r' | awk -F': ' '/^Spring-Boot-Version:/{print $2; exit}'
}

container_running() {
  local name="$1"
  local st
  st="$(docker inspect -f '{{.State.Status}}' "$name" 2>/dev/null || echo missing)"
  [[ "$st" == "running" ]]
}

# Detect docker-start (offline) stack: app containers on internal network
MODE="host"
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  if container_running food-gateway && container_running food-frontend; then
    MODE="docker"
  fi
fi

echo "============================================"
echo " Food Order — CHECKLIST"
echo " Root: $ROOT_DIR"
echo " Mode: $MODE$([ "$MODE" = docker ] && echo ' (docker-start.bat / offline)' || echo ' (start.cmd / host)')"
echo " Time: $(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date)"
echo "============================================"

# -----------------------------------------------------------------------------
sec "1. Prerequisites"
# -----------------------------------------------------------------------------
if command -v curl >/dev/null 2>&1; then
  ok "curl available"
else
  bad "curl not found (needed for HTTP smoke tests)"
fi

if [[ "$MODE" == "docker" ]]; then
  ok "Docker-only mode — host JDK/Node not required for runtime"
  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    ok "Docker daemon reachable"
  else
    bad "Docker daemon not reachable"
  fi
else
  if [[ -f "$SCRIPT_DIR/env.sh" ]]; then
    # shellcheck source=env.sh
    if source "$SCRIPT_DIR/env.sh" >/tmp/food-check-env.$$ 2>&1; then
      ok "Java detected: JAVA_MAJOR=${JAVA_MAJOR:-?} (required >= 8)  JAVA_HOME=${JAVA_HOME:-}"
      if [[ "${JAVA_MAJOR:-0}" =~ ^[0-9]+$ ]] && (( JAVA_MAJOR >= 8 )); then
        ok "Java version eligible for Spring Boot 2.7"
      else
        bad "Java major ${JAVA_MAJOR:-unknown} is below 8"
      fi
    else
      bad "scripts/env.sh failed to resolve a usable JDK"
      cat /tmp/food-check-env.$$ 2>/dev/null | sed 's/^/         /' | head -20
    fi
  else
    bad "scripts/env.sh missing"
  fi

  if command -v node >/dev/null 2>&1 || command -v node.exe >/dev/null 2>&1; then
    NODE_BIN="$(command -v node.exe 2>/dev/null || command -v node)"
    NODE_VER="$("$NODE_BIN" -v 2>/dev/null || echo unknown)"
    ok "Node.js $NODE_VER"
  else
    warn "Node.js not on PATH (frontend start will fail)"
  fi

  if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
      ok "Docker daemon reachable"
    else
      bad "Docker installed but daemon not reachable (start Docker Desktop)"
    fi
  else
    bad "docker not found"
  fi
fi

# -----------------------------------------------------------------------------
sec "2. Build artifacts (Spring Boot 2.7 JARs)"
# -----------------------------------------------------------------------------
SERVICES=(eureka-service user-service restaurant-service order-service notification-service api-gateway)
if [[ "$MODE" == "docker" ]]; then
  ok "Docker-only mode — runtime uses images (JARs optional on this PC)"
  # Still report JAR status as WARN if missing (useful on pack machine)
  for svc in "${SERVICES[@]}"; do
    jar="$(ls "$ROOT_DIR/$svc/target/"*-SNAPSHOT.jar 2>/dev/null | grep -v original | head -1 || true)"
    if [[ -n "$jar" && -f "$jar" ]]; then
      ver="$(jar_boot_version "$jar")"
      if [[ "$ver" == 2.7.* ]]; then
        ok "$svc — $(basename "$jar")  Spring-Boot=$ver"
      else
        warn "$svc — JAR present (Spring-Boot=${ver:-unknown})"
      fi
    else
      warn "$svc — no local JAR (OK for offline PC using images only)"
    fi
  done
else
  for svc in "${SERVICES[@]}"; do
    jar="$(ls "$ROOT_DIR/$svc/target/"*-SNAPSHOT.jar 2>/dev/null | grep -v original | head -1 || true)"
    if [[ -z "$jar" || ! -f "$jar" ]]; then
      bad "$svc — missing target/*-SNAPSHOT.jar (run ./mvnw -DskipTests package)"
      continue
    fi
    ver="$(jar_boot_version "$jar")"
    if [[ "$ver" == 2.7.* ]]; then
      ok "$svc — $(basename "$jar")  Spring-Boot=$ver"
    elif [[ -n "$ver" ]]; then
      bad "$svc — Spring-Boot=$ver (expected 2.7.x)"
    else
      warn "$svc — JAR present but Spring-Boot-Version not in MANIFEST"
    fi
  done

  if [[ -d "$ROOT_DIR/frontend/node_modules" ]]; then
    ok "frontend/node_modules present"
  else
    warn "frontend/node_modules missing (offline pack or npm install needed)"
  fi
fi

# -----------------------------------------------------------------------------
sec "3. Infrastructure (Docker compose services)"
# -----------------------------------------------------------------------------
expect_container() {
  local name="$1"
  if ! command -v docker >/dev/null 2>&1; then
    warn "skip container check: $name"
    return
  fi
  if container_running "$name"; then
    ok "container $name is running"
  else
    if [[ "$MODE" == "docker" ]]; then
      bad "container $name not running (run docker-start.bat)"
    else
      bad "container $name not running (run start-infra / start.cmd)"
    fi
  fi
}
expect_container food-mysql
expect_container food-redis
expect_container food-zookeeper
expect_container food-kafka

if [[ "$MODE" == "docker" ]]; then
  # Infra is on internal Docker network only — probe inside containers
  if container_running food-mysql \
    && docker exec food-mysql mysqladmin ping -h localhost -uroot -p1999 --silent >/dev/null 2>&1; then
    ok "MySQL healthy inside container (not published on host :3306 — expected)"
  else
    bad "MySQL not healthy inside food-mysql"
  fi
  if container_running food-redis \
    && docker exec food-redis redis-cli ping 2>/dev/null | grep -q PONG; then
    ok "Redis healthy inside container (not published on host :6379 — expected)"
  else
    bad "Redis not healthy inside food-redis"
  fi
  local_k="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' food-kafka 2>/dev/null || echo missing)"
  if [[ "$local_k" == "healthy" ]]; then
    ok "Kafka healthy inside container (not published on host :29092 — expected)"
  elif container_running food-kafka; then
    warn "Kafka running but health=$local_k (may still be starting)"
  else
    bad "Kafka container not usable"
  fi
else
  for pair in "3306:MySQL" "6379:Redis" "29092:Kafka"; do
    port="${pair%%:*}"
    name="${pair##*:}"
    if port_up "$port"; then
      ok "infra port :$port ($name) listening"
    else
      bad "infra port :$port ($name) not listening"
    fi
  done
fi

# -----------------------------------------------------------------------------
sec "4. Backend / frontend ports"
# -----------------------------------------------------------------------------
if [[ "$MODE" == "docker" ]]; then
  for name in food-eureka food-user food-restaurant food-order food-notification food-gateway food-frontend; do
    expect_container "$name"
  done
  for pair in "8761:eureka" "9000:api-gateway" "4200:frontend"; do
    port="${pair%%:*}"
    name="${pair##*:}"
    if port_up "$port"; then
      ok "host port :$port ($name) UP"
    else
      bad "host port :$port ($name) DOWN — expected for docker-start"
    fi
  done
  ok "internal app ports :8081-:8084 not published on host — expected in Docker mode"
else
  declare -a PORT_CHECKS=(
    "8761:eureka-service"
    "8081:user-service"
    "8082:restaurant-service"
    "8083:order-service"
    "8084:notification-service"
    "9000:api-gateway"
    "4200:frontend"
  )
  for pair in "${PORT_CHECKS[@]}"; do
    port="${pair%%:*}"
    name="${pair##*:}"
    if port_up "$port"; then
      ok "port :$port ($name) UP"
    else
      if [[ "$name" == "frontend" ]]; then
        warn "port :$port ($name) DOWN — start with start-frontend.sh / start.cmd"
      else
        bad "port :$port ($name) DOWN — start with start-backend.sh / start.cmd"
      fi
    fi
  done
fi

# -----------------------------------------------------------------------------
sec "5. HTTP smoke tests (gateway + services)"
# -----------------------------------------------------------------------------
if ! command -v curl >/dev/null 2>&1; then
  warn "Skipping HTTP smoke (no curl)"
else
  if [[ "$MODE" == "docker" ]]; then
    ok "skip direct :8082 restaurant check (not published in Docker mode)"
  else
    code="$(http_code 'http://127.0.0.1:8082/api/v1/restaurants?page=0&size=1')"
    if [[ "$code" == "200" ]]; then
      ok "restaurant-service GET /api/v1/restaurants → HTTP $code"
    else
      bad "restaurant-service GET /api/v1/restaurants → HTTP $code (expect 200)"
    fi
  fi

  code="$(http_code 'http://127.0.0.1:9000/api/v1/restaurants?page=0&size=1')"
  if [[ "$code" == "200" ]]; then
    ok "gateway GET /api/v1/restaurants → HTTP $code"
  else
    bad "gateway GET /api/v1/restaurants → HTTP $code (expect 200; gateway/restaurant down?)"
  fi

  code="$(http_code 'http://127.0.0.1:9000/api/v1/auth/login' \
    -H 'Content-Type: application/json' \
    -d '{"username":"user","password":"user123"}')"
  body="$(cat /tmp/food-check-body.$$ 2>/dev/null || true)"
  if [[ "$code" == "200" ]] && echo "$body" | grep -qi 'token\|jwt\|Bearer\|eyJ'; then
    ok "gateway POST /api/v1/auth/login (user/user123) → HTTP $code + token"
    TOKEN="$(echo "$body" | sed -n 's/.*"token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
    if [[ -z "$TOKEN" ]]; then
      TOKEN="$(echo "$body" | sed -n 's/.*"accessToken"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
    fi
  elif [[ "$code" == "200" ]]; then
    warn "login HTTP 200 but token field not recognized in body"
    TOKEN=""
  else
    bad "gateway POST /api/v1/auth/login → HTTP $code (seed users? user-service up?)"
    TOKEN=""
  fi

  code="$(http_code 'http://127.0.0.1:9000/api/v1/auth/login' \
    -H 'Content-Type: application/json' \
    -d '{"username":"user","password":"wrong-password"}')"
  if [[ "$code" == "401" || "$code" == "400" || "$code" == "403" ]]; then
    ok "login rejects bad password → HTTP $code"
  elif [[ "$code" == "000" ]]; then
    bad "login bad-password probe unreachable"
  else
    warn "login bad password → HTTP $code (expected 4xx)"
  fi

  if [[ -n "${TOKEN:-}" ]]; then
    code="$(http_code 'http://127.0.0.1:9000/api/v1/users/profile' \
      -H "Authorization: Bearer $TOKEN")"
    if [[ "$code" == "200" ]]; then
      ok "gateway GET /api/v1/users/profile with JWT → HTTP $code"
    else
      code2="$(http_code "http://127.0.0.1:9000/api/v1/auth/validateToken?token=${TOKEN}" -X POST)"
      if [[ "$code2" == "200" ]]; then
        ok "gateway POST /api/v1/auth/validateToken → HTTP $code2 (profile path returned $code)"
      else
        warn "authenticated profile → HTTP $code (token validate → $code2) — check user routes"
      fi
    fi
  fi

  code="$(http_code 'http://127.0.0.1:8761/')"
  if [[ "$code" == "200" ]]; then
    ok "eureka UI → HTTP $code (registry may be empty — clients disabled)"
  else
    bad "eureka UI → HTTP $code"
  fi

  code="$(http_code 'http://127.0.0.1:4200/')"
  if [[ "$code" == "200" ]]; then
    ok "frontend :4200 → HTTP $code"
  else
    warn "frontend :4200 → HTTP $code"
  fi
fi

# -----------------------------------------------------------------------------
sec "6. Recent errors in service logs"
# -----------------------------------------------------------------------------
if [[ "$MODE" == "docker" ]]; then
  for name in food-eureka food-user food-restaurant food-order food-notification food-gateway; do
    if ! container_running "$name"; then
      warn "skip logs: $name not running"
      continue
    fi
    hits="$(docker logs --tail 200 "$name" 2>&1 | grep -cE 'ERROR|Exception|Failed to start|APPLICATION FAILED' || true)"
    if [[ "${hits:-0}" -eq 0 ]]; then
      ok "$name — no ERROR/Exception in last 200 docker log lines"
    elif [[ "$hits" -le 5 ]]; then
      warn "$name — $hits ERROR/Exception line(s) in last 200 (docker logs $name)"
    else
      bad "$name — $hits ERROR/Exception line(s) in last 200"
    fi
  done
else
  LOG_DIR="$ROOT_DIR/scripts/logs"
  if [[ -d "$LOG_DIR" ]]; then
    for svc in "${SERVICES[@]}"; do
      log="$LOG_DIR/$svc.log"
      if [[ ! -f "$log" ]]; then
        warn "no log yet: scripts/logs/$svc.log"
        continue
      fi
      hits="$(tail -n 200 "$log" 2>/dev/null | grep -cE 'ERROR|Exception|Failed to start|APPLICATION FAILED' || true)"
      if [[ "${hits:-0}" -eq 0 ]]; then
        ok "$svc.log — no ERROR/Exception in last 200 lines"
      elif [[ "$hits" -le 3 ]]; then
        warn "$svc.log — $hits ERROR/Exception line(s) in last 200 (review scripts/logs/$svc.log)"
      else
        bad "$svc.log — $hits ERROR/Exception line(s) in last 200 (likely runtime bug)"
      fi
    done
  else
    warn "scripts/logs/ missing (services not started via scripts yet)"
  fi
fi

# -----------------------------------------------------------------------------
sec "SUMMARY"
# -----------------------------------------------------------------------------
echo "  PASS=$PASS  FAIL=$FAIL  WARN=$WARN"
echo
if (( FAIL == 0 )); then
  echo "  Result: OK — critical checks passed."
  if (( WARN > 0 )); then
    echo "  Review WARN items above if something still looks wrong in the UI."
  fi
  echo
  echo "  UI:      http://localhost:4200"
  echo "  Gateway: http://localhost:9000"
  echo "  Login:   user / user123  |  admin / admin123"
  rm -f /tmp/food-check-body.$$ /tmp/food-check-env.$$ 2>/dev/null || true
  exit 0
fi

echo "  Result: PROBLEMS FOUND — fix FAIL items, then re-run test-al.bat"
echo "  Tips:"
if [[ "$MODE" == "docker" ]]; then
  echo "    docker-start.bat / docker-stop.bat"
  echo "    docker compose -f docker-compose.offline.yml ps"
  echo "    docker logs <container>"
else
  echo "    start.cmd              start infra + backend + frontend"
  echo "    status.cmd             port overview"
  echo "    scripts\\logs\\*.log    service error details"
fi
rm -f /tmp/food-check-body.$$ /tmp/food-check-env.$$ 2>/dev/null || true
exit 1
