#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-$HOME/Загрузки/Godot_v4.7.1-stable_linux.x86_64}"
APK="$ROOT/build/space-crawler.apk"

export GODOT_ANDROID_KEYSTORE_DEBUG_PATH="${GODOT_ANDROID_KEYSTORE_DEBUG_PATH:-$HOME/.local/share/godot/keystores/debug.keystore}"
export GODOT_ANDROID_KEYSTORE_DEBUG_USER="${GODOT_ANDROID_KEYSTORE_DEBUG_USER:-androiddebugkey}"
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD="${GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD:-android}"
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:-$GODOT_ANDROID_KEYSTORE_DEBUG_PATH}"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="${GODOT_ANDROID_KEYSTORE_RELEASE_USER:-$GODOT_ANDROID_KEYSTORE_DEBUG_USER}"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="${GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD:-$GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD}"

mkdir -p "$ROOT/build"
"$HOME/Android/Sdk/platform-tools/adb" start-server >/dev/null 2>&1 || true

if [[ ! -d "$ROOT/app/android" ]]; then
  "$GODOT" --headless --path "$ROOT/app" --install-android-build-template --quit-after 1
fi

"$GODOT" --headless --path "$ROOT/app" --export-release "Android" "$APK"
echo "Built: $APK"
