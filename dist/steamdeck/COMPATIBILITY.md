# Compatibility and verification report

Game: **The Last Blade** (SNK, 1997), MVS/AES, MAME set `lastblad`,
NGH-234. Configuration: MVS version, real `sp-s2.sp1` BIOS.

Toolkit: **NeoGeoRecomp v0.2.0**, commit
`af96b2b4b39b42b392b17bcaa6a74a5f27088202`, plus the generic fixes in
`docs/toolkit-patches.md` (`patches/0001-...` through `patches/0004-...`).

Everything below was run in this workspace. Anything not run is marked
**untested**, not assumed. All measurements use
`--rtc 1997-12-19T12:00:00`, so they are reproducible.

## Hardware profile

| Area | Result |
|---|---|
| 68000 program | 5 MB P ROM: 1 MB fixed + four 1 MB banks |
| Encryption / protection | none (normal PROGBK1 MVS/AES cart) |
| C ROMs | 40 MB, three odd/even pairs (8+8+4 MB), no CMC decryption |
| S ROM | 128 KB fixed layer |
| M ROM | 128 KB Z80 driver |
| V ROMs | 16 MB ADPCM-A |
| BIOS | real `sp-s2.sp1` (MVS Asia/Europe v2), no BIOS HLE |
| Banking | standard `$2FFFF0-$2FFFFF` 1 MB window; recompiler covers bank 0 |

## ROM validation - passed

All 14 game files and the 4 required system-ROM files match MAME
`ROM_START( lastblad )` by size, CRC32 and SHA1
(`python scripts/validate-roms.py roms`). Table in `docs/rom-layout.md`.

## Boot and hardware

| Test | Environment / run | Result |
|---|---|---|
| Interpreter boot, 3,600 frames | Windows x64, headless | **Passed**; BIOS self-test, eyecatcher, intro text |
| Native boot, 3,600 frames | Windows x64, headless | **Passed**; 59,459,566 instructions, 100.000% native, 0 uncovered |
| Native frames vs interpreter | frames 1200, 2400, 3000, 3200, 3400 | **Byte-identical** PNGs (SHA-256 match) |
| Native vs interpreter at match creation | frame 3599 | **Differs**: the CPU opponent is chosen from a timing-sensitive value; see limitations |
| Windows vs Linux frames | frames 4000, 12000, 23999, separate builds | **Byte-identical** PNGs (SHA-256 match) |
| Windowed launch | Windows x64, SDL2 2.32 | **Passed**, exit 0, 180 frames |
| Fullscreen launch | Windows x64, `--fullscreen` | **Passed**, exit 0, 180 frames |
| Windowed/fullscreen launch | Linux AppImage under Xvfb 1280x800 + openbox | **Passed**, exit 0 |
| Aspect at 1280x800, fullscreen | X11 screen capture | content **1143x800** at x=68, aspect **1.4287** (target 320/224 = 1.4286); black pillarboxes, not stretched |
| Audio | 7,000-frame `--wav`, native | **118.26 s**, 55,555 Hz stereo, peak 19,440 (-5.2 dBFS); gameplay segment RMS 1,951 |

## Recompilation and correctness

| Metric | Result |
|---|---|
| Static discovery | **24,967** dispatch entries, 14,179 routines, 1,358,949 instructions emitted |
| Pointer scan | 13,166 seeds |
| Profile pass (6,000 + 24,000 frames) | **0 new entry points**; static discovery already covered the sessions |
| `--verify`, 24,000 frames, Windows final build | **30,581,852 blocks, 0 mismatches** |
| `--verify`, 24,000 frames, Linux final build | **30,581,852 blocks, 0 mismatches** |
| `--verify`, 24,000 frames, AppImage final build | **30,581,852 blocks, 0 mismatches** |
| Native instructions, 24,000 frames (all three builds) | **367,339,903** |
| Interpreted instructions | **0** |
| Uncovered entry points | **0** |
| Native coverage | **100.000%** of the executed instructions in this session |

The 100% figure is measured over the scripted session (boot, intro, HOW TO
PLAY, ability/character select, repeated matches, title/attract). It is not a
proof that every reachable path in a 5 MB program is native; banked code in
banks 1-3 would interpret by design, and no measured execution reached them.

### Toolkit regression

The vendored, patched toolkit was built with `NEOGEORECOMP_BUILD_TESTS=ON`:

| Host | `ctest` | Conformance |
|---|---|---|
| Windows (clang-cl, SDL 2.32.10) | 2/2 passed | **59/60** (reference interpreter 59/60) |
| Linux (Ubuntu 22.04, gcc 11.4, SDL 2.0.20) | 2/2 passed (gamepad self-skips below SDL 2.26) | **59/60** (reference interpreter 59/60) |

The one conformance failure is Musashi's `move` test program, which uses a
68020 addressing mode that the reference 68000 interpreter fails too.

`ng_gamepad_test` (Windows, SDL 2.32 virtual pads) passes: D-pad, left stick,
A/B/X/Y -> A/B/C/D, Start, Back -> coin, two pads, and unplugging all map as
documented. No physical controller was tested.

## Gameplay

