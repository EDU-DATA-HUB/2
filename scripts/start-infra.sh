#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "==> Starting local infrastructure (MySQL, Redis, Kafka)..."
if ! docker info >/dev/null 2>&1; then
  echo "Docker is not running. Start Docker Desktop, then re-run this script."
  exit 1
fi

docker compose up -d

echo "==> Waiting for MySQL..."
for i in $(seq 1 40); do
  if docker exec food-mysql mysqladmin ping -h localhost -uroot -p1999 --silent >/dev/null 2>&1; then
    echo "MySQL is ready."
    break
  fi
  if [[ "$i" -eq 40 ]]; then
    echo "MySQL did not become ready in time."
    exit 1
  fi
  sleep 2
done

echo "==> Waiting for Redis..."
for i in $(seq 1 20); do
  if docker exec food-redis redis-cli ping 2>/dev/null | grep -q PONG; then
    echo "Redis is ready."
    break
  fi
  if [[ "$i" -eq 20 ]]; then
    echo "Redis did not become ready in time."
    exit 1
  fi
  sleep 1
done

echo "==> Infra is up."
docker compose ps
