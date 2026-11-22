"""Makes the avatar's activity pictures (running, squats, push-ups, sit-ups, eating) from the
team's activity sheets (user, 22 Nov 2026, the zip 261122a).

Each character has two sheets in assets/art/avatar/source/activity/ (made by the team with an
AI image tool, CC BY 4.0), with the 5 bodies in columns (obese, overweight, healthy, thin,
muscular, the order of data/avatar_art.json):
- <name>_activity.png: 8 rows, run_left, run_right, squat_up, squat_down, situp_up, situp_down,
  pushup_down, pushup_up;
- <name>_eat.png: 2 rows, eat_open, eat_closed (the bed under them is not used yet).

Each figure is saved on the canvas the game already uses for that picture (the size and the
feet line of the pictures before; scripts/ui/main.gd draws each canvas in a fixed rect) as
assets/art/avatar/<name>/<picture>_<body>.png. One scale per sheet keeps the team's sizes:
the healthy body standing (squat_up) is as tall as the medium body was (smaller if a figure
would not fit its canvas), and the healthy body
eating is as tall as the old eating picture. Each figure keeps its place in its cell of the
sheet (the middle of the cell on the middle of the canvas, the bottom of the row on the feet
line). The tool prints the open mouth of each eating body (dark red near the middle of the
head), for eat_mouth_y in data/avatar_art.json.

Run from the project folder (needs Pillow and NumPy):
    python3 tools/cut_activity_sheets.py
"""

from pathlib import Path

import numpy as np
from PIL import Image

SOURCE = Path("assets/art/avatar/source/activity")
OUT = Path("assets/art/avatar")
BODIES = ["obese", "overweight", "healthy", "thin", "muscular"]
HEALTHY = BODIES.index("healthy")
ACTIVITY_ROWS = ["run_left", "run_right", "squat_up", "squat_down", "situp_up", "situp_down",
		"pushup_down", "pushup_up"]
EAT_ROWS = ["eat_open", "eat_closed"]
# Each picture's canvas (width, height) and feet line (y), as before.
CANVAS = {
	"run": ((660, 900), 889),
	"squat": ((660, 900), 889),
	"situp": ((920, 720), 712),
	"pushup": ((1000, 680), 672),
	"eat": ((1120, 1120), None),
}
# Per character: the old medium body's height standing (squat_up), and the old eating
# picture's height and bottom, in canvas pixels.
SHEETS = {
	"child_female": {"stand_h": 655, "eat_h": 877, "eat_bottom": 1084},
	"child_male": {"stand_h": 833, "eat_h": 988, "eat_bottom": 1081},
	"teen_male": {"stand_h": 741, "eat_h": 1047, "eat_bottom": 1098},
	"teen_female": {"stand_h": 855, "eat_h": 977, "eat_bottom": 1085},
}
# Pixels at least this opaque belong to a figure.
SOLID = 40
# A figure that would touch its canvas's edge is made this much smaller than the edge allows.
FIT_MARGIN = 0.97


def runs(mask):
	"""The (first, last) indexes of each run of True values."""
	out = []
	start = None
	for i, v in enumerate(mask):
		if v and start is None:
			start = i
		elif not v and start is not None:
			out.append((start, i - 1))
			start = None
	if start is not None:
		out.append((start, len(mask) - 1))
	return out


def cells(sheet, rows_wanted):
	"""The sheet's rows (first rows_wanted of them) and its 5 columns, as (first, last)."""
	solid = np.array(sheet)[:, :, 3] >= SOLID
	rows = runs(solid.any(axis=1))[:rows_wanted]
	if len(rows) != rows_wanted:
		raise ValueError("expected %d rows, found %d" % (rows_wanted, len(rows)))
	top, bottom = rows[0][0], rows[-1][1]
	cols = runs(solid[top:bottom + 1].any(axis=0))
	if len(cols) != len(BODIES):
		raise ValueError("expected %d columns, found %d" % (len(BODIES), len(cols)))
	return rows, cols


