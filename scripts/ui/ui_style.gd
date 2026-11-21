extends RefCounted
## Milestone 25: the design tokens of the interface (documentation/ui_specification_v1.md,
## section 14) and small drawing helpers shared by the scripts in scripts/ui/. Values read from the
## approved mockups (documentation/ui_mockups/). Only the look; no game rule and no game number.

const FONT_BOLD := preload("res://assets/fonts/nunito/nunito_bold.tres")
const FONT_HEAVY := preload("res://assets/fonts/nunito/nunito_extrabold.tres")

# --- Colours ---------------------------------------------------------------------------------

## Text on the sky (HUD, clock, labels) and the next level's see-through text.
const TEXT_PRIMARY := Color(1, 1, 1)
const TEXT_SECONDARY := Color(1, 1, 1, 0.55)
## Dark navy: the speech balloon's outline and text, and the text of the buttons.
const INK := Color("#1b2552")
## The HUD and the clock capsule: a white line and a white fill at 5%.
const HUD_OPACITY := 0.05
const HUD_FILL := Color(1, 1, 1, HUD_OPACITY)
const HUD_LINE := Color(1, 1, 1, 0.85)
const HUD_DIVIDER := Color(1, 1, 1, 0.55)
## The empty part of every bar: blue-grey, see-through.
const TRACK := Color(0.66, 0.73, 0.92, 0.42)
const HEALTH_COLOR := Color("#ff4b5c")
const HEALTH_COLOR_DARK := Color("#e8283c")
## The red part while the danger warning flashes (decision 82).
const HEALTH_FLASH := Color("#ffd0d4")
const XP_COLOR := Color("#2fc0f5")
const XP_COLOR_DARK := Color("#1d8fe8")
const EXERCISE_COLOR := Color("#93f7e0")
const SLEEP_COLOR := Color("#d9c6fd")
const EAT_COLOR := Color("#fea6b5")
const ENTERTAINMENT_COLOR := Color("#ffe385")
## Every other button: white, with navy text.
const NEUTRAL_COLOR := Color("#f4f6ff")
## Panels that open over the game.
const PANEL_COLOR := Color("#232a6e")
## Icons inside the buttons.
const ICON_INK := Color("#1b2552")
const APPLE_RED := Color("#ff3346")
const LEAF_GREEN := Color("#38c172")
const CONTROLLER_BROWN := Color("#7b4a1e")
const SUN_COLOR := Color("#fff2b0")
const MOON_COLOR := Color("#fff6da")
const STAR_COLOR := Color(1, 1, 1)
const SHADOW_COLOR := Color(0.05, 0.07, 0.25, 0.28)
## How much the screen is darkened while a panel covers it.
const DIM_COLOR := Color(0.04, 0.05, 0.16, 0.6)

## Milestone 40 (documentation/ui_v2/values.md, "new"): the activity dock.
const STOP_COLOR := Color("#fd95b4")
const STOP_BASE := Color("#e0668e")
const MINIGAME_UP_COLOR := Color("#8afade")
const MINIGAME_UP_BASE := Color("#3db38b")
const MINIGAME_DOWN_COLOR := Color("#6c78c2")
const MINIGAME_DOWN_BASE := Color("#4c56a0")
const SLEEP_BASE := Color("#a98ce8")
## The green zone of every timing bar.
const ZONE_COLOR := Color("#6bf0b0")
## Key chips: INK at 35%.
const CHIP_COLOR := Color(0.105882, 0.145098, 0.321569, 0.35)
## Change 4: the cardio panel's bars and its see-through panel (PANEL_COLOR at 92%).
const STEPS_FILL := Color("#6df9cf")
const BREATH_FILL := Color("#29d3fd")
const PANEL_92 := Color(0.137255, 0.164706, 0.431373, 0.92)
## Change 9: the menus' tiles and the "chosen" badge.
const TILE_COLOR := Color("#eef1fb")
const BADGE_COLOR := Color("#22b573")
## Change 10: the cards' subtitles.
const SUBTITLE_COLOR := Color("#477297")
## Change 6: the band behind the meal's dock: PANEL_COLOR at 85%.
const DOCK_BAND := Color(0.137255, 0.164706, 0.431373, 0.85)
## Change 5: football (values.md): Pass, Shoot, the field's stripes, keycaps' base, see-through white.
const PASS_COLOR := Color("#6cd6fd")
const PASS_BASE := Color("#2a9fd6")
const SHOOT_COLOR := Color("#fd98a8")
const SHOOT_BASE := Color("#d9566f")
const FIELD_STRIPE_A := Color("#2db576")
const FIELD_STRIPE_B := Color("#25a56a")
const TILE_BASE := Color("#9babde")
const WHITE_08 := Color(1, 1, 1, 0.08)
const WHITE_25 := Color(1, 1, 1, 0.25)
const WHITE_60 := Color(1, 1, 1, 0.6)
## Floor and plate shadows: INK at 30% (alpha given per element).
const SHADOW_INK := Color(0.105882, 0.145098, 0.321569, 0.3)
## Pressed and disabled buttons of the new look (changes.md, rule 3).
const DISABLED_ALPHA := 0.45

