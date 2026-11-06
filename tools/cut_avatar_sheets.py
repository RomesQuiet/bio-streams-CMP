"""Cuts the team's avatar sprite sheets into even grids for the game.

Each sheet in assets/art/avatar/source/ (made by the team with an AI image tool, CC BY 4.0)
has 5 columns (bodies: obese, overweight, healthy, thin, muscular) and 5 rows (faces: happy,
neutral, sad, tired, asleep), but the figures are not on an even grid. This script finds
each figure by its transparency, scales every sheet by one factor so its largest figure fits
a cell of CELL_W x CELL_H pixels, puts each figure's feet on the bottom of its cell and
centres its column, and writes assets/art/avatar/<name>.png (5 x 5 cells).

Run from the project folder (needs Pillow and NumPy):
    python3 tools/cut_avatar_sheets.py
"""

from pathlib import Path

import numpy as np
from PIL import Image

SOURCE = Path("assets/art/avatar/source")
OUT = Path("assets/art/avatar")
SHEETS = {
    "child_female": "criança do gènero feminino 10 anos.png",
    "child_male": "criança sexo masculino 10 anos.png",
    "teen_female": "rapariga do sexo feminino 14 anos.png",
    "teen_male": "criança sexo masculino 14 anos.png",
}
COLUMNS = 5
ROWS = 5
# The size of the avatar control in scenes/avatar/avatar.tscn.
CELL_W = 330
CELL_H = 450
MARGIN = 6
# Pixels at least this opaque belong to a figure.
SOLID = 40
# Columns of figures are at least this far apart.
GAP = 15
# Rows are split within this share of a fifth of the sheet around each fifth.
SEARCH = 0.25


def runs(indexes, gap=GAP):
    """Groups sorted indexes into (first, last) runs, split where the gap is larger than gap."""
    groups = []
    first = last = indexes[0]
    for i in indexes[1:]:
        if i - last > gap:
            groups.append((first, last))
            first = i
        last = i
    groups.append((first, last))
    return [g for g in groups if g[1] - g[0] > 20]


def bbox(mask):
    ys, xs = np.where(mask)
    return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1


def cut(name, filename):
    image = Image.open(SOURCE / filename).convert("RGBA")
    pixels = np.array(image)
    # Hidden colour under fully transparent pixels only makes the file larger.
    pixels[pixels[..., 3] == 0, :3] = 0
    image = Image.fromarray(pixels)
    solid = pixels[..., 3] >= SOLID
    columns = runs(np.where(solid.any(axis=0))[0])
    assert len(columns) == COLUMNS, f"{filename}: found {len(columns)} columns"
    boxes = {}
    centres = []
    for c, (x0, x1) in enumerate(columns):
        # The figures are not on an even grid and some touch the one above: split the column
        # at its emptiest line near each fifth of the sheet.
        profile = solid[:, x0 : x1 + 1].sum(axis=1)
        band = image.height / ROWS
        splits = [0]
        for k in range(1, ROWS):
            low, high = int(band * (k - SEARCH)), int(band * (k + SEARCH))
            window = profile[low:high]
            emptiest = np.where(window == window.min())[0]
            splits.append(low + int(emptiest[len(emptiest) // 2]))
        splits.append(image.height)
        rows = [(splits[k], splits[k + 1] - 1) for k in range(ROWS)]
        # The centre of the body, without the "zZ" of the asleep row.
        bx0, _, bx1, _ = bbox(solid[: rows[ROWS - 2][1] + 1, x0 : x1 + 1])
        centres.append(x0 + (bx0 + bx1) / 2.0)
        for r, (y0, y1) in enumerate(rows):
            fx0, fy0, fx1, fy1 = bbox(solid[y0 : y1 + 1, x0 : x1 + 1])
            boxes[(c, r)] = (x0 + fx0, y0 + fy0, x0 + fx1, y0 + fy1)
    widest = max(max(x1 - centres[c], centres[c] - x0) * 2.0 for (c, _), (x0, _, x1, _) in boxes.items())
    tallest = max(y1 - y0 for (x0, y0, x1, y1) in boxes.values())
    scale = min((CELL_W - 2 * MARGIN) / widest, (CELL_H - 2 * MARGIN) / tallest)
    atlas = Image.new("RGBA", (CELL_W * COLUMNS, CELL_H * ROWS), (0, 0, 0, 0))
    for (c, r), (x0, y0, x1, y1) in boxes.items():
        piece = image.crop((x0, y0, x1, y1))
        size = (max(1, round(piece.width * scale)), max(1, round(piece.height * scale)))
        piece = piece.resize(size, Image.LANCZOS)
        left = c * CELL_W + round(CELL_W / 2.0 + (x0 - centres[c]) * scale)
        top = r * CELL_H + CELL_H - MARGIN - piece.height
        atlas.alpha_composite(piece, (left, top))
    atlas.save(OUT / f"{name}.png", optimize=True)
    print(f"{name}.png: scale {scale:.3f}")


if __name__ == "__main__":
    for sheet_name, sheet_file in SHEETS.items():
        cut(sheet_name, sheet_file)
