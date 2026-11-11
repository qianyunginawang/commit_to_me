class_name AffectionView
extends ColorRect
## The affection summary, as a pop-up over the map (the AFFECTION button
## next to CALENDAR). One row per love interest: portrait, name, title
## (Stranger, Classmate...), and an affection bar out of 100. Jay's row also
## shows his day/night balance. Close with the button or Esc.

signal closed

var _list: VBoxContainer


func _ready() -> void:
	name = "AffectionOverlay"
	color = Color(UiStyle.SHADOW, 0.6)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	refresh()


func refresh() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	for id in GameData.character_ids():
		_list.add_child(_row(id))


func close() -> void:
	closed.emit()
	if get_parent():
		get_parent().remove_child(self)
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _build() -> void:
	var card := GlassPanel.new()
	card.tab_text = "Affection"
	card.custom_minimum_size = Vector2(520, 0)
	add_child(card)
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	card.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 14)
	column.add_child(_list)
	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "CLOSE"
	close_button.theme_type_variation = &"BrightButton"
	close_button.custom_minimum_size = Vector2(0, 40)
	close_button.pressed.connect(close)
	column.add_child(close_button)


## One love interest: portrait, name and title, the bar, and Jay's balance.
func _row(id: String) -> Control:
	var look := Looks.speaker_look(id, GameState.slot)
	var row := HBoxContainer.new()
	row.name = id
	row.add_theme_constant_override("separation", 14)
	var thumb: Portrait = preload("res://scenes/portrait.tscn").instantiate()
	thumb.custom_minimum_size = Vector2(56, 64)
	row.add_child(thumb)
	thumb.show_look(look)
	thumb.get_node("%Initial").add_theme_font_size_override("font_size", 34)
	var frame := Panel.new()
	frame.theme_type_variation = &"PortraitFrame"
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb.add_child(frame)

	var text := VBoxContainer.new()
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 4)
	row.add_child(text)
	var value := GameState.get_affection(id)
	var top := HBoxContainer.new()
	text.add_child(top)
	var name_label := Label.new()
	name_label.text = GameData.get_character(id).get("name", id).to_upper()
	name_label.add_theme_font_override("font", UiStyle.display_font())
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_label)
	var score := UiStyle.caption("%s · %d / %d" % [GameState.get_level(id)["title"].to_upper(), value,
		GameState.MAX_AFFECTION], UiStyle.CYAN_PALE, 12)
	score.name = "Score"
	top.add_child(score)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 8)
	bar.max_value = GameState.MAX_AFFECTION
	bar.value = value
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(bar)
	if id == JayBalance.CHARACTER:
		var balance := UiStyle.caption(JayBalance.describe().to_upper(), UiStyle.TEXT_SOFT, 11)
		balance.name = "Balance"
		if not JayBalance.is_balanced():
			balance.add_theme_color_override("font_color", UiStyle.DUSK)
			balance.text += "  ·  OUT OF BALANCE: SPEND TIME WITH HIS OTHER SIDE"
		text.add_child(balance)
	return row