## Milestone 40: the main menu (the team's splash screen, 21 Nov 2026; colours read from its
## pixels). Each menu button: its face and its darker thickness.
const MENU_NEW_FACE := Color("#a9f0e0")
const MENU_NEW_BASE := Color("#3ad3b7")
const MENU_AVATARS_FACE := Color("#b3e0ff")
const MENU_AVATARS_BASE := Color("#4eacf4")
const MENU_BACKUP_FACE := Color("#dec0fc")
const MENU_BACKUP_BASE := Color("#a283fa")
const MENU_ABOUT_FACE := Color("#fbc1da")
const MENU_ABOUT_BASE := Color("#f986bf")
## Continue is not in the splash screen; it keeps the entertainment gold (Claude's choice).
const MENU_CONTINUE_FACE := Color("#ffe385")
const MENU_CONTINUE_BASE := Color("#e6b94a")
## The title's outline and shadow, and the chosen half of the language switch.
const MENU_TITLE_OUTLINE := Color("#20236c")
const MENU_TOGGLE_ON := Color("#d2e3fd")

# --- Sizes (pixels at the 720 x 1280 reference) ----------------------------------------------

const BORDER_THIN := 2.0
const BORDER_MEDIUM := 3.0
const CORNER_RADIUS := 26.0
const BUTTON_CORNER_RADIUS := 30.0
## The four buttons: how far the body goes down when pressed, and the thickness under it.
const BUTTON_PRESS_OFFSET := 7.0
const BUTTON_BASE_DEPTH := 8.0
## Real seconds the body takes to come back up.
const BUTTON_RETURN_SECONDS := 0.14
const ACTION_FONT_SIZE := 34
## The ground line is this far above the bottom of the stage (where the avatar's feet are).
const GROUND_FROM_BOTTOM := 60.0
## The top of the curved ground is this far above the feet, in the middle of the screen.
const GROUND_RISE := 34.0
## The ground is the top of a circle this large, so it bends down at the sides like a planet.
const GROUND_RADIUS := 1150.0
## Draw order of the background, which covers the whole screen (top_level): the sky first, then
## the sun or moon, then the ground; everything else (z 0) is drawn over them.
const Z_SKY := -3
const Z_SUN_MOON := -2
const Z_GROUND := -1


## The colour of one of the four buttons.
static func action_color(kind: String) -> Color:
	match kind:
		"exercise":
			return EXERCISE_COLOR
		"sleep":
			return SLEEP_COLOR
		"eat":
			return EAT_COLOR
		"entertainment", "jump":
			return ENTERTAINMENT_COLOR
	return NEUTRAL_COLOR


## Makes a screen's root control the game's column (decision 87): as wide as the project's base
## width, centred, as tall as the screen. Its background nodes cover the whole screen themselves.
static func make_column(control: Control) -> void:
	var half := float(ProjectSettings.get_setting("display/window/size/viewport_width")) * 0.5
	control.anchor_left = 0.5
	control.anchor_right = 0.5
	control.anchor_top = 0.0
	control.anchor_bottom = 1.0
	control.offset_left = -half
	control.offset_right = half
	control.offset_top = 0.0
	control.offset_bottom = 0.0
	control.grow_horizontal = Control.GROW_DIRECTION_BOTH


