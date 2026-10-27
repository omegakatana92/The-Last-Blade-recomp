# Test inputs

Both scripts use the runtime's frame-based input format:
`<frame>[-<end>] <button>[+<button>...]`. A single-frame event is held for six
frames, enough for the BIOS to see a coin or start press.

* `coin_start.txt` - coin, start, skip the intro/HOW TO PLAY, choose the
  default ability, and begin a match. Used for the short boot-to-gameplay
  check and for audio capture.
* `play_long.txt` - a 24,000-frame (~6:45) soak with six coin/start cycles,
  movement and A/B/C/D. Used by `--verify`, the profile target and the
  coverage measurements.

All recorded measurements also pass
`--rtc 1997-12-19T12:00:00`, which pins the emulated calendar so a run does
not depend on the host clock. See `docs/testing.md` for the full commands.

These files contain no ROM data; they are just input timing.
