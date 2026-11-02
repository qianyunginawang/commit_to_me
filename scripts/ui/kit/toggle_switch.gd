@tool
class_name ToggleSwitch
extends BaseButton
## An on/off switch: a cyan pill with a dark knob when on, a dim one when off.

const W := 46.0
const H := 24.0
const KNOB := 9.0


func _init() -> void:
	toggle_mode = true
	focus_mode = Control.FOCUS_ALL
	custom_minimum_size = Vector2(W, H)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	toggled.connect(func(_on): queue_redraw())
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)


func _draw() -> void:
	var top := (size.y - H) / 2.0
	var rect := Rect2(Vector2(size.x - W, top), Vector2(W, H))
	var on := button_pressed
	var track := UiStyle.CYAN if on else Color(UiStyle.CYAN_PALE, 0.32 if is_hovered() else 0.2)
	_pill(rect.grow(4), Color(UiStyle.CYAN, 0.25) if on else Color.TRANSPARENT)
	_pill(rect, track)
	if has_focus():
		_pill_outline(rect.grow(3), UiStyle.GOLD)
	var knob_x := rect.end.x - H / 2.0 if on else rect.position.x + H / 2.0
	draw_circle(Vector2(knob_x, rect.position.y + H / 2.0), KNOB, UiStyle.INK if on else UiStyle.TEXT_MUTED)


func _pill(rect: Rect2, color: Color) -> void:
	if color.a <= 0.0:
		return
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(int(rect.size.y / 2.0))
	box.anti_aliasing = true
	draw_style_box(box, rect)


func _pill_outline(rect: Rect2, color: Color) -> void:
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.border_color = color
	box.set_border_width_all(2)
	box.set_corner_radius_all(int(rect.size.y / 2.0))
	draw_style_box(box, rect)
