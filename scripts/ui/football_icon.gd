extends Control
## A small picture for the first-time explanation of football, in the colours of the field.

const FootballField := preload("res://scripts/ui/football_field.gd")

## "you", "goal", "free", "other" or "breath".
var kind := ""


func _draw() -> void:
	var centre := size * 0.5
	match kind:
		"you":
			FootballField.draw_egg(self, centre, 18.0, FootballField.YOU_COLOR)
		"goal":
			draw_rect(Rect2(centre - Vector2(24, 18), Vector2(48, 12)), FootballField.OTHER_COLOR)
			draw_arc(centre - Vector2(0, 6), 26.0, 0.0, PI, 24, FootballField.GOOD_COLOR, 3.0)
		"free":
			FootballField.draw_egg(self, centre, 14.0, FootballField.TEAM_COLOR)
			draw_arc(centre, 23.0, 0.0, TAU, 32, FootballField.GOOD_COLOR, 3.0)
		"other":
			FootballField.draw_egg(self, centre, 14.0, FootballField.OTHER_COLOR)
			draw_circle(centre + Vector2(0, 18), 6.0, FootballField.BALL_COLOR)
		"breath":
			draw_rect(Rect2(centre - Vector2(26, 8), Vector2(52, 16)), FootballField.OUTLINE_COLOR)
			draw_rect(Rect2(centre - Vector2(24, 6), Vector2(32, 12)), FootballField.GOOD_COLOR)
