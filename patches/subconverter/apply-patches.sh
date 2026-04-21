#!/usr/bin/env bash
set -euo pipefail

# apply-patches.sh - Apply subconverter kleinsHTTP patches
# Usage: ./apply-patches.sh [patch-dir]

PATCH_DIR="${1:-patches/subconverter}"
SERIES="${PATCH_DIR}/series.txt"

if [[ ! -f "$SERIES" ]]; then
  echo "ERROR: series.txt not found in $PATCH_DIR"
  exit 1
fi

echo "Applying patches from $PATCH_DIR..."
while IFS= read -r patch_file; do
  [[ -z "$patch_file" ]] && continue
  [[ "$patch_file" =~ ^# ]] && continue
  
  patch_path="${PATCH_DIR}/${patch_file}"
  if [[ ! -f "$patch_path" ]]; then
    echo "WARNING: $patch_path not found, skipping"
    continue
  fi
  
  echo "Applying $patch_file..."
  if patch -p1 < "$patch_path"; then
    echo "  OK"
  else
    echo "  FAILED"
    exit 1
  fi
done < "$SERIES"

echo "All patches applied successfully"
