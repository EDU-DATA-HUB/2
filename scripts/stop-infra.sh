#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "==> Stopping infrastructure containers..."
docker compose down
echo "Done. (MySQL data volume kept: food_mysql_data)"