# --- Drawing helpers -------------------------------------------------------------------------

## The outline of a rounded rectangle, clockwise, with `segments` points per corner.
static func rounded_rect_points(rect: Rect2, radius: float, segments := 8) -> PackedVector2Array:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var points := PackedVector2Array()
	var corners := [
		[Vector2(rect.end.x - r, rect.position.y + r), -PI * 0.5],
		[Vector2(rect.end.x - r, rect.end.y - r), 0.0],
		[Vector2(rect.position.x + r, rect.end.y - r), PI * 0.5],
		[Vector2(rect.position.x + r, rect.position.y + r), PI],
	]
	for corner in corners:
		for i in segments + 1:
			var angle: float = corner[1] + PI * 0.5 * i / segments
			points.append(corner[0] + Vector2.from_angle(angle) * r)
	return points


## Points of a circle (or an ellipse when radii differ).
static func ellipse_points(centre: Vector2, radii: Vector2, segments := 40) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in segments:
		points.append(centre + Vector2.from_angle(TAU * i / segments) * radii)
	return points


## Fills a polygon with a vertical gradient: `top` at y = from_y, `bottom` at y = to_y.
static func fill_vertical_gradient(canvas: CanvasItem, points: PackedVector2Array, from_y: float, to_y: float,
		top: Color, bottom: Color) -> void:
	var colors := PackedColorArray()
	var span := maxf(to_y - from_y, 1.0)
	for point in points:
		colors.append(top.lerp(bottom, clampf((point.y - from_y) / span, 0.0, 1.0)))
	canvas.draw_polygon(points, colors)
	# Polygons have no antialiasing: a thin smooth line of the same colours softens the edge.
	var closed := points.duplicate()
	closed.append(points[0])
	var closed_colors := colors.duplicate()
	closed_colors.append(colors[0])
	canvas.draw_polyline_colors(closed, closed_colors, 1.2, true)


## A rounded rectangle with a vertical gradient.
static func draw_gradient_box(canvas: CanvasItem, rect: Rect2, radius: float, top: Color, bottom: Color) -> void:
	fill_vertical_gradient(canvas, rounded_rect_points(rect, radius), rect.position.y, rect.end.y, top, bottom)


## A closed outline along points.
static func draw_outline(canvas: CanvasItem, points: PackedVector2Array, color: Color, width: float) -> void:
	var closed := points.duplicate()
	closed.append(points[0])
	canvas.draw_polyline(closed, color, width, true)


## A soft round glow: `color` in the middle, fading to nothing at `radius`.
static func draw_glow(canvas: CanvasItem, centre: Vector2, radius: float, color: Color, segments := 36) -> void:
	var clear := Color(color, 0.0)
	for i in segments:
		var a := centre + Vector2.from_angle(TAU * i / segments) * radius
		var b := centre + Vector2.from_angle(TAU * (i + 1) / segments) * radius
		canvas.draw_primitive(PackedVector2Array([centre, a, b]), PackedColorArray([color, clear, clear]),
				PackedVector2Array())


## A line with round ends.
static func draw_round_line(canvas: CanvasItem, from: Vector2, to: Vector2, color: Color, width: float) -> void:
	canvas.draw_line(from, to, color, width, true)
	canvas.draw_circle(from, width * 0.5, color, true, -1.0, true)
	canvas.draw_circle(to, width * 0.5, color, true, -1.0, true)


## Text centred on `centre`, in `font` at `font_size`, made smaller when it is wider than max_width.
static func draw_centred_text(canvas: CanvasItem, font: Font, centre: Vector2, text: String, font_size: int,
		color: Color, max_width := -1.0) -> void:
	var fitted := fit_font_size(font, text, font_size, max_width)
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x
	var baseline := centre.y + (font.get_ascent(fitted) - font.get_descent(fitted)) * 0.5
	canvas.draw_string(font, Vector2(centre.x - width * 0.5, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted, color)


## The largest size up to font_size at which text fits in max_width (no limit when negative).
static func fit_font_size(font: Font, text: String, font_size: int, max_width: float) -> int:
	var fitted := font_size
	while max_width > 0.0 and fitted > 12 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x > max_width:
		fitted -= 1
	return fitted
