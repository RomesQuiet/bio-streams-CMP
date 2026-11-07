"""Makes the avatar pictures for the game from the team's sprite sheets.

Each sheet in assets/art/avatar/source/ (made by the team with an AI image tool, CC BY 4.0)
has 5 columns (bodies: obese, overweight, healthy, thin, muscular) and 5 rows (faces: happy,
neutral, sad, tired, asleep), but the figures are not on an even grid.

1. cut() finds each figure by its transparency, scales every sheet by one factor so its
   largest figure fits a cell of CELL_W x CELL_H pixels (the avatar's size on screen), puts
   each figure's feet on the bottom of its cell and centres its column: an even 5 x 5 grid.
2. The team upscaled those grids about 3.6 times with an AI tool (7 Nov 2026), on a white
   background: assets/art/avatar/source/upscaled/<name>-upscaled-4x.png. from_upscaled()
   turns the white back into transparency: white connected to where the grid was transparent
   is background (so white inside a figure, such as eyes and socks, stays), and the grey edge
   of the black outline gets its transparency back.
3. The team's figures do not stand in the same place or have the same height, so the avatar
   moved and its head jumped up and down when its picture changed (user, 7 Nov 2026). Each
   figure is scaled to the median height of its sheet (from its feet to the top of its head)
   and moved so the middle of its feet is the middle of its picture, its feet on the ground.
4. Each figure is saved on its own at OUT_SCALE times the avatar's size (sharp on phones
   with dense screens, and below the 4096-pixel limit of many phones) as
   assets/art/avatar/<name>/<body>_<face>.png, with the names in data/avatar_art.json.

Run from the project folder (needs Pillow and NumPy):
    python3 tools/cut_avatar_sheets.py
"""

import json
from pathlib import Path

import numpy as np
from PIL import Image

Image.MAX_IMAGE_PIXELS = None

SOURCE = Path("assets/art/avatar/source")
UPSCALED = SOURCE / "upscaled"
OUT = Path("assets/art/avatar")
ART = Path("data/avatar_art.json")
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
# The pictures in the game are this many times the avatar's size on screen.
OUT_SCALE = 2
# In the upscaled sheets: a pixel at least this light (all of R, G, B) can be background,
# and the grid's transparency below this share marks the background for sure.
LIGHT = 215
CLEAR = 0.05
# The grey edge of the outline: this many pixels next to the background, at most this far
# from grey (largest minus smallest of R, G, B).
EDGE = 3
GREY = 40
# The feet: this share of the figure's height, from the bottom.
FEET = 0.1
# The head is the highest solid pixel this share of a cell's width either side of the feet
# (so the "zZ" of the asleep faces does not count).
HEAD_BAND = 0.12


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
    print(f"{name}: scale {scale:.3f}")
    return atlas


def dilate(mask):
    """The mask grown by one pixel in the four directions."""
    grown = mask.copy()
    grown[1:, :] |= mask[:-1, :]
    grown[:-1, :] |= mask[1:, :]
    grown[:, 1:] |= mask[:, :-1]
    grown[:, :-1] |= mask[:, 1:]
    return grown


def from_upscaled(atlas, path):
    """The upscaled grid with its white background made transparent again."""
    rgb = np.array(Image.open(path).convert("RGB"))
    height, width = rgb.shape[:2]
    guide = np.array(atlas.getchannel("A").resize((width, height), Image.BILINEAR)) / 255.0
    light = rgb.min(axis=2) >= LIGHT
    background = light & (guide < CLEAR)
    while True:
        grown = dilate(background) & light
        if (grown == background).all():
            break
        background = grown
    alpha = np.where(background, 0, 255).astype(np.uint8)
    near = background.copy()
    for _ in range(EDGE):
        near = dilate(near)
    spread = rgb.max(axis=2).astype(int) - rgb.min(axis=2)
    edge = near & ~background & (spread <= GREY)
    # A grey edge pixel is black outline over white: alpha = 1 - lightness, colour black.
    alpha[edge] = 255 - rgb.min(axis=2)[edge]
    rgb[edge] = 0
    rgb[background] = 0
    return Image.fromarray(np.dstack([rgb, alpha]), "RGBA")


def measure(alpha):
    """(middle of the feet, bottom, height from the feet to the top of the head) of one cell."""
    solid = alpha >= SOLID
    ys, xs = np.where(solid)
    bottom = ys.max()
    feet_x = xs[ys >= bottom - FEET * (bottom - ys.min())].mean()
    band = solid[:, max(0, round(feet_x - HEAD_BAND * alpha.shape[1])) : round(feet_x + HEAD_BAND * alpha.shape[1])]
    top = np.where(band.any(axis=1))[0].min()
    return feet_x, bottom, bottom - top


def save_cells(name, sheet):
    """Each figure of an even 5 x 5 sheet on its own, at OUT_SCALE times the avatar's size, all at
    the same height, with the middle of the feet in the middle of the picture."""
    art = json.loads(ART.read_text())
    out_w, out_h = CELL_W * OUT_SCALE, CELL_H * OUT_SCALE
    cell_w, cell_h = sheet.width / COLUMNS, sheet.height / ROWS
    alpha = np.array(sheet.getchannel("A"))
    # Premultiplied, so transparent pixels do not darken the edges when scaling.
    sheet = sheet.convert("RGBa")
    cells = {}
    for c in range(COLUMNS):
        for r in range(ROWS):
            box = (round(c * cell_w), round(r * cell_h), round((c + 1) * cell_w), round((r + 1) * cell_h))
            cells[(c, r)] = (box, measure(alpha[box[1] : box[3], box[0] : box[2]]))
    height = float(np.median([m[2] for _, m in cells.values()]))
    base = out_w / cell_w
    folder = OUT / name
    folder.mkdir(exist_ok=True)
    changes = []
    for (c, r), (box, (feet_x, bottom, figure_h)) in cells.items():
        scale = base * height / figure_h
        changes.append(abs(height / figure_h - 1.0))
        piece = sheet.crop(box)
        piece = piece.resize((round(piece.width * scale), round(piece.height * scale)), Image.LANCZOS)
        left = round(out_w / 2.0 - feet_x * scale)
        top = round(out_h - MARGIN * OUT_SCALE - bottom * scale)
        cell = Image.new("RGBa", (out_w, out_h), (0, 0, 0, 0))
        cell.paste(piece, (left, top))
        cell = cell.convert("RGBA")
        kept = (np.array(cell.getchannel("A")) >= SOLID).sum()
        assert kept >= (np.array(piece.convert("RGBA").getchannel("A")) >= SOLID).sum() * 0.999, f"{name} {c},{r}: a figure would leave its picture"
        cell.save(folder / f"{art['columns'][c]}_{art['rows'][r]}.png", optimize=True)
    print(f"{name}: {len(cells)} pictures, heights changed up to {max(changes) * 100:.0f}%")


if __name__ == "__main__":
    for sheet_name, sheet_file in SHEETS.items():
        grid = cut(sheet_name, sheet_file)
        upscaled = UPSCALED / f"{sheet_name}-upscaled-4x.png"
        save_cells(sheet_name, from_upscaled(grid, upscaled) if upscaled.exists() else grid)
