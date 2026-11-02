class_name TitleBackdrop
extends Control
## The title screens' background: navy with a pink glow, a few bold slashes
## and the campus grid. Fill a screen with it, behind everything else.


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UiStyle.NAVY)
	for i in 8:
		draw_circle(Vector2(140, 400), 520 - i * 60, Color(1, 0.24, 0.5, 0.05))
		draw_circle(Vector2(1180, 460), 420 - i * 50, Color(0.18, 0.44, 0.85, 0.05))
	var grid := Color(UiStyle.CYAN, 0.05)
	for x in range(0, int(size.x), 32):
		draw_line(Vector2(x, 0), Vector2(x, size.y), grid, 1)
	for y in range(0, int(size.y), 32):
		draw_line(Vector2(0, y), Vector2(size.x, y), grid, 1)
	draw_line(Vector2(-40, 680), Vector2(1320, 160), Color(UiStyle.PINK, 0.6), 3)
	draw_line(Vector2(-40, 720), Vector2(1320, 210), Color(UiStyle.PINK, 0.45), 1.5)
	draw_line(Vector2(200, 760), Vector2(1400, 300), Color(UiStyle.CYAN, 0.35), 1.5)
	draw_colored_polygon(PackedVector2Array([Vector2(1140, 0), Vector2(1280, 0), Vector2(1280, 300)]), Color(UiStyle.PINK, 0.85))
	draw_arc(Vector2(1180, 470), 140, 0, TAU, 64, Color(UiStyle.CYAN, 0.25), 10, true)
