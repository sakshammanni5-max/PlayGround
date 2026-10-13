#!/usr/bin/env bash
# StreamApp preview server.
# Builds the static site (site/ -> dist/) when needed, publishes
# deployment-output.json for the controller, then serves dist/ in the
# foreground on PORT (default 3000). Source and built output stay inside
# PROJECT_DIR; OPENCODE_WEB_DIR/RUNNER_TEMP are only worker metadata.
set -euo pipefail

# cd is a shell builtin: /usr/bin/time cannot execute it, so change directory
# plainly (same as the runtime launcher) and time the external commands below.
cd "$(dirname "$0")"
PROJECT_ROOT="$(/usr/bin/time -p pwd)"
SITE_DIR="$PROJECT_ROOT/site"
DIST_DIR="$PROJECT_ROOT/dist"

/usr/bin/time -p test -d "$SITE_DIR"
/usr/bin/time -p test -f "$SITE_DIR/index.html"

# Rebuild when dist is missing anything or any site source is newer.
rebuild=false
if [[ ! -f "$DIST_DIR/index.html" || ! -f "$DIST_DIR/styles.css" || ! -f "$DIST_DIR/app.js" ]]; then
  rebuild=true
elif [[ -n "$(/usr/bin/time -p find "$SITE_DIR" -type f -newer "$DIST_DIR/index.html" -print -quit)" ]]; then
  rebuild=true
fi

if [[ "$rebuild" == true ]]; then
  echo "building static site: $SITE_DIR -> $DIST_DIR"
  /usr/bin/time -p rm -rf "$DIST_DIR"
  /usr/bin/time -p mkdir -p "$DIST_DIR"
  /usr/bin/time -p cp "$SITE_DIR/index.html" "$SITE_DIR/styles.css" "$SITE_DIR/app.js" "$DIST_DIR/"
  COMMIT="$(/usr/bin/time -p git rev-parse --short HEAD 2>/dev/null || echo no-commit)"
  /usr/bin/time -p node -e 'require("node:fs").writeFileSync(process.argv[1], JSON.stringify({ built_at: new Date().toISOString(), commit: process.argv[2] }) + "\n")' "$DIST_DIR/build-info.json" "$COMMIT"
else
  echo "static site up to date: $DIST_DIR"
fi

/usr/bin/time -p test -f "$DIST_DIR/index.html"

: "${OPENCODE_WEB_DIR:?OPENCODE_WEB_DIR must point at the worker metadata dir.}"
/usr/bin/time -p mkdir -p "$OPENCODE_WEB_DIR"
/usr/bin/time -p node -e 'require("node:fs").writeFileSync(process.argv[3], JSON.stringify({ project: process.argv[1], directory: process.argv[2] }) + "\n")' "$PROJECT_ROOT" "$DIST_DIR" "$OPENCODE_WEB_DIR/deployment-output.json"
echo "wrote $OPENCODE_WEB_DIR/deployment-output.json"
# Serve in the foreground. OPENCODE_WEB_DIR is intentionally blanked for the
# static server so it cannot overwrite the deployment-output.json written above
# (it only writes that file when the variable is set).
PORT="${PORT:-3000}"
export PORT
echo "serving $DIST_DIR on 0.0.0.0:$PORT (foreground)"
/usr/bin/time -p true
cd "$DIST_DIR"
OPENCODE_WEB_DIR= exec node "${RUNTIME_DIR:?}/scripts/default-start.mjs"
