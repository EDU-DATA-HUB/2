#!/usr/bin/env bash
# Start Angular frontend. Works from Git Bash or WSL → Windows Node (nvm4w).
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FRONTEND_DIR="$ROOT_DIR/frontend"
cd "$FRONTEND_DIR"

if [[ ! -d node_modules ]]; then
  echo "ERROR: node_modules missing."
  echo "Online: run npm install"
  echo "Offline: use the 02-app.tar.gz bundle (includes node_modules) — do not npm install."
  exit 1
fi

resolve_node() {
  local cand
  for cand in \
    "${NODE_BIN:-}" \
    "$(command -v node 2>/dev/null || true)" \
    "$(command -v node.exe 2>/dev/null || true)" \
    "/c/nvm4w/nodejs/node.exe" \
    "/mnt/c/nvm4w/nodejs/node.exe" \
    "/c/Program Files/nodejs/node.exe" \
    "/mnt/c/Program Files/nodejs/node.exe"
  do
    [[ -z "$cand" ]] && continue
    if [[ -x "$cand" || -f "$cand" ]]; then
      printf '%s' "$cand"
      return 0
    fi
  done
  return 1
}

to_win_path() {
  local p="$1"
  if command -v wslpath >/dev/null 2>&1; then
    wslpath -w "$p"
  elif command -v cygpath >/dev/null 2>&1; then
    cygpath -w "$p"
  else
    echo "$p"
  fi
}

NG_JS="$FRONTEND_DIR/node_modules/@angular/cli/bin/ng.js"
if [[ ! -f "$NG_JS" ]]; then
  echo "ERROR: Angular CLI not found at node_modules/@angular/cli/bin/ng.js"
  exit 1
fi

NODE_BIN="$(resolve_node)" || {
  echo "ERROR: Node.js not found."
  echo "  Install Node 18+ on Windows, or from WSL:"
  echo "    export NODE_BIN=/mnt/c/nvm4w/nodejs/node.exe"
  exit 1
}

echo "==> Starting Angular at http://localhost:4200 (offline-safe, no install)"
echo "    NODE_BIN=$NODE_BIN"

case "$NODE_BIN" in
  *.exe|*/node.exe)
    WIN_DIR="$(to_win_path "$FRONTEND_DIR")"
    WIN_NODE="$(to_win_path "$NODE_BIN")"
    WIN_NG="$(to_win_path "$NG_JS")"
    # Avoid nested cmd quoting issues: write a tiny launcher .cmd and run it
    LAUNCHER="$ROOT_DIR/scripts/.run-frontend.cmd"
    # CMD file must use CRLF-friendly lines; avoid bash-expanded escapes
    {
      printf '%s\r\n' '@echo off'
      printf '%s\r\n' "cd /d \"$WIN_DIR\""
      printf '%s\r\n' "\"$WIN_NODE\" \"$WIN_NG\" serve --host 0.0.0.0 --port 4200"
    } >"$LAUNCHER"

    WIN_LAUNCHER="$(to_win_path "$LAUNCHER")"
    echo "    frontend=$WIN_DIR"
    echo "    launcher=$WIN_LAUNCHER"
    exec cmd.exe /c "$WIN_LAUNCHER"
    ;;
  *)
    exec "$NODE_BIN" "$NG_JS" serve --host 0.0.0.0 --port 4200
    ;;
esac
