# Building and testing

Reproduce every result in `docs/compatibility.md` from a clean folder.

> **Repository note:** this public repository intentionally omits CMake/build
> files and the vendored toolkit. The commands below describe the private build
> tree used to produce the prebuilt artifacts in `dist/`. See `README.md` and
> `BUILDING.md` for the public rebuild instructions.

All deterministic runs use `--rtc 1997-12-19T12:00:00`. The default calendar
is the host clock; The Last Blade seeds from it, so runs a second apart can
choose a different CPU opponent. `--rtc` pins it without changing gameplay.

## 0. ROMs

Unzip your legally obtained MAME `lastblad` and `neogeo` sets into `roms/`
(one flat folder, 18 files) and validate them:

```bash
python scripts/validate-roms.py roms
```

Expected last line: `result: all files verified`.

## 1. Windows x64

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build-windows.ps1 -RomDir .\roms -Test
```

What it does: configures `build-windows` with Ninja + clang-cl (MSVC ABI),
builds `The Last Blade.exe` in Release, runs a headless smoke test, stages
`dist\windows\TheLastBlade-Windows-x64\`. Add `-Msvc` for the Visual Studio
generator, `-SdlDir <...>` for an SDL2 outside `deps/sdl2`.

Build without a window (interpreter-only smoke):

```powershell
cmake -S . -B build-interp -G Ninja -DCMAKE_BUILD_TYPE=Release `
      -DCMAKE_C_COMPILER=clang-cl -DCMAKE_CXX_COMPILER=clang-cl -DLASTBLADE_ROM_DIR=
cmake --build build-interp
& ".\build-interp\The Last Blade.exe" --headless --rom-path .\roms --frames 1200
```

## 2. Linux / AppImage

```bash
./scripts/build-linux.sh ./roms                 # binary only -> build-linux/TheLastBlade
./packaging/appimage/build-appimage.sh ./roms   # -> dist/steamdeck/*.AppImage
```

The AppImage script builds Release, strips, collects the SDL2 it linked
against, writes `AppRun` (ROM discovery + fullscreen), the desktop entry and
icon, copies the licences, downloads `appimagetool` if needed and packs with
`--no-appstream`.

On a headless host, run the AppImage with `APPIMAGE_EXTRACT_AND_RUN=1` if FUSE
is unavailable.

## 3. Interpreter first

```bash
./build-linux/TheLastBlade --headless --interp --rom-path ./roms \
  --rtc 1997-12-19T12:00:00 --frames 3600 \
  --screenshot 600:600.png --screenshot 2400:2400.png --screenshot 3599:3599.png
```

This exercises the board model without any recompiled code. The BIOS
self-test, eyecatcher, intro text, HOW TO PLAY pages and select screens should
be correct here before looking at native execution.

## 4. Native build and frame comparison

Rebuild with `LASTBLADE_ROM_DIR` set (the scripts do this) and capture the
same frames, then compare hashes with the interpreter run:

```powershell
& ".\build-windows\The Last Blade.exe" --headless --rom-path .\roms `
  --rtc 1997-12-19T12:00:00 --frames 3600 `
  --screenshot 1200:n1200.png --screenshot 2400:n2400.png --screenshot 3400:n3400.png
Get-FileHash 1200.png,n1200.png,2400.png,n2400.png,3400.png,n3400.png -Algorithm SHA256
```

Frames 1200, 2400, 3000, 3200 and 3400 were byte-identical in the delivered
build. At ~frame 3599 the match starts: the game picks its CPU opponent from a
free-running value, and the native dispatcher and the one-instruction
interpreter can sample it a few cycles apart, so the opponents may differ. That
is a scheduling difference, not a translation mismatch; `--verify` checks every
block.

## 5. Correctness (`--verify`)

```powershell
& ".\build-windows\The Last Blade.exe" --headless --verify --rom-path .\roms `
  --rtc 1997-12-19T12:00:00 --frames 24000 --input tests\play_long.txt
```

Expected:

```
[verify] 30581852 blocks checked, 0 mismatches
[exec] native blocks 30581852, interpreted instructions 0, 0 uncovered entry points
[coverage] native instructions 367339903, interpreted 0, 100.000% native
```

The block count depends on the compiler's block boundaries; the instruction
count and the "0 mismatches" do not. The same figures were measured on the
Linux binary and inside the AppImage.

## 6. Profiling (close native coverage gaps)

```powershell
cmake --build build-windows --target profile
cmake --build build-windows
```

`profile` runs a 6,000-frame boot and the 24,000-frame soak with
`--dump-misses`, merging runtime-only entry points into `build-windows/entries.txt`.
This title needed **0** extra entries: static discovery already covered the
session, and the rebuilt table stayed at 24,967 entries.

## 7. Audio

```bash
./build-linux/TheLastBlade --headless --rom-path ./roms \
  --rtc 1997-12-19T12:00:00 --frames 7000 --input tests/coin_start.txt --wav play.wav
python3 - <<'PY'
import wave, struct, math
w = wave.open("play.wav"); n = w.getnframes(); r = w.getframerate()
a = struct.unpack("<%dh" % (n * w.getnchannels()), w.readframes(n))
print(r, "Hz", n / r, "s", "peak", max(abs(x) for x in a),
      "rms", round(math.sqrt(sum(x*x for x in a)/len(a)), 1))
PY
```

Delivered build: 55,555 Hz stereo, 118.26 s, peak 19,440 (-5.2 dBFS).

## 8. Windowed and fullscreen on Linux (headless host)

```bash
Xvfb :99 -screen 0 1280x800x24 -ac &
DISPLAY=:99 openbox &
DISPLAY=:99 APPIMAGE_EXTRACT_AND_RUN=1 \
  "./dist/steamdeck/The Last Blade-SteamDeck-x86_64.AppImage" \
  --rom-path ./roms --rtc 1997-12-19T12:00:00 --frames 1800 &
sleep 15
DISPLAY=:99 import -window root shot.png
```

Measure the non-black bounding box: at 1280x800 the game occupies 1143x800,
centred at x=68 (aspect 1.4287), with black pillarboxes. Without a window
manager SDL's fullscreen request can fail, which is why `openbox` is started
first.

## 9. Toolkit regression tests

```bash
cmake -S neogeorecomp -B /tmp/ng-tests -DCMAKE_BUILD_TYPE=Release \
      -DNEOGEORECOMP_BUILD_TESTS=ON
cmake --build /tmp/ng-tests --parallel 8
ctest --test-dir /tmp/ng-tests --output-on-failure
```

Expected: conformance 59/60 (reference interpreter 59/60), gamepad test passes
on SDL >= 2.26 and self-skips below it.

On Windows the same commands work with the VS/clang-cl environment used by
`scripts/build-windows.ps1`.

## 10. Steam Deck

Copy the AppImage and `roms/` to the Deck, add the AppImage as a non-Steam
game (Proton off), launch once in Desktop Mode, then play in Gaming Mode.
**This step was not performed in this workspace** - no Deck hardware was
available.

## Clean rebuild

```powershell
Remove-Item -Recurse build-windows,dist
```

```bash
rm -rf build-linux dist
```

Deleting the build tree also deletes `entries.txt`. This title's entry list
stays empty, so a clean build regenerates the same 24,967 entries.
