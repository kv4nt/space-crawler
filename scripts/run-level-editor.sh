#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/tools/level-editor"

if command -v docker >/dev/null 2>&1; then
  echo "Building level editor image..."
  docker build -t space-crawler-level-editor .
  echo "Starting on http://localhost:8080"
  docker run --rm -p 8080:8080 space-crawler-level-editor
else
  echo "Docker not found. Open tools/level-editor/index.html in a browser"
  echo "or run: python3 -m http.server 8080 --directory tools/level-editor"
fi
