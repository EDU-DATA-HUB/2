#!/usr/bin/env bash
# Quick status of infra + backend ports (Windows-friendly).
# Host mode (start.cmd): expects :8081-:8084 on localhost.
# Docker mode (docker-start): those ports are internal only — show container status.
set -euo pipefail

container_running() {
  local name="$1"
  local st
  st="$(docker inspect -f '{{.State.Status}}' "$name" 2>/dev/null || echo missing)"
  [[ "$st" == "running" ]]
}

check_port() {
  local port="$1" name="$2"
  if command -v powershell.exe >/dev/null 2>&1; then
    if powershell.exe -NoProfile -Command \
      "if (Get-NetTCPConnection -LocalPort ${port} -State Listen -EA SilentlyContinue) { exit 0 } else { exit 1 }" \
      >/dev/null 2>&1; then
      printf '  UP   :%-5s  %s\n' "$port" "$name"
      return 0
    fi
  elif (echo >/dev/tcp/127.0.0.1/"$port") >/dev/null 2>&1; then
    printf '  UP   :%-5s  %s\n' "$port" "$name"
    return 0
  fi
  printf '  DOWN :%-5s  %s\n' "$port" "$name"
  return 1
}

check_container() {
  local cname="$1" label="$2"
  if container_running "$cname"; then
    printf '  UP   %-18s  %s (Docker internal)\n' "$cname" "$label"
    return 0
  fi
  printf '  DOWN %-18s  %s\n' "$cname" "$label"
  return 1
}

MODE="host"
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  if container_running food-gateway && container_running food-frontend; then
    MODE="docker"
  fi
fi

echo "==> Mode: $MODE$([ "$MODE" = docker ] && echo ' (legacy full-stack compose)' || echo ' (start.cmd: Docker infra + local apps)')"
echo "==> Backend / UI"

if [[ "$MODE" == "docker" ]]; then
  check_port 8761 eureka-service || true
  check_port 9000 api-gateway || true
  check_port 4200 frontend || true
  echo
  echo "==> App services (not published on host — OK in Docker mode)"
  check_container food-user user-service || true
  check_container food-restaurant restaurant-service || true
  check_container food-order order-service || true
  check_container food-notification notification-service || true
  echo
  echo "Note: :8081-:8084 are inside the Docker network only."
  echo "Probe via gateway: curl http://127.0.0.1:9000/api/v1/restaurants?page=0&size=1"
else
  check_port 8761 eureka-service || true
  check_port 8081 user-service || true
  check_port 8082 restaurant-service || true
  check_port 8083 order-service || true
  check_port 8084 notification-service || true
  check_port 9000 api-gateway || true
  check_port 4200 frontend || true
  echo
  echo "Note: Eureka UI may be empty — clients are disabled; services use localhost URLs."
  echo "Probe: curl http://127.0.0.1:8082/api/v1/restaurants?page=0&size=1"
fi