| Item | Result |
|---|---|
| BIOS warning / eyecatcher | Yes |
| Intro / story screens | Yes |
| Attract / title screen | Yes |
| HOW TO PLAY pages | Yes (two pages observed) |
| Coin insertion | Yes (credit counter increments) |
| Start | Yes |
| Ability select (POWER / SPEED) | Yes |
| Character select | Yes (Kaede, Akari, Amano, Juzo observed) |
| Match: movement, A/B/C/D, hits, health bars, round timer | Yes |
| Multiple stages and opponents | Yes (observed across six matches) |
| Match end, return to title/attract | Yes |
| Two-player versus | **Untested** |
| Test / service menu | **Untested** |
| Memory card | Not implemented by the toolkit |
| Audio device playback | **Untested** (WAV output verified) |
| Physical gamepad / Steam Input | **Untested** (mapping verified virtually) |

Screenshots collected during these runs are not shipped because they contain
SNK artwork.

## Performance

Measured on this workspace, not on a Deck:

| Run | Result |
|---|---|
| Windows headless, 6,000 frames | 14.61 s (about 410 fps; the 68000 model is not the bottleneck) |
| Linux headless, 6,000 frames | 25.66 s (about 234 fps) |
| AppImage peak RSS, 600 frames | 154,080 KB |
| Linux windowed under Xvfb, 600 frames | 13.5 s (about 44 fps) - Xvfb/software rendering is the bottleneck here, not the game; not representative of the Deck GPU |
| Frame pacing | `window_sdl.c` paces to the MVS rate, 59.1856 Hz |

The headless figures leave ample CPU headroom for 60 fps on Deck-class
hardware, but real frame pacing and GPU behaviour were **not measured on a
Steam Deck**.

## Windows deliverable

| Item | Result |
|---|---|
| Toolchain | clang-cl 22.1.7 (MSVC ABI, Windows SDK), Ninja, CMake 4.3.3, Release x64 |
| Build | **built** |
| Package | `dist/windows/TheLastBlade-Windows-x64/` - exe + SDL2.dll + VC runtime + docs + licences |
| Headless smoke test | **Passed** (1,200 frames, 100.000% native) |
| Full soak, native | **Passed** (24,000 frames, 100.000% native) |
| `--verify` on the packaged exe | **Passed**, 30,581,852 blocks, 0 mismatches |
| ROMs in package | none |

## Steam Deck AppImage

| Item | Result |
|---|---|
| Build host | Windows 11 + WSL2, Ubuntu 22.04 x86_64, gcc 11.4, CMake 4.4.4, SDL2 2.0.20 |
| Output | `dist/steamdeck/The Last Blade-SteamDeck-x86_64.AppImage` |
| Headless 24,000-frame run | **Passed**, 100.000% native, 0 uncovered |
| `--verify` on the AppImage | **Passed**, 30,581,852 blocks, 0 mismatches |
| Windowed/fullscreen launch (1280x800 Xvfb) | **Passed**, exit 0 |
| Aspect at 1280x800 | 1143x800 content centred, aspect 1.4287, black pillarboxes |
| `ldd` | no missing libraries; glibc/libstdc++/libgcc not bundled; SDL2 bundled in `usr/lib` |
| ROMs inside AppImage | none |
| Steam Deck hardware | **Not available**: Gaming Mode, Steam Input, LCD/OLED panels **untested** |
| Built against | glibc 2.35 (Ubuntu 22.04); SteamOS 3 is newer, so the ABI floor is met |

## Known limitations

* Native coverage is 100% for the scripted session only; banks 1-3 interpret
  by design if execution ever reaches them.
* **Native vs interpreter scheduling.** The dispatcher takes interrupts at
  basic-block boundaries, while `--interp` steps one instruction at a time.
  Every native block passes `--verify`, but a free-running counter sampled at
  match creation can differ by a few cycles, so the CPU opponent chosen at
  frame ~3600 can differ between a native and an interpreter run. The two
  builds remain deterministic individually, and Windows and Linux native
  builds render byte-identical frames.
* No Steam Deck hardware, no physical gamepad, no keyboard-by-hand test, no
  two-player or service-menu test, no listening test on a real audio device.
* The toolkit's controller layout is fixed (no remapping).
* PolyForm Noncommercial 1.0.0 is the confirmed licence for original code
  and does not permit commercial distribution.
* No ROMs or BIOS files are bundled; a legally obtained `neogeo` set is
  required.
* The AES set (`lastbladh`) and bootleg/hack variants are not configured.

## Deliverables

| Path | State |
|---|---|
| `dist/windows/TheLastBlade-Windows-x64/` | built and tested |
| `dist/steamdeck/The Last Blade-SteamDeck-x86_64.AppImage` | built and tested under Xvfb; not run on Deck hardware |

Hashes and sizes are for the builds produced in this workspace. Rebuilds with
other compiler versions will differ; the source, the pinned toolkit and the
fixed input/calendar are what make the result reproducible.

## Test log index

| Artifact | Meaning |
|---|---|
| `build-windows/build.log` | clean Windows Release build |
| `build-windows/verify-24000-rtc.log` | 24,000-frame `--verify` on Windows |
| `build-windows/profile.log` | profile pass, 0 new entry points |
| `build-windows/toolkit-tests-ctest.log` | toolkit conformance/gamepad tests |
| `build-linux/...` | Linux build and AppImage runs |
| `dist/steamdeck/README.txt` | user instructions for the AppImage |

Logs are build artifacts and are not committed.
