extends Control
## The picture of the avatar's request in the speech balloon (Milestone 16), drawn in the style of
## Milestone 25 (scripts/ui/ui_icons.gd): a bed with Z, a burger, an apple, a knife and fork, a
## screen or a ball. Hidden when there is no request.

const Ui := preload("res://scripts/ui/ui_style.gd")
const Icons := preload("res://scripts/ui/ui_icons.gd")

## A request of scripts/health/requests.gd ("tired", "fast_food", ...) or "" for none.
var kind := "":
	set(value):
		kind = value
		visible = not kind.is_empty()
		queue_redraw()


func _draw() -> void:
	Icons.draw(self, kind, size * 0.5, minf(size.x, size.y) * 0.9, Ui.INK)
