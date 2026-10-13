#!/usr/bin/env bash
# Capture desktop + mobile screenshots of the exact CAPTURE_URL into
# CAPTURE_DIR (outside the project source). Leaves the app server running.
# Exit 75: temporary navigation/browser infrastructure failure.
# Exit 1: script or rendering defect (bad args, non-retryable HTTP, blank render).
set -euo pipefail

# cd is a shell builtin and cannot be timed with /usr/bin/time.
cd "$(dirname "$0")"
: "${CAPTURE_URL:?Set CAPTURE_URL to the exact URL to capture.}"
: "${CAPTURE_DIR:?Set CAPTURE_DIR to the screenshot output directory.}"
: "${RUNTIME_DIR:?RUNTIME_DIR must point at the runtime scripts dir.}"
/usr/bin/time -p mkdir -p "$CAPTURE_DIR"
/usr/bin/time -p node "$RUNTIME_DIR/scripts/default-capture.mjs"
status=$?
if [[ $status -eq 0 ]]; then
  /usr/bin/time -p test -s "$CAPTURE_DIR/final-desktop.png"
  /usr/bin/time -p test -s "$CAPTURE_DIR/final-mobile.png"
  echo "captured $CAPTURE_DIR/final-desktop.png + final-mobile.png"
fi
exit "$status"
