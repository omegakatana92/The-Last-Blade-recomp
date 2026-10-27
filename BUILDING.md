# Rebuilding from source

This public repository intentionally **does not contain CMake files, build
trees, ROMs, BIOS files or generated C**. The release artifacts under `dist/`
are prebuilt and ready to run. This document explains how to reproduce them
from the upstream toolkit.

## 1. Get the toolkit

```bash
git clone --recurse-submodules https://github.com/sp00nznet/neogeorecomp
cd neogeorecomp
git checkout af96b2b4b39b42b392b17bcaa6a74a5f27088202   # v0.2.0
```

The commit is the one the released binaries were built against. The upstream
repository is MIT-licensed; its `LICENSE`, `NOTICE` and `LICENSES/` files stay
in place.

## 2. Apply the port's patches

From this repository:

```bash
for p in patches/0001-*.patch patches/0002-*.patch \
         patches/0003-*.patch patches/0004-*.patch; do
    git -C /path/to/neogeorecomp apply "$PWD/$p"
done
```

All four apply cleanly to v0.2.0. They add generic board/runtime fixes,
fullscreen and uniform scaling, SDL portability/error handling, and the
optional `--rtc` calendar pin. There are no title-specific addresses or
hacks.

## 3. Create the build project

The port's game glue is in `src/`:

* `src/game.c` / `src/game.h` — the verified `ng_game_t` ROM layout.
* `src/main.c` — calls `ng_main()` with the recompiled table.
* `src/recomp_main.c` — calls `ng_recomp_main()` for the generator.

Use the upstream game template (for example the `metalslug` repository
layout) and replace its game descriptor and glue with these files. The
expected build options are:

```text
LASTBLADE_ROM_DIR   directory with your lastblad and neogeo files
LASTBLADE_ENTRIES   optional runtime-discovered entry list
```

The recompiler writes 16 C files plus `recomp_table.c` into the build tree.
Those files are derived from the ROM and must not be committed.

## 4. Supply ROMs and build

Unzip your own legally obtained MAME `lastblad` and `neogeo` sets into a local
folder. Never commit them.

```bash
python scripts/validate-roms.py roms
```

Then configure with your own CMake project (not included here, by request):

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DLASTBLADE_ROM_DIR=./roms
cmake --build build --parallel
```

On Windows use clang-cl/MSVC or the equivalent; the released Windows build
used clang-cl 22.1.7, Visual Studio 2026, Ninja and CMake 4.3.3. The released
Linux build used gcc 11.4, CMake 4.4.4 and SDL2 2.0.20 on Ubuntu 22.04.

## 5. Verify

```bash
./build/TheLastBlade --headless --verify --rom-path ./roms \
  --rtc 1997-12-19T12:00:00 --frames 24000 --input tests/play_long.txt
```

Expected:

```text
[verify] 30581852 blocks checked, 0 mismatches
[exec] native blocks 30581852, interpreted instructions 0, 0 uncovered entry points
[coverage] native instructions 367339903, interpreted 0, 100.000% native
```

The Windows executable is the same program with the same measurements; the
AppImage wraps the Linux binary with SDL2 and a fullscreen launcher.
