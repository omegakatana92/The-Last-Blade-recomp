#!/usr/bin/env python3
"""Draw an original 256x256 icon for The Last Blade recompilation.

No SNK artwork is used: a dark gradient, a crimson moon, a diagonal blade
and "LB" block letters drawn from a tiny bitmap font.
"""
import os
import struct
import zlib

W = H = 256
px = bytearray(W * H * 3)


def put(x, y, r, g, b):
    if 0 <= x < W and 0 <= y < H:
        i = (y * W + x) * 3
        px[i] = r
        px[i + 1] = g
        px[i + 2] = b


# dark blue-black background with a subtle vertical gradient
for y in range(H):
    for x in range(W):
        put(x, y, 8 + y // 32, 10 + y // 36, 18 + y // 18)

# crimson moon
cx, cy, rad = 178, 78, 46
for y in range(cy - rad, cy + rad + 1):
    for x in range(cx - rad, cx + rad + 1):
        if (x - cx) ** 2 + (y - cy) ** 2 <= rad * rad:
            put(x, y, 176, 28, 34)

# diagonal blade: a bright edge over a dark steel body
for y in range(34, 222):
    x = 34 + (y - 34)
    for d in range(-5, 6):
        put(x + d, y, 26, 30, 38)
    put(x - 2, y, 236, 242, 246)
    put(x + 2, y, 120, 132, 146)

# guard
for y in range(196, 214):
    for x in range(18, 62):
        if abs((x + y) - 236) < 9:
            put(x, y, 196, 158, 70)

# panel behind the letters
for y in range(96, 184):
    for x in range(22, 150):
        put(x, y, 9, 10, 14)

FONT = {
    'L': ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
    'B': ["11110", "10001", "10001", "11110", "10001", "10001", "11110"],
}
text = "LB"
scale = 11
tw = (len(text) * 6 - 1) * scale
tx = 22 + (128 - tw) // 2
ty = 96 + (88 - 7 * scale) // 2
for ci, ch in enumerate(text):
    for gy, row in enumerate(FONT[ch]):
        for gx, bit in enumerate(row):
            if bit == '1':
                for yy in range(scale):
                    for xx in range(scale):
                        put(tx + (ci * 6 + gx) * scale + xx, ty + gy * scale + yy, 246, 240, 226)

raw = bytearray()
for y in range(H):
    raw.append(0)
    raw += px[y * W * 3:(y + 1) * W * 3]


def chunk(t, d):
    return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d) & 0xFFFFFFFF)


out = b'\x89PNG\r\n\x1a\n'
out += chunk(b'IHDR', struct.pack('>IIBBBBB', W, H, 8, 2, 0, 0, 0))
out += chunk(b'IDAT', zlib.compress(bytes(raw), 9))
out += chunk(b'IEND', b'')
path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "thelastblade.png")
with open(path, 'wb') as f:
    f.write(out)
print(path)
