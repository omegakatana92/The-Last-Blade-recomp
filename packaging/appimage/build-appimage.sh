#!/usr/bin/env bash
# Build the Linux x86_64 player and package it as a Steam Deck / Linux
# AppImage.
#
# Prerequisites: gcc, g++, cmake 3.21+, make (or ninja), libsdl2-dev,
# pkg-config, wget, python3. Your ROMs are never bundled: the AppImage
# contains only the recompiled player and its runtime libraries.
#
# Usage: ./packaging/appimage/build-appimage.sh [ROM_DIR]
#   ROM_DIR defaults to $ROOT/roms.
# Output: dist/steamdeck/The Last Blade-SteamDeck-x86_64.AppImage
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ROMS="${1:-$ROOT/roms}"
BUILD="${BUILD_DIR:-$ROOT/build-linux}"
APPDIR="$BUILD/AppDir"
OUT="$ROOT/dist/steamdeck/The Last Blade-SteamDeck-x86_64.AppImage"
DOC="$APPDIR/usr/share/doc/thelastblade"

echo "== configure/build (Release) =="
cmake -S "$ROOT" -B "$BUILD" -DCMAKE_BUILD_TYPE=Release "-DLASTBLADE_ROM_DIR=$ROMS"
cmake --build "$BUILD" --parallel "$(nproc)"

echo "== assemble AppDir =="
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/lib" \
         "$APPDIR/usr/share/applications" \
         "$APPDIR/usr/share/icons/hicolor/256x256/apps" \
         "$DOC/LICENSES"
cp "$BUILD/TheLastBlade" "$APPDIR/usr/bin/TheLastBlade"
strip --strip-unneeded "$APPDIR/usr/bin/TheLastBlade" 2>/dev/null || true

# Bundle the SDL2 the build linked against. Do not bundle glibc, libstdc++,
# libgcc or the graphics stack: SteamOS provides those, and bundling them is
# a common source of AppImage breakage.
SDL=$(ldd "$BUILD/TheLastBlade" | awk '/libSDL2-2\.0\.so\.0/{print $3; exit}')
if [ -n "$SDL" ]; then cp "$SDL" "$APPDIR/usr/lib/"; fi

python3 "$ROOT/packaging/appimage/make_icon.py"
cp "$ROOT/packaging/appimage/thelastblade.png" "$APPDIR/thelastblade.png"
cp "$ROOT/packaging/appimage/thelastblade.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/thelastblade.png"
cp "$ROOT/packaging/appimage/thelastblade.desktop" "$APPDIR/thelastblade.desktop"
cp "$ROOT/packaging/appimage/thelastblade.desktop" "$APPDIR/usr/share/applications/thelastblade.desktop"
cp "$ROOT/packaging/appimage/README.txt" "$DOC/README.txt"
cp "$ROOT/LICENSE" "$DOC/LICENSE.txt"
cp "$ROOT/THIRD_PARTY_NOTICES.md" "$DOC/THIRD_PARTY_NOTICES.md"
cp "$ROOT/docs/rom-layout.md" "$DOC/ROM-LAYOUT.md"
cp "$ROOT/neogeorecomp/LICENSE" "$DOC/LICENSES/neogeorecomp.txt"
cp "$ROOT/neogeorecomp/NOTICE" "$DOC/LICENSES/neogeorecomp-NOTICE.txt"
cp "$ROOT/neogeorecomp/LICENSES/"*.txt "$DOC/LICENSES/"
cp "$ROOT/packaging/SDL2.txt" "$DOC/LICENSES/SDL2.txt"

cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/sh
# Find the ROMs before starting: beside the AppImage (the normal Steam Deck
# case), or in the usual EmulationStation folders. An explicit --rom-path
# from the user always wins.
HERE=$(dirname "$(readlink -f "$0")")
export LD_LIBRARY_PATH="$HERE/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

has_rom=0
for a in "$@"; do [ "$a" = "--rom-path" ] && has_rom=1; done
if [ "$has_rom" = 0 ]; then
    here=""
    [ -n "${APPIMAGE:-}" ] && here=$(dirname "$APPIMAGE")
    for d in "$here/roms" "$here/roms/lastblad" \
             "$HOME/Emulation/roms/arcade" "$HOME/Emulation/roms/neogeo" \
             "$HOME/Emulation/roms/lastblad" "$HOME/roms/lastblad" "$HOME/roms"; do
        if [ -d "$d" ]; then set -- --rom-path "$d" "$@"; has_rom=1; break; fi
    done
fi

# Steam Deck / Gaming Mode expects a fullscreen game. Respect an explicit
# --headless, --fullscreen or --scale.
add_fs=1
for a in "$@"; do
    case "$a" in --headless|--fullscreen|--scale) add_fs=0;; esac
done
[ "$add_fs" = 1 ] && set -- --fullscreen "$@"

exec "$HERE/usr/bin/TheLastBlade" "$@"
EOF
chmod +x "$APPDIR/AppRun"

echo "== appimagetool =="
mkdir -p "$ROOT/dist/steamdeck"
TOOL="${APPIMAGETOOL:-$BUILD/appimagetool.AppImage}"
if [ ! -x "$TOOL" ]; then
    wget -q -O "$TOOL" \
      https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
    chmod +x "$TOOL"
fi
ARCH=x86_64 "$TOOL" --appimage-extract-and-run --no-appstream "$APPDIR" "$OUT"
chmod +x "$OUT"
cp "$ROOT/packaging/appimage/README.txt" "$ROOT/dist/steamdeck/README.txt"
cp "$ROOT/THIRD_PARTY_NOTICES.md" "$ROOT/dist/steamdeck/THIRD_PARTY_NOTICES.md"
cp "$ROOT/docs/compatibility.md" "$ROOT/dist/steamdeck/COMPATIBILITY.md"
cp "$ROOT/docs/testing.md" "$ROOT/dist/steamdeck/TESTING.md"
cp "$ROOT/docs/rom-layout.md" "$ROOT/dist/steamdeck/ROM-LAYOUT.md"
echo "wrote $OUT"
