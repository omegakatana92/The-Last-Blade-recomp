#!/usr/bin/env bash
# Build the Linux x86_64 player only (no AppImage).
#
# Usage: ./scripts/build-linux.sh [ROM_DIR] [BUILD_DIR]
#   ROM_DIR   defaults to ./roms
#   BUILD_DIR defaults to ./build-linux
# Output: $BUILD_DIR/TheLastBlade
#
# For the AppImage deliverable use packaging/appimage/build-appimage.sh.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROMS="${1:-$ROOT/roms}"
BUILD="${2:-$ROOT/build-linux}"
cmake -S "$ROOT" -B "$BUILD" -DCMAKE_BUILD_TYPE=Release "-DLASTBLADE_ROM_DIR=$ROMS"
cmake --build "$BUILD" --parallel "$(nproc)"
echo "built $BUILD/TheLastBlade"
