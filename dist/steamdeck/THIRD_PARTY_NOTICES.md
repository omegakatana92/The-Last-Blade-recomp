# Third-party notices

This project is an independent port built on **NeoGeoRecomp** and other
open-source components. The PolyForm Noncommercial 1.0.0 licence in
`LICENSE` applies only to the original project code authored for this port
(ROM layout, player glue, build/packaging scripts, docs and icon). It does
not relicense any third-party component.

The vendored toolkit in `neogeorecomp/` is NeoGeoRecomp v0.2.0, MIT,
copyright 2026 sp00nznet and contributors, plus the generic local fixes
listed in `docs/toolkit-patches.md`. Its original `LICENSE`, `NOTICE` and
`LICENSES/` directory are preserved in place.

| Component | Where | Licence | Copyright / notice |
|---|---|---|---|
| NeoGeoRecomp | `neogeorecomp/` | MIT | Copyright 2026 sp00nznet and contributors. See `neogeorecomp/LICENSE`, `neogeorecomp/NOTICE`. |
| Musashi 68000 | `neogeorecomp/ext/musashi` | MIT | Copyright Karl Stenerud. See `neogeorecomp/LICENSES/Musashi.txt`. |
| superzazu/z80 | `neogeorecomp/ext/z80` | MIT | Copyright Nicolas Allemand. See `neogeorecomp/LICENSES/z80.txt`. |
| ymfm (YM2610) | `neogeorecomp/ext/ymfm` | BSD-3-Clause | Copyright Aaron Giles. See `neogeorecomp/LICENSES/ymfm.txt`. |
| SDL2 | `deps/sdl2` (Windows), system SDL2 (Linux) | zlib | Copyright 1997-2025 Sam Lantinga. See `packaging/SDL2.txt`. |

## Local changes to the toolkit

Three generic runtime/window patches from the reference port plus one new
reproducibility patch are applied to the vendored NeoGeoRecomp copy. They
are recorded as unified diffs in `patches/` and explained in
`docs/toolkit-patches.md`:

1. **Generic runtime and fullscreen** - watchdog reset handling, correct
   interpretation when a non-zero P-ROM bank is selected, odd-PC dispatch,
   a measured instruction-coverage line, sprite bounds for C-ROM sets that
   are not a power of two, windowed/fullscreen presentation with uniform
   scaling and pillarboxing, and window error reporting.
2. **Gamepad test portability** - the toolkit's virtual-gamepad test builds
   on SDL older than 2.26 and reports itself skipped.
3. **Window error reporting** - SDL window/renderer/texture failures are
   reported and cleaned up instead of crashing.
4. **Reproducible calendar** - an optional `--rtc` pins the uPD4990A time so
   runs that seed from the clock are reproducible. The default remains the
   host clock.

These are generic board/runtime fixes; no title-specific address, patch or
override was added.

## Game data

No game ROMs, Neo Geo BIOS files, or generated C derived from them are
included in this repository or in either distribution. You must supply a
legally obtained MAME `lastblad` set and `neogeo` system set. The Last Blade,
Neo Geo, MVS and AES are trademarks of SNK Corporation. This project is not
affiliated with or endorsed by SNK.

## Licence compatibility

The upstream toolkit is MIT and the bundled cores are MIT/BSD-3/zlib; those
are compatible with redistributing the combined binary under their own
terms. The PolyForm Noncommercial licence covers only the original code and
does not grant rights in SNK's game data. If you intend commercial
distribution, review every component's terms and obtain the necessary
rights; nothing here is legal advice.
