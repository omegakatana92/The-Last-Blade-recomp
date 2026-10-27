#!/usr/bin/env python3
"""Validate The Last Blade (MAME set `lastblad`) ROM files.

Checks every file the runtime loads against MAME's neogeo.cpp: size, CRC32
and SHA1. The game set and the required `neogeo` system ROMs may live in one
directory or be passed as two.

Usage:
    python scripts/validate-roms.py ROM_DIR [BIOS_DIR]

Exit code 0 means every file matched; 1 means a problem was found.
No ROM data is read from or written anywhere except the paths given.
"""
import hashlib
import os
import sys
import zlib

# MAME src/mame/snk/neogeo.cpp, ROM_START( lastblad ) and the neogeo BIOS set.
GAME = {
    "234-p1.p1":  (0x100000, "e123a5a3", "a3ddabc00feeb54272b145246612ad4632b0e413"),
    "234-p2.sp2": (0x400000, "0fdc289e", "1ff31c0b0f4f9ddbedaf4bcf927faaae81892ec7"),
    "234-s1.s1":  (0x020000, "95561412", "995de272f572fd08d909d3d0af4251b9957b3640"),
    "234-m1.m1":  (0x020000, "087628ea", "48dcf739bb16699af4ab8ed632b7dcb25e470e06"),
    "234-v1.v1":  (0x400000, "ed66b76f", "8a05ff06d9b6f01c6c16b3026282eaabb0e25b44"),
    "234-v2.v2":  (0x400000, "a0e7f6e2", "753ff74fa9294f695aae511ae01ead119b114a57"),
    "234-v3.v3":  (0x400000, "a506e1e2", "b3e04ba1a5cb50b77c6fbe9fe353b9b64b6f3f74"),
    "234-v4.v4":  (0x400000, "0e34157f", "20a1f4833e5e29ba0073c1712d7a17ab7a2a035c"),
    "234-c1.c1":  (0x800000, "9f7e2bd3", "2828aca0c0f5802110f10453c1cf640f69736554"),
    "234-c2.c2":  (0x800000, "80623d3c", "ad460615115ec8fb25206f012da59ecfc8059b64"),
    "234-c3.c3":  (0x800000, "91ab1a30", "e3cf9133784bef2c8f1bfe45f277ccf82cc6f6a1"),
    "234-c4.c4":  (0x800000, "3d60b037", "78a50233bcd19e92c7b6f7ee1a53417d9db21f6a"),
    "234-c5.c5":  (0x400000, "1ba80cee", "0c59057183b5279b747e73213b4cd3c6d7ad9eb1"),
    "234-c6.c6":  (0x400000, "beafd091", "55df9cc128eb0f00856de3996c946e3efe8f09a5"),
}

BIOS = {
    "sp-s2.sp1": (0x020000, "9036d879", "4f5ed7105b7128794654ce82b51723e16e389543"),
    "sfix.sfix": (0x020000, "c2ea0cfd", "fd4a618cdcdbf849374f0a50dd8efe9dbab706c3"),
    "sm1.sm1":   (0x020000, "94416d67", "42f9d7ddd6c0931fd64226a60dc73602b2819dcf"),
    "000-lo.lo": (0x020000, "5a86cff2", "5992277debadeb64d1c1c64b0a92d9293eaf7e4a"),
}


def check(name, expected, search):
    size, crc, sha1 = expected
    for d in search:
        p = os.path.join(d, name)
        if os.path.isfile(p):
            break
    else:
        print("MISSING   %-12s (looked in %s)" % (name, ", ".join(search)))
        return False
    data = open(p, "rb").read()
    got_crc = "%08x" % (zlib.crc32(data) & 0xFFFFFFFF)
    got_sha1 = hashlib.sha1(data).hexdigest()
    ok = len(data) == size and got_crc == crc and got_sha1 == sha1
    if ok:
        print("OK        %-12s %9d bytes  crc32 %s" % (name, len(data), got_crc))
    else:
        print("MISMATCH  %-12s size %d (want %d) crc32 %s (want %s)"
              % (name, len(data), size, got_crc, crc))
    return ok


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    game_dir = sys.argv[1]
    bios_dir = sys.argv[2] if len(sys.argv) > 2 else game_dir
    ok = True
    print("== game set lastblad ==")
    for n, e in GAME.items():
        ok &= check(n, e, [game_dir])
    print("== system set neogeo ==")
    for n, e in BIOS.items():
        ok &= check(n, e, [bios_dir, game_dir])
    print("result:", "all files verified" if ok else "PROBLEMS FOUND")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
