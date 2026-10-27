# The Last Blade â€” native recompilation

A native static recompilation of **The Last Blade** (SNK, 1997, MVS/AES,
MAME set `lastblad`, NGH-234), built on
[NeoGeoRecomp](https://github.com/sp00nznet/neogeorecomp) v0.2.0.

The 68000 program is translated ahead of time into C and runs on a model of
the MVS board. This is not an emulator wrapper. Musashi remains linked as the
correctness oracle and fallback; on the measured 24,000-frame session nothing
executed in it.

## Downloads

| Deliverable | Path | Size | SHA-256 |
|---|---|---:|---|
| Windows x64 | `dist/windows/TheLastBlade-Windows-x64/` | 49,196,544 B exe | `512dcb1ff4c5f3e0b848b978f450ca41a97d2b2ddf154e32724bb5d9fe246b6d` |
| Steam Deck / Linux x86_64 | `dist/steamdeck/The Last Blade-SteamDeck-x86_64.AppImage` | 16,476,664 B | `ba0aa1f21f3da3faa165ad3190b61bbe74043085a67068bb0ce485d09c9edc36` |

`dist/SHA256SUMS.txt` verifies every distributed file:

```bash
cd dist && sha256sum -c SHA256SUMS.txt
```

The Windows folder includes `SDL2.dll` and the VC runtime. The AppImage bundles
SDL2 and leaves glibc/libstdc++ to SteamOS.

## Run it

Windows:

```powershell
& ".\dist\windows\TheLastBlade-Windows-x64\The Last Blade.exe" --rom-path .\roms
```

Linux / Steam Deck:

```bash
chmod +x "The Last Blade-SteamDeck-x86_64.AppImage"
"./The Last Blade-SteamDeck-x86_64.AppImage" --rom-path ./roms
```

The AppImage looks for `roms/` beside itself and in the usual EmulationStation
folders, and starts fullscreen. At 1280x800 the 320x224 picture is scaled
uniformly and pillarboxed, never stretched.

## ROMs are required and are not included

No game ROMs, Neo Geo BIOS files, or generated C are in this repository or in
either release. Supply your own legally obtained dump, unzipped into one folder:

```text
lastblad.zip -> 234-p1.p1 234-p2.sp2 234-s1.s1 234-m1.m1
                234-v1.v1 234-v2.v2 234-v3.v3 234-v4.v4
                234-c1.c1 ... 234-c6.c6
neogeo.zip   -> sp-s2.sp1 sfix.sfix sm1.sm1 000-lo.lo
```

Validate them with:

```bash
python scripts/validate-roms.py roms
```

Expected: `result: all files verified`. The exact sizes, CRC32 and SHA1 are in
`docs/rom-layout.md`.

## Controls

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | arrows | D-pad / left stick |
| A B C D | Z X C V | A B X Y (Xbox positions) |
| Coin | 5 (6 = P2) | Back / View |
| Start | 1 (2 = P2) | Start |
| Select | 3 | left shoulder |
| Service / test | 9 / F2 | â€” |
| Fullscreen | F11 or Alt+Enter | â€” |
| Quit | Esc | â€” |

Two SDL GameControllers work: first connected is player 1, second player 2.
Steam Input's default gamepad template presents the Deck as an Xbox pad, which
matches the layout above. On MVS you must insert a coin before Start works.

## Verified results

| Item | Result |
|---|---|
| ROM validation | 14 game files + 4 BIOS files match MAME by size, CRC32, SHA1 |
| Recompiled entry points | **24,967** (14,179 routines; profile pass added 0) |
| `--verify`, 24,000 frames | **30,581,852 blocks, 0 mismatches** |
| Native coverage | **100.000%**, 0 interpreted instructions, 0 uncovered |
| Native instructions | **367,339,903** (identical on Windows, Linux and AppImage) |
| Windows vs Linux frames | byte-identical at frames 4000, 12000, 23999 |
| Fullscreen 1280x800 | content 1143x800, aspect 1.4287, pillarboxed |
| Toolkit conformance | 59/60 on Windows and Linux (reference interpreter 59/60) |
| Audio | Z80 + YM2610 WAV verified; 55,555 Hz stereo, peak -5.2 dBFS |
| Steam Deck hardware | **untested** â€” no Deck was available |

Full measurements: `docs/compatibility.md`.

## Repository contents

```text
src/            game.c (ROM layout), main.c, recomp_main.c, game.h
patches/        four generic NeoGeoRecomp v0.2.0 patches, unified diffs
docs/           ROM layout, compatibility, testing, toolkit patches
tests/          deterministic input scripts for boot and the 24,000-frame soak
scripts/        Windows/Linux build scripts and ROM validator
packaging/      Windows README, AppImage recipe, icon, .desktop, SDL2 licence
dist/           prebuilt Windows x64 and Steam Deck AppImage + checksums
LICENSES/       upstream MIT/BSD/zlib licence texts
```

### Deliberately not included

* **No CMake files.** Build files, CMake caches and build trees are omitted at
  the project owner's request. The release binaries are prebuilt.
* **No ROMs or BIOS files of any kind.**
* **No generated C.** The recompiler output is derived from the ROM and is
  produced only in a private build tree.
* **No vendored toolkit or SDL2 development package.** Both are third-party
  projects; see `LICENSES/` and the upstream links below.

## Rebuilding from source

The source here is the port's original glue plus the generic patches. To
rebuild, obtain the upstream toolkit and add your own build configuration:

1. Clone NeoGeoRecomp v0.2.0 at commit
   `af96b2b4b39b42b392b17bcaa6a74a5f27088202`.
2. Apply `patches/0001-...` through `patches/0004-...` in order. They apply
   cleanly to that commit.
3. Use the upstream game template with `src/game.c`, `src/main.c` and
   `src/recomp_main.c`; the expected options are `LASTBLADE_ROM_DIR` and
   `LASTBLADE_ENTRIES`.
4. Supply your own ROMs/BIOS locally. Generated C stays in the build tree.

The released artifacts were built with clang-cl 22.1.7 / Visual Studio 2026 /
Ninja / CMake 4.3.3 on Windows, and gcc 11.4 / CMake 4.4.4 / SDL2 2.0.20 on
Ubuntu 22.04.

## Licensing

* **Original project code** (ROM layout, player glue, scripts, packaging, docs,
  icon): **PolyForm Noncommercial 1.0.0**. See `LICENSE`. Commercial use needs
  a separate licence.
* **NeoGeoRecomp**: MIT, copyright 2026 sp00nznet and contributors.
* **Musashi**: MIT, Karl Stenerud. **z80**: MIT, Nicolas Allemand.
  **ymfm**: BSD-3-Clause, Aaron Giles. **SDL2**: zlib, Sam Lantinga.
* All notices are in `THIRD_PARTY_NOTICES.md` and `LICENSES/`.

The PolyForm licence covers only the original code. It grants no rights in
SNK's game data. The release binaries contain code recompiled from The Last
Blade and are provided for use by people who have the rights to the original
game; no ROM or BIOS data is included. Distribute or use them only where that
is lawful in your jurisdiction.

The Last Blade, Neo Geo, MVS and AES are trademarks of SNK Corporation. This
project is unaffiliated with and not endorsed by SNK.

## Known limitations

* Steam Deck hardware, Steam Input, and LCD/OLED panels are **untested**.
* No physical gamepad was tested; the SDL mapping is covered by the toolkit's
  virtual-pad test on Windows.
* Two-player versus, service menu and memory-card paths are untested.
* Audio was verified from a captured WAV, not listened to on a device.
* Native and interpreter runs can choose a different CPU opponent at match
  creation because they sample a free-running counter at different cycles;
  `--verify` still reports 0 mismatches block by block.
* Banks 1-3 of the cartridge would run in Musashi if reached; no measured
  session reached them.
* The AES set `lastbladh` and bootleg variants are not configured.
