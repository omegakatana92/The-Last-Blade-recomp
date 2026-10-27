# ROM layout

Game: **The Last Blade** (SNK, 1997), MAME set `lastblad`, NGH-234, MVS
version. The AES/home set `lastbladh` has different program ROMs and is not
supported by this configuration.

Reference: MAME `src/mame/snk/neogeo.cpp`, `ROM_START( lastblad )`, and the
`neogeo` system set. This port uses only the MVS `lastblad` layout.

## Required files

Unzip the MAME `lastblad` and `neogeo` sets into one folder (18 files),
because the runtime reads plain files, not archives.

### Game set (`lastblad.zip`)

| File | Size | CRC32 | SHA1 | Region |
|---|---:|---|---|---|
| `234-p1.p1` | 1,048,576 | `e123a5a3` | `a3ddabc00feeb54272b145246612ad4632b0e413` | P ROM fixed 1 MB |
| `234-p2.sp2` | 4,194,304 | `0fdc289e` | `1ff31c0b0f4f9ddbedaf4bcf927faaae81892ec7` | P ROM banked 4 MB |
| `234-s1.s1` | 131,072 | `95561412` | `995de272f572fd08d909d3d0af4251b9957b3640` | S ROM (fix layer) |
| `234-m1.m1` | 131,072 | `087628ea` | `48dcf739bb16699af4ab8ed632b7dcb25e470e06` | M1 (Z80 driver) |
| `234-v1.v1` | 4,194,304 | `ed66b76f` | `8a05ff06d9b6f01c6c16b3026282eaabb0e25b44` | V ROM (ADPCM-A) |
| `234-v2.v2` | 4,194,304 | `a0e7f6e2` | `753ff74fa9294f695aae511ae01ead119b114a57` | V ROM (ADPCM-A) |
| `234-v3.v3` | 4,194,304 | `a506e1e2` | `b3e04ba1a5cb50b77c6fbe9fe353b9b64b6f3f74` | V ROM (ADPCM-A) |
| `234-v4.v4` | 4,194,304 | `0e34157f` | `20a1f4833e5e29ba0073c1712d7a17ab7a2a035c` | V ROM (ADPCM-A) |
| `234-c1.c1` | 8,388,608 | `9f7e2bd3` | `2828aca0c0f5802110f10453c1cf640f69736554` | C ROM plane 0,1 |
| `234-c2.c2` | 8,388,608 | `80623d3c` | `ad460615115ec8fb25206f012da59ecfc8059b64` | C ROM plane 2,3 |
| `234-c3.c3` | 8,388,608 | `91ab1a30` | `e3cf9133784bef2c8f1bfe45f277ccf82cc6f6a1` | C ROM plane 0,1 |
| `234-c4.c4` | 8,388,608 | `3d60b037` | `78a50233bcd19e92c7b6f7ee1a53417d9db21f6a` | C ROM plane 2,3 |
| `234-c5.c5` | 4,194,304 | `1ba80cee` | `0c59057183b5279b747e73213b4cd3c6d7ad9eb1` | C ROM plane 0,1 |
| `234-c6.c6` | 4,194,304 | `beafd091` | `55df9cc128eb0f00856de3996c946e3efe8f09a5` | C ROM plane 2,3 |

### System set (`neogeo.zip`)

| File | Size | CRC32 | SHA1 | Role |
|---|---:|---|---|---|
| `sp-s2.sp1` | 131,072 | `9036d879` | `4f5ed7105b7128794654ce82b51723e16e389543` | MVS Asia/Europe BIOS v2 (default) |
| `sfix.sfix` | 131,072 | `c2ea0cfd` | `fd4a618cdcdbf849374f0a50dd8efe9dbab706c3` | BIOS fix layer |
| `sm1.sm1` | 131,072 | `94416d67` | `42f9d7ddd6c0931fd64226a60dc73602b2819dcf` | BIOS Z80 sound driver |
| `000-lo.lo` | 131,072 | `5a86cff2` | `5992277debadeb64d1c1c64b0a92d9293eaf7e4a` | Sprite-shrink table |

`sp-s2.sp1` is the default. Other MVS system ROMs can be selected with
`--bios FILE` if they are present; this port was validated with `sp-s2.sp1`.
AES system ROMs are not implemented by the toolkit.

## Memory layout

| Region | Size | Contents |
|---|---:|---|
| Fixed P ROM | 1 MB | `234-p1.p1` at `$000000` |
| Banked P ROM | 4 MB | `234-p2.sp2` at `$100000`, four 1 MB banks behind `$200000` |
| C ROM | 40 MB | three odd/even pairs, byte-interleaved by the loader |
| S ROM | 128 KB | fixed layer |
| M1 | 128 KB | Z80 sound driver |
| V ROM | 16 MB | ADPCM-A sample data |

The P ROMs are stored 16-bit word-swapped (`ROM_LOAD16_WORD_SWAP`); the game
descriptor sets `swap = 1`. The fixed bank carries the `NEO-GEO` signature at
`$100` after the swap, which is what the loader and recompiler check.

## Banking and protection

* The cart is a normal **PROGBK1** MVS/AES board: four 1 MB banks behind the
  `$200000` window, selected through `$2FFFF0-$2FFFFF`.
* **No P-ROM encryption, no NEO-CMC C-ROM decryption, no ALTERA/NEO-PVC
  protection and no daughterboard.**
* C ROMs are plain `ROM_LOAD16_BYTE` pairs. The 40 MB total is not a power of
  two, so the renderer's generic bounds fix (patch 0001) is required to avoid
  reading past the fitted C-ROM data for the highest tile codes.
* Static recompilation covers the fixed 1 MB and the first banked MB (bank 0).
  If the program ever executes code from a non-zero bank, the dispatcher runs
  it in the Musashi interpreter, because a native entry is tied to the bytes
  of one bank. No measured session executed from banks 1-3; coverage on the
  tested sessions was 100%.

## BIOS

Boot is through the real MVS system ROM; there is no BIOS HLE. The BIOS does
the RAM test, eyecatcher, coin/credit handling, calls the cartridge's `USER`
entry every frame and `PLAYER_START` when Start is pressed. The recompiler
translates the BIOS as a third region (`$C00000`), so it runs natively too.

No ROM or BIOS data is included with this project or in either distribution.