def place(sheet, row, col, scale, canvas, feet):
	"""One figure on its canvas: the cell's middle on the canvas's middle, the row's bottom on
	the feet line. Only the figure's own pixels are placed (the cell's empty margins are not)."""
	(w, h) = canvas
	cell = sheet.crop((col[0], row[0], col[1] + 1, row[1] + 1))
	box = Image.fromarray(((np.array(cell)[:, :, 3] >= SOLID) * 255).astype(np.uint8)).getbbox()
	figure = cell.crop(box)
	size = (max(1, round(figure.width * scale)), max(1, round(figure.height * scale)))
	figure = figure.resize(size, Image.LANCZOS)
	out = Image.new("RGBA", canvas, (0, 0, 0, 0))
	x = round(w / 2 + (box[0] - cell.width / 2) * scale)
	y = round(feet - (cell.height - box[1]) * scale)
	if x < 0 or y < 0 or x + figure.width > w or y + figure.height > h:
		print("  warning: a figure is cut by its canvas (%d, %d, %d x %d)" % (x, y, figure.width, figure.height))
	out.alpha_composite(figure, (max(0, x), max(0, y)), (max(0, -x), max(0, -y)))
	return out


def mouth_y(image):
	"""The middle of the open mouth (dark red pixels near the middle of the head), as a share of
	the picture's height."""
	a = np.array(image).astype(int)
	solid = a[:, :, 3] >= SOLID
	ys = np.nonzero(solid.any(axis=1))[0]
	top, bottom = ys[0], ys[-1]
	red = (a[:, :, 0] > 110) & (a[:, :, 1] < 90) & (a[:, :, 2] < 90) & solid
	w = a.shape[1]
	red[:, : int(w * 0.42)] = False
	red[:, int(w * 0.58):] = False
	red[int(top + 0.45 * (bottom - top)):, :] = False
	found = np.nonzero(red)[0]
	return float(np.median(found)) / a.shape[0] if len(found) else -1.0


def largest_scale(sheet, row, col, canvas, feet):
	"""The largest scale at which the figure in a cell fits its canvas when placed by place()."""
	(w, h) = canvas
	cell = sheet.crop((col[0], row[0], col[1] + 1, row[1] + 1))
	x0, y0, x1, _ = Image.fromarray(((np.array(cell)[:, :, 3] >= SOLID) * 255).astype(np.uint8)).getbbox()
	limits = [feet / (cell.height - y0)]
	if x0 < cell.width / 2:
		limits.append((w / 2) / (cell.width / 2 - x0))
	if x1 > cell.width / 2:
		limits.append((w / 2) / (x1 - cell.width / 2))
	return min(limits)


def height(sheet, row, col):
	"""The height of the figure in a cell (sheet pixels)."""
	solid = np.array(sheet.crop((col[0], row[0], col[1] + 1, row[1] + 1)))[:, :, 3] >= SOLID
	ys = np.nonzero(solid.any(axis=1))[0]
	return ys[-1] - ys[0] + 1


def main():
	for name, info in SHEETS.items():
		print(name)
		folder = OUT / name
		sheet = Image.open(SOURCE / ("%s_activity.png" % name)).convert("RGBA")
		rows, cols = cells(sheet, len(ACTIVITY_ROWS))
		scale = info["stand_h"] / height(sheet, rows[ACTIVITY_ROWS.index("squat_up")], cols[HEALTHY])
		# Smaller when a figure would not fit its canvas (FIT_MARGIN keeps it off the edge).
		for r, picture in enumerate(ACTIVITY_ROWS):
			canvas, feet = CANVAS[picture.split("_")[0]]
			for c in range(len(BODIES)):
				scale = min(scale, largest_scale(sheet, rows[r], cols[c], canvas, feet) * FIT_MARGIN)
		print("  activity scale %.3f" % scale)
		for r, picture in enumerate(ACTIVITY_ROWS):
			canvas, feet = CANVAS[picture.split("_")[0]]
			for c, body in enumerate(BODIES):
				place(sheet, rows[r], cols[c], scale, canvas, feet).save(folder / ("%s_%s.png" % (picture, body)))

		sheet = Image.open(SOURCE / ("%s_eat.png" % name)).convert("RGBA")
		rows, cols = cells(sheet, len(EAT_ROWS))
		scale = info["eat_h"] / height(sheet, rows[EAT_ROWS.index("eat_closed")], cols[HEALTHY])
		print("  eating scale %.3f" % scale)
		canvas = CANVAS["eat"][0]
		pictures = {}
		for r, picture in enumerate(EAT_ROWS):
			for c, body in enumerate(BODIES):
				image = place(sheet, rows[r], cols[c], scale, canvas, info["eat_bottom"])
				image.save(folder / ("%s_%s.png" % (picture, body)))
				pictures[(picture, body)] = image
		for body in BODIES:
			print("  mouth of %s at %.3f of the height" % (body, mouth_y(pictures[("eat_open", body)])))

if __name__ == "__main__":
	main()
