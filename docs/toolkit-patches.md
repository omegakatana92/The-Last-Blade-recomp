# Toolkit patches

The project targets **NeoGeoRecomp v0.2.0** (commit
`af96b2b4b39b42b392b17bcaa6a74a5f27088202`) with four local changes. Upstream
is MIT; these changes stay under the upstream licence. The upstream source is
not vendored in this repository. The unified diffs are in `patches/`; apply
them in order to a clean v0.2.0 checkout.

## 0001 - generic runtime and fullscreen

Board/runtime fixes found while bringing up the reference ports. None of them
is title-specific.

* **Watchdog.** Writes with A0 set in `$300000-$3BFFFF` stroke the MVS
  watchdog. If it is not stroked for 1,622,015 68000 clocks the board resets.
  Several carts clear backup RAM then idle until the watchdog restarts them;
  without this the first boot can hang. `ng_main()` restarts the CPU and
  board after an expiry while preserving work and backup RAM.
* **P-ROM bank dispatch.** A native entry belongs to the first banked
  megabyte. When another bank is selected, `lookup()` returns no native entry
  so the interpreter sees the right bytes; `note_miss()` does not record
  those addresses as recompiler seeds.
* **Odd PC.** An odd program counter is a 68000 address error, not an alias
  of the even instruction below it. `lookup()` and `note_miss()` ignore odd
  addresses so Musashi takes the exception.
* **Coverage line.** `--verify` and the new `[coverage]` line report native
  *instructions* as well as blocks, so a 100% claim is measured rather than
  inferred from "0 uncovered entries".
* **C-ROM bounds.** The sprite decoder rounds the tile count up to a power of
  two for the address mask. A 40 MB C-ROM set has 327,680 tiles, so the mask
  can produce a code past the decoded data; the renderer now skips such a
  code instead of reading out of bounds.
* **Presentation.** `--fullscreen` starts fullscreen; F11 / Alt+Enter toggles.
  The 320x224 picture is scaled uniformly, centred and pillarboxed (never
  stretched), nearest-neighbour. This is what the Steam Deck deliverable
  needs at 1280x800.
* **Timing line.** `NG_TIMING=1` prints the simulated 68000 clocks, useful
  when comparing runs.

## 0002 - gamepad test portability

The toolkit's `ng_gamepad_test` uses `SDL_VirtualJoystickDesc`, which only
exists from SDL 2.26. Ubuntu 22.04 ships SDL 2.0.20. The test now compiles on
older SDL and reports itself skipped instead of failing; on SDL >= 2.26 it
runs the full mapping test. No runtime behaviour changes.

## 0003 - window error reporting

`window_open()` checks `SDL_CreateWindow`, `SDL_CreateRenderer` and
`SDL_CreateTexture`, falls back to a software renderer when accelerated
creation fails, and cleans up instead of dereferencing NULL. This matters on
headless Linux and unusual drivers.

## 0004 - reproducible calendar

The uPD4990A calendar defaults to the host's local time, as the real chip
does. The BIOS and some games read it, and The Last Blade's path diverges by a
few instructions between runs a second apart (the game seeds from the clock).
A new generic option pins the calendar for reproducible tests:

```
--rtc 1997-12-19T12:00:00
```

With it, two headless runs produce identical instruction counts and identical
PNG hashes; without it the default remains the host clock. The calendar
register, weekday calculation and serial protocol are unchanged. The option
is documented in the vendored `docs/running.md`.
