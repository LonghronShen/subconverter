#!/usr/bin/env bash
set -euo pipefail

BIN="${1:?path to subconverter binary}"
PORT="${2:-25500}"
LOG_DIR="${3:-$(pwd)/logs}"
mkdir -p "$LOG_DIR"

RUNTIME_LOG="$LOG_DIR/phase-a-kleinshttp-runtime.log"
IMPORTS_LOG="$LOG_DIR/phase-a-kleinshttp-imports.log"
RUN_LOG="$LOG_DIR/phase-a-kleinshttp-server.log"

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

"$BIN" > "$RUN_LOG" 2>&1 &
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

healthz_code=$(curl -sS -o /tmp/phasea-healthz.out -w "%{http_code}" --max-time 5 "http://127.0.0.1:${PORT}/healthz")
healthz_body=$(cat /tmp/phasea-healthz.out)
version_code=$(curl -sS -o /tmp/phasea-version.out -w "%{http_code}" --max-time 5 "http://127.0.0.1:${PORT}/version")
version_body=$(cat /tmp/phasea-version.out)
unknown_code=$(curl -sS -o /tmp/phasea-unknown.out -w "%{http_code}" --max-time 5 "http://127.0.0.1:${PORT}/definitely-missing-route")
unknown_body=$(cat /tmp/phasea-unknown.out)

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

if command -v file >/dev/null 2>&1 && file "$BIN" | grep -qi 'PE32'; then
  if command -v i686-w64-mingw32-objdump >/dev/null 2>&1; then
    i686-w64-mingw32-objdump -p "$BIN" > "$IMPORTS_LOG" 2>&1 || true
  else
    echo "i686-w64-mingw32-objdump not found" > "$IMPORTS_LOG"
  fi
else
  echo "non-PE binary; import scan skipped" > "$IMPORTS_LOG"
fi

echo "phase-a kleinshttp smoke passed"
