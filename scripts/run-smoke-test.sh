#!/usr/bin/env bash
set -euo pipefail

BIN="${1:?path to subconverter binary}"
PORT="${2:-25500}"
LOG_DIR="${3:-$(pwd)/logs}"
mkdir -p "$LOG_DIR"

# ---------------------------------------------------------------------------
# Determine launcher: use wine for Win32 PE binaries when wine is available.
# A Win32 PE file starts with the two-byte magic "MZ" (0x4d 0x5a).
# "Consumer container" detection: wine present in PATH implies the runtime
# environment is set up for Windows executables (matches consumer.Dockerfile).
# ---------------------------------------------------------------------------
is_win32_pe() {
  local magic
  magic=$(dd if="$1" bs=2 count=1 2>/dev/null | od -A n -t x1 | tr -d ' \n')
  [[ "$magic" == "4d5a" ]]
}

build_launch_cmd() {
  local exe="$1"; shift
  if is_win32_pe "$exe" && command -v wine >/dev/null 2>&1; then
    echo "Detected Win32 PE with wine available — launching via wine" >&2
    LAUNCH_CMD=(wine "$exe" "$@")
  else
    LAUNCH_CMD=("$exe" "$@")
  fi
}

RUNTIME_LOG="$LOG_DIR/runtime.log"
IMPORTS_LOG="$LOG_DIR/imports.log"
RUN_LOG="$LOG_DIR/server.log"

: > "$RUNTIME_LOG"
: > "$IMPORTS_LOG"
: > "$RUN_LOG"

if ! command -v curl >/dev/null 2>&1; then
  echo "curl not found" >&2
  exit 1
fi

cleanup() {
  if [[ -n "${PID:-}" ]]; then
    kill "$PID" 2>/dev/null || true
    wait "$PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

build_launch_cmd "$BIN"
"${LAUNCH_CMD[@]}" > "$RUN_LOG" 2>&1 &
PID=$!

ready=0
for _ in $(seq 1 40); do
  if curl -fsS --max-time 1 "http://127.0.0.1:${PORT}/healthz" >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 0.25
done

if [[ "$ready" -ne 1 ]]; then
  echo "server did not become ready on port ${PORT}" | tee -a "$RUNTIME_LOG"
  tail -n 80 "$RUN_LOG" >> "$RUNTIME_LOG" || true
  exit 1
fi

healthz_code=$(curl -sS -o /tmp/sc-healthz.out -w "%{http_code}" --max-time 5 "http://127.0.0.1:${PORT}/healthz")
healthz_body=$(cat /tmp/sc-healthz.out)
version_code=$(curl -sS -o /tmp/sc-version.out -w "%{http_code}" --max-time 5 "http://127.0.0.1:${PORT}/version")
version_body=$(cat /tmp/sc-version.out)
unknown_code=$(curl -sS -o /tmp/sc-unknown.out -w "%{http_code}" --max-time 5 "http://127.0.0.1:${PORT}/definitely-missing-route")
unknown_body=$(cat /tmp/sc-unknown.out)

{
  echo "healthz_code=${healthz_code}"
  echo "healthz_body=${healthz_body}"
  echo "version_code=${version_code}"
  echo "version_body=${version_body}"
  echo "unknown_code=${unknown_code}"
  echo "unknown_body=${unknown_body}"
  echo
  echo "== server log tail =="
  tail -n 80 "$RUN_LOG" || true
} > "$RUNTIME_LOG"

if [[ "$healthz_code" != "200" || "$healthz_body" != "OK" ]]; then
  echo "healthz assertion failed" >&2
  exit 1
fi
if [[ "$version_code" != "200" || -z "$version_body" ]]; then
  echo "version assertion failed" >&2
  exit 1
fi
if [[ "$unknown_code" != "404" ]]; then
  echo "unknown route assertion failed" >&2
  exit 1
fi

echo "smoke test passed"
