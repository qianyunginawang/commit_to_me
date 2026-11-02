@tool
class_name GlassPanel
extends PanelContainer
## A glass frame (the theme's PanelContainer style) with a glowing diamond on
## each corner and an optional tab on the top edge, like "LOCATION".

@export var tab_text := "":
	set(value):
		tab_text = value
		queue_redraw()
@export var corner_diamonds := true:
	set(value):
		corner_diamonds = value
		queue_redraw()

const DIAMOND := 5.0
const TAB_HEIGHT := 26.0
const TAB_SLANT := 14.0


func _draw() -> void:
	if corner_diamonds:
		for corner in [Vector2.ZERO, Vector2(size.x, 0), Vector2(0, size.y), size]:
			_diamond(corner)
	if tab_text != "":
		var font := UiStyle.label_font(4)
		var text := tab_text.to_upper()
		var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		var w := text_width + 60.0
		var left := (size.x - w) / 2.0
		var top := -TAB_HEIGHT / 2.0 - 2.0
		var shape := PackedVector2Array([
			Vector2(left + TAB_SLANT, top), Vector2(left + w - TAB_SLANT, top),
			Vector2(left + w, top + TAB_HEIGHT), Vector2(left, top + TAB_HEIGHT)])
		draw_polygon(shape, PackedColorArray([Color("#1f4f7a"), Color("#1f4f7a"), Color("#0e2440"), Color("#0e2440")]))
		draw_line(shape[0], shape[1], UiStyle.CYAN_PALE, 2.0)
		draw_string(font, Vector2(left + 30.0, top + 18.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UiStyle.TEXT)


func _diamond(center: Vector2) -> void:
	var points := PackedVector2Array([
		center + Vector2(0, -DIAMOND), center + Vector2(DIAMOND, 0),
		center + Vector2(0, DIAMOND), center + Vector2(-DIAMOND, 0)])
	draw_colored_polygon(points, Color(UiStyle.CYAN, 0.35))
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0, -DIAMOND + 1.5), center + Vector2(DIAMOND - 1.5, 0),
		center + Vector2(0, DIAMOND - 1.5), center + Vector2(-DIAMOND + 1.5, 0)]), UiStyle.CYAN_PALE)
