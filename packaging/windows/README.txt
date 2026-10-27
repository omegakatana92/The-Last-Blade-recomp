The Last Blade
Native static recompilation for Windows x64
===========================================

This folder contains "The Last Blade.exe", SDL2.dll, the Visual C++ runtime
DLLs and the licences. It does NOT contain game ROMs or the Neo Geo BIOS.

Quick start
-----------
1. Put your legally obtained ROM files in the "roms" folder next to the
   executable (or anywhere else):

     lastblad.zip -> 234-p1.p1 234-p2.sp2 234-s1.s1 234-m1.m1
                     234-v1.v1 234-v2.v2 234-v3.v3 234-v4.v4
                     234-c1.c1 ... 234-c6.c6
     neogeo.zip   -> sp-s2.sp1 sfix.sfix sm1.sm1 000-lo.lo

   Unzip them: all 18 files must be directly in the same folder. See
   ROM-LAYOUT.md for sizes, CRC32 and SHA1.

2. Run "The Last Blade.exe". It looks for .\roms by default. For another
   folder:

     "The Last Blade.exe" --rom-path "D:\NeoGeo\roms"

Controls
--------
  Arrows / left stick     move
  Z X C V / pad A B X Y   Neo Geo A B C D
  5 / Back                insert coin
  1 / Start               start
  3 / left shoulder       select
  9                       service
  F2                      test switch
  F11 or Alt+Enter        toggle fullscreen
  Esc                     quit

On MVS you must insert a coin before Start does anything. Up to two SDL
GameControllers work; the first is player 1, the second player 2.

Command line
------------
Run "The Last Blade.exe --help" for the full list. Useful options:
  --rom-path DIR        game ROM files (default: roms)
  --bios-path DIR       BIOS files (default: the ROM path)
  --bios FILE           system ROM (default: sp-s2.sp1)
  --fullscreen          start fullscreen (F11 toggles)
  --rtc YYYY-MM-DDTHH:MM:SS  fixed calendar (reproducible runs)
  --scale N             window scale (default 3)
  --headless            no window
  --interp              interpreter only
  --verify              compare every recompiled block with Musashi

Notes
-----
* The MVS BIOS is the real sp-s2.sp1 system ROM; there is no BIOS HLE.
* The 68000 program is statically recompiled at build time from your own
  dump and runs natively; there is no 68000 interpreter in the hot path.
  Runtime-computed targets without a native entry use the bundled Musashi
  fallback. On the tested 24,000-frame session native coverage measured
  100.000% with 0 interpreted instructions.
* Original project code is PolyForm Noncommercial 1.0.0 - free for
  noncommercial use, commercial use needs a separate licence. Upstream
  NeoGeoRecomp (MIT), Musashi (MIT), z80 (MIT), ymfm (BSD-3) and SDL2
  (zlib) keep their own licences; see LICENSES\.
* The Last Blade, Neo Geo, MVS and AES are trademarks of SNK Corporation.
  This project is not affiliated with or endorsed by SNK.
