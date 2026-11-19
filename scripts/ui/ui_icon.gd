extends Control
## Milestone 25: one icon of scripts/ui/ui_icons.gd, drawn in the middle of this control (the heart,
## the gear, pause or play). While `flashing` (the danger warning, decision 82) the heart pulses.

const Ui := preload("res://scripts/ui/ui_style.gd")
const Icons := preload("res://scripts/ui/ui_icons.gd")

## Pulses per real second while flashing, and how much larger the heart gets.
const FLASH_RATE := 1.6
const FLASH_GROW := 0.14

@export var kind := "heart":
	set(value):
		if value != kind:
			kind = value
			queue_redraw()
@export var color := Color.WHITE:
	set(value):
		if value != color:
			color = value
			queue_redraw()
## The icon's size as a share of the smaller side of this control.
@export var box_share := 0.8
var flashing := false:
	set(value):
		if value != flashing:
			flashing = value
			_flash_time = 0.0
			set_process(flashing)
			queue_redraw()
var _flash_time := 0.0


func _ready() -> void:
	set_process(flashing)
	# Inside a flat button (the gear, pause): paler while pressed or disabled.
	var button := get_parent() as BaseButton
	if button:
		button.button_down.connect(queue_redraw)
		button.button_up.connect(queue_redraw)
		button.draw.connect(queue_redraw)


func _process(delta: float) -> void:
	_flash_time += delta
	queue_redraw()


## 0 to 1 and back, FLASH_RATE times per second.
func flash_amount() -> float:
	return 0.5 - 0.5 * cos(_flash_time * TAU * FLASH_RATE) if flashing else 0.0


func _draw() -> void:
	var box := minf(size.x, size.y) * box_share
	var shown := kind
	if flashing:
		box *= 1.0 + FLASH_GROW * flash_amount()
		if kind == "heart" and flash_amount() > 0.5:
			shown = "heart_flash"
	var tint := color
	var button := get_parent() as BaseButton
	if button and button.disabled:
		tint.a *= 0.35
	elif button and button.is_pressed():
		tint.a *= 0.6
		box *= 0.92
	Icons.draw(self, shown, size * 0.5, box, tint)
