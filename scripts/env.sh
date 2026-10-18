#!/usr/bin/env bash
# Shared local / offline environment (Git Bash, WSL, MSYS on Windows).
# Discovers JDK 8 / 11 / 17 installs; Spring Boot 2.7 JARs run on Java 8+.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Minimum major version required to run this offline bundle (Spring Boot 2.7.18 + Java 8 bytecode).
REQUIRED_JAVA_MAJOR=8

_JAVA_CANDIDATES=()

_add_candidate() {
  local p="${1:-}"
  [[ -z "$p" ]] && return 0
  _JAVA_CANDIDATES+=("$p")
}

_add_candidate "${JAVA_HOME:-}"

# Explicit well-known homes (Git Bash + WSL)
for _ver in 17 11 8; do
  _add_candidate "/c/Program Files/Java/jdk-${_ver}"
  _add_candidate "/mnt/c/Program Files/Java/jdk-${_ver}"
  _add_candidate "/c/Program Files/Eclipse Adoptium/jdk-${_ver}"
  _add_candidate "/mnt/c/Program Files/Eclipse Adoptium/jdk-${_ver}"
done
# Legacy Oracle layout
_add_candidate "/c/Program Files/Java/jdk1.8.0_471"
_add_candidate "/mnt/c/Program Files/Java/jdk1.8.0_471"
_add_candidate "/c/Program Files/Java/jre1.8.0_471"

# Glob common vendor roots for jdk-17*, jdk-11*, jdk-8*, jdk1.8*
for _root in \
  "/c/Program Files/Java" \
  "/mnt/c/Program Files/Java" \
  "/c/Program Files/Eclipse Adoptium" \
  "/mnt/c/Program Files/Eclipse Adoptium" \
  "/c/Program Files/Microsoft" \
  "/mnt/c/Program Files/Microsoft" \
  "/c/Program Files/Amazon Corretto" \
  "/mnt/c/Program Files/Amazon Corretto"
do
  [[ -d "$_root" ]] || continue
  for _d in "$_root"/jdk-17* "$_root"/jdk-11* "$_root"/jdk-8* "$_root"/jdk1.8* "$_root"/jre1.8*; do
    [[ -d "$_d" ]] && _add_candidate "$_d"
  done
done

# Return 0 and print "HOME|BIN" if this JDK dir is usable
_resolve_jdk() {
  local home="$1"
  [[ -z "$home" || ! -d "$home" ]] && return 1
  if [[ -x "$home/bin/java" ]]; then
    printf '%s|%s' "$home" "$home/bin/java"
    return 0
  fi
  if [[ -f "$home/bin/java.exe" ]]; then
    printf '%s|%s' "$home" "$home/bin/java.exe"
    return 0
  fi
  return 1
}

# Print major version for a java binary (8, 11, 17, 21, ...)
_java_major() {
  local bin="$1"
  local line ver
  line="$("$bin" -version 2>&1 | head -1 || true)"
  # Examples: java version "1.8.0_471"  OR  openjdk version "17.0.17"
  if [[ "$line" =~ \"1\.([0-9]+) ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
    return 0
  fi
  if [[ "$line" =~ \"([0-9]+) ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
    return 0
  fi
  printf '%s' "0"
}

# Prefer highest usable JDK among 17 / 11 / 8 (and newer if present).
# Returns HOME|BIN|MAJOR for the best candidate that meets REQUIRED_JAVA_MAJOR,
# or the best available (any) if none meet — caller validates.
_pick_jdk() {
  local cand resolved home bin major
  local best_home="" best_bin="" best_major=-1
  local ok_home="" ok_bin="" ok_major=-1

  for cand in "${_JAVA_CANDIDATES[@]}"; do
    [[ -z "$cand" ]] && continue
    resolved="$(_resolve_jdk "$cand" || true)"
    [[ -z "$resolved" ]] && continue
    home="${resolved%%|*}"
    bin="${resolved##*|}"
    major="$(_java_major "$bin")"
    [[ "$major" =~ ^[0-9]+$ ]] || continue

    if (( major > best_major )); then
      best_major=$major
      best_home=$home
      best_bin=$bin
    fi
    if (( major >= REQUIRED_JAVA_MAJOR && major > ok_major )); then
      ok_major=$major
      ok_home=$home
      ok_bin=$bin
    fi
  done

  if [[ -n "$ok_home" ]]; then
    printf '%s|%s|%s' "$ok_home" "$ok_bin" "$ok_major"
    return 0
  fi
  if [[ -n "$best_home" ]]; then
    printf '%s|%s|%s' "$best_home" "$best_bin" "$best_major"
    return 0
  fi
  return 1
}

_fail_java() {
  echo "ERROR: $*"
  echo
  echo "This offline bundle ships Spring Boot 2.7 JARs → runtime needs Java ${REQUIRED_JAVA_MAJOR}+ (8, 11, or 17)."
  echo "Scripts detect JDK 8 / 11 / 17 under Program Files and pick the newest eligible install."
  echo
  echo "Set JAVA_HOME to a JDK ${REQUIRED_JAVA_MAJOR}+ install, for example:"
  echo "  # Git Bash"
  echo "  export JAVA_HOME=\"/c/Program Files/Java/jdk-17\""
  echo "  # WSL"
  echo "  export JAVA_HOME=\"/mnt/c/Program Files/Java/jdk-17\""
  echo "  # Java 8 example"
  echo "  export JAVA_HOME=\"/c/Program Files/Java/jdk1.8.0_471\""
  exit 1
}

if _picked="$(_pick_jdk)"; then
  export JAVA_HOME="${_picked%%|*}"
  _rest="${_picked#*|}"
  export JAVA_BIN="${_rest%%|*}"
  JAVA_MAJOR="${_rest##*|}"
elif command -v java >/dev/null 2>&1; then
  export JAVA_BIN="$(command -v java)"
  export JAVA_HOME="$(cd "$(dirname "$JAVA_BIN")/.." && pwd)"
  JAVA_MAJOR="$(_java_major "$JAVA_BIN")"
elif command -v java.exe >/dev/null 2>&1; then
  export JAVA_BIN="$(command -v java.exe)"
  export JAVA_HOME="$(cd "$(dirname "$JAVA_BIN")/.." && pwd)"
  JAVA_MAJOR="$(_java_major "$JAVA_BIN")"
else
  _fail_java "No JDK found (looked for Java 8 / 11 / 17 under Program Files and JAVA_HOME)."
fi

export PATH="$JAVA_HOME/bin:$PATH"
export JAVA_MAJOR

echo "JAVA_HOME=$JAVA_HOME"
echo "JAVA_BIN=$JAVA_BIN"
echo "JAVA_MAJOR=$JAVA_MAJOR (required >= $REQUIRED_JAVA_MAJOR to run services)"
"$JAVA_BIN" -version

if ! [[ "$JAVA_MAJOR" =~ ^[0-9]+$ ]] || (( JAVA_MAJOR < REQUIRED_JAVA_MAJOR )); then
  _fail_java "Found Java ${JAVA_MAJOR:-unknown}, but this bundle requires Java ${REQUIRED_JAVA_MAJOR}+."
fi
