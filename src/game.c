/*
 * game.c - The Last Blade (MAME set `lastblad`, NGH-234) ROM layout,
 * shared by the player and the generator so both load the program
 * identically.
 *
 * The layout is MAME's ROM_START( lastblad ) in src/mame/snk/neogeo.cpp:
 *
 *   P ROM  $500000 = 1 MB fixed (234-p1.p1) + 4 MB banked (234-p2.sp2),
 *          both stored 16-bit word-swapped (ROM_LOAD16_WORD_SWAP).
 *   C ROMs 40 MB in three odd/even pairs (ROM_LOAD16_BYTE: c1 at even
 *          bytes, c2 at odd bytes, and so on): two 8 MB pairs and one
 *          4 MB pair.
 *   S ROM  234-s1.s1  (fixed layer)
 *   M1     234-m1.m1  (Z80 sound driver)
 *   V ROMs 16 MB ADPCM-A: v1..v4 (4 MB each), concatenated.
 *
 * The cart is a normal PROGBK1 MVS/AES board: four 1 MB banks behind the
 * $200000 window, selected through $2FFFF0-$2FFFFF. No encryption, no CMC
 * protection, no daughterboard. The fixed bank carries the "NEO-GEO"
 * signature at $100 after the word swap, which is what the loader assumes.
 */
#include "game.h"

const ng_game_t k_lastblade = {
    .name = "lastblad",
    .title = "The Last Blade",
    .prom_size = 0x500000,
    .prom = {
        /* file          file offset  dest       length    swap */
        {"234-p1.p1",  0x000000,    0x000000,  0x100000, 1},
        {"234-p2.sp2", 0x000000,    0x100000,  0x400000, 1},
    },
    .crom_size = 0x2800000,
    .crom_pairs = {
        {"234-c1.c1", "234-c2.c2"},
        {"234-c3.c3", "234-c4.c4"},
        {"234-c5.c5", "234-c6.c6"},
    },
    .srom = "234-s1.s1",
    .m1 = "234-m1.m1",
    .vrom = {"234-v1.v1", "234-v2.v2", "234-v3.v3", "234-v4.v4"},
};
