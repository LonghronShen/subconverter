#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# --- Pre-flight Check --------------------------------------------------------
check_containers() {
  if ! docker compose -f "$PROJECT_DIR/docker-compose.yml" ps --services --filter "status=running" 2>/dev/null | grep -q .; then
    echo "No containers running — starting legacy_win32_builder..."
    docker compose -f "$PROJECT_DIR/docker-compose.yml" up -d legacy_win32_builder
  fi
}

builder_script() {
  local script_rel="$1"
  shift
  local full_path="/workspace/scripts/$script_rel"
  docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T legacy_win32_builder bash "$full_path" "$@"
}

# --- Cleanup ----------------------------------------------------------------
cleanup() {
  echo "Stopping containers..."
#   docker compose -f "$PROJECT_DIR/docker-compose.yml" down
}
trap cleanup EXIT

# --- Main Execution ---------------------------------------------------------
check_containers

builder_script "build.sh"
