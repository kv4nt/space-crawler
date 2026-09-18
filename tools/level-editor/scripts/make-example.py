#!/usr/bin/env python3
"""Эталонный pixel-art для редактора уровней: flat colors + прозрачный фон."""
from PIL import Image

W, H = 32, 32
# (x, y, w, h, rgba)
T = (0, 0, 0, 0)
BLK = (18, 20, 28, 255)
WHT = (235, 238, 245, 255)
SLV = (180, 186, 198, 255)
GLD = (218, 170, 40, 255)
BLU = (55, 120, 210, 255)
ORG = (230, 120, 45, 255)
BRN = (110, 72, 42, 255)

img = Image.new("RGBA", (W, H), T)
px = img.load()

def fill(x, y, w, h, c):
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            if 0 <= xx < W and 0 <= yy < H:
                px[xx, yy] = c

def dot(x, y, c):
    if 0 <= x < W and 0 <= y < H:
        px[x, y] = c

# Контур + шлем
fill(10, 4, 12, 10, BLK)
fill(11, 5, 10, 8, SLV)
fill(12, 6, 8, 6, BLU)
fill(13, 7, 6, 4, BLK)

# Тело
fill(9, 14, 14, 12, BLK)
fill(10, 15, 12, 10, WHT)
fill(11, 16, 4, 3, ORG)
fill(17, 16, 4, 3, ORG)

# Руки + кирка
fill(6, 16, 4, 8, BLK)
fill(7, 17, 2, 6, WHT)
fill(22, 16, 4, 8, BLK)
fill(23, 17, 2, 6, WHT)
fill(24, 14, 2, 6, BRN)
fill(25, 12, 2, 4, SLV)

# Ноги
fill(10, 26, 5, 5, BLK)
fill(11, 27, 3, 3, ORG)
fill(17, 26, 5, 5, BLK)
fill(18, 27, 3, 3, ORG)

# Рюкзак
fill(8, 15, 2, 8, BLK)
fill(8, 16, 1, 6, SLV)

out = "/var/www/space-crawler/tools/level-editor/examples/example_astronaut_pixel.png"
img.save(out)
print(out)
