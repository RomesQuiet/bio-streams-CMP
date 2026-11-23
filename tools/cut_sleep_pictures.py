#!/usr/bin/env python3
"""Cut the team's sleeping pictures (22 Nov 2026) for the game.

Sources: assets/art/avatar/source/sleep/<folder>_<day|night>.jpg (a bed with the avatar asleep in
it, a window with a blind and, by day, yellow light stripes, on a purple wall and floor).
For each picture:
  - the wall and the floor (the flat purple background, flood-filled from the edges) become
    transparent, so the game draws the room's own colours behind (scripts/ui/scenery.gd);
  - the glass (the grey and white checks between the slats: wide bands of light grey) becomes
    transparent, so the game draws the sky of the hour behind it;
  - the picture is scaled so its glass has the same width in every picture, and put onto a canvas of OUT_W x OUT_H with the floor line at FLOOR_SHARE of
    its height (the same in every picture, so the bed stands on the game's floor);
  - saved as assets/art/avatar/<folder>/sleep_<day|night>.png.
The glass rectangle of every picture (shares of the canvas) is written to data/sleep_glass.json
(x, y, width, height by folder and time; read by scripts/ui/scenery.gd).

Run: python3 tools/cut_sleep_pictures.py
"""
import json
import os
from collections import deque

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(ROOT, "assets/art/avatar/source/sleep")
ART = os.path.join(ROOT, "assets/art/avatar")
DATA = os.path.join(ROOT, "data/sleep_glass.json")
# Twice the size drawn in the game (560 x 617, scripts/ui/scenery.gd SLEEP_RECT).
OUT_W, OUT_H = 1120, 1234
FLOOR_SHARE = 0.77
BACKGROUND_TOLERANCE = 34
GLASS_MIN_WIDTH_SHARE = 0.05
GLASS_MIN_CHECKS = 0.25
# The glass is in the top half (a grey hoodie lower down is not glass).
GLASS_MAX_BOTTOM_SHARE = 0.5
# A slit between two slats is thin (about 22 of 1316 pixels).
GLASS_MAX_SLIT_SHARE = 0.03
GLASS_WIDTH_SHARE = 0.517
DEBUG = False


def close(a, b, tol):
    return abs(a[0] - b[0]) + abs(a[1] - b[1]) + abs(a[2] - b[2]) <= tol


def floor_line(im):
    """The first row (from the top, at the left edge) where the floor's colour starts."""
    wall = im.getpixel((8, 8))
    for y in range(8, im.height):
        if not close(im.getpixel((8, y)), wall, BACKGROUND_TOLERANCE):
            return y
    return int(im.height * FLOOR_SHARE)


def flood_background(im, alpha):
    w, h = im.size
    px = im.load()
    wall = px[8, 8]
    floor = px[8, h - 8]
    seen = bytearray(w * h)
    queue = deque()
    for x in range(w):
        queue.append((x, 0))
        queue.append((x, h - 1))
    for y in range(h):
        queue.append((0, y))
        queue.append((w - 1, y))
    while queue:
        x, y = queue.popleft()
        i = y * w + x
        if seen[i]:
            continue
        seen[i] = 1
        c = px[x, y]
        if not (close(c, wall, BACKGROUND_TOLERANCE) or close(c, floor, BACKGROUND_TOLERANCE)):
            continue
        alpha[x, y] = 0
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not seen[ny * w + nx]:
                queue.append((nx, ny))


def is_glass(c):
    return min(c) >= 170 and max(c) - min(c) <= 30


def clear_glass(im, alpha):
    """Wide bands of light grey (the checks) become transparent; small white shapes (the Zz, a
    hoodie) stay. A slit cut in two by the avatar's hair still counts. Returns the bounding box of the glass."""
    w, h = im.size
    px = im.load()
    seen = bytearray(w * h)
    box = None
    for sy in range(h):
        for sx in range(w):
            if seen[sy * w + sx] or not is_glass(px[sx, sy]):
                continue
            part = []
            queue = deque([(sx, sy)])
            seen[sy * w + sx] = 1
            while queue:
                x, y = queue.popleft()
                part.append((x, y))
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= nx < w and 0 <= ny < h and not seen[ny * w + nx] and is_glass(px[nx, ny]):
                        seen[ny * w + nx] = 1
                        queue.append((nx, ny))
            xs = [p[0] for p in part]
            # The checks are two greys; the Zz are one white with a thin grey edge.
            checks = sum(1 for p in part if min(px[p[0], p[1]]) <= 244) / len(part)
            if DEBUG and len(part) > 500:
                print("  part", min(xs), max(xs), min(p[1] for p in part), max(p[1] for p in part), round(checks, 2))
            if max(xs) - min(xs) < w * GLASS_MIN_WIDTH_SHARE or checks < GLASS_MIN_CHECKS or max(p[1] for p in part) > h * GLASS_MAX_BOTTOM_SHARE \
                    or max(p[1] for p in part) - min(p[1] for p in part) > h * GLASS_MAX_SLIT_SHARE:
                continue
            ys = [p[1] for p in part]
            for x, y in part:
                alpha[x, y] = 0
            part_box = (min(xs), min(ys), max(xs) + 1, max(ys) + 1)
            box = part_box if box is None else (min(box[0], part_box[0]), min(box[1], part_box[1]),
                    max(box[2], part_box[2]), max(box[3], part_box[3]))
    return box


def main():
    glass_rects = {}
    for name in sorted(os.listdir(SOURCE)):
        if not name.endswith(".jpg"):
            continue
        stem = name[:-4]
        folder, time = stem.rsplit("_", 1)
        im = Image.open(os.path.join(SOURCE, name)).convert("RGB")
        alpha = Image.new("L", im.size, 255)
        apx = alpha.load()
        floor_y = floor_line(im)
        flood_background(im, apx)
        glass = clear_glass(im, apx)
        rgba = im.copy()
        rgba.putalpha(alpha)
        # Scale: the glass is GLASS_WIDTH_SHARE of the canvas in every picture (the team's
        # pictures are not all drawn at the same size), then the floor line goes to FLOOR_SHARE.
        scale = OUT_W * GLASS_WIDTH_SHARE / (glass[2] - glass[0])
        size = (round(im.width * scale), round(im.height * scale))
        scaled = rgba.resize(size, Image.LANCZOS)
        left = (OUT_W - size[0]) // 2
        top = round(OUT_H * FLOOR_SHARE - floor_y * scale)
        canvas = Image.new("RGBA", (OUT_W, OUT_H), (0, 0, 0, 0))
        canvas.alpha_composite(scaled, (left, top)) if top >= 0 else canvas.alpha_composite(scaled.crop((0, -top, size[0], size[1])), (left, 0))
        out = os.path.join(ART, folder, "sleep_%s.png" % time)
        canvas.save(out, optimize=True)
        g = [glass[0] * scale + left, glass[1] * scale + top, glass[2] * scale + left, glass[3] * scale + top]
        glass_rects.setdefault(folder, {})[time] = [round(g[0] / OUT_W, 4), round(g[1] / OUT_H, 4),
                round((g[2] - g[0]) / OUT_W, 4), round((g[3] - g[1]) / OUT_H, 4)]
        print(out, "floor", floor_y, "glass", glass_rects[folder][time])
    data = {"_comment": "Written by tools/cut_sleep_pictures.py: the glass of each sleeping picture (x, y, width, height as shares of the picture), where scripts/ui/scenery.gd draws the sky of the hour.", "glass": glass_rects}
    with open(DATA, "w", encoding="utf-8") as f:
        json.dump(data, f, indent="\t")
        f.write("\n")


if __name__ == "__main__":
    main()
