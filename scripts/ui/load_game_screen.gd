extends MenuPage
## Continue game: every save slot, most recently played at the top. Each has
## a delete button that asks once more before deleting.

const MONTHS := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

var list: VBoxContainer


func _ready() -> void:
	build_page("Continue", Vector2(720, 500))
	var caption := UiStyle.caption("PICK A SAVE", UiStyle.TEXT_MUTED, 12)
	body.add_child(caption)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)

	refresh()


## Rebuilds the list of saves.
func refresh() -> void:
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	var saves := GameState.list_saves()
	for i in saves.size():
		list.add_child(_entry(saves[i], i == 0))
	if saves.is_empty():
		list.add_child(UiStyle.caption("NO SAVES YET", UiStyle.TEXT_DIM, 12))
		back_button.grab_focus.call_deferred()
	else:
		list.get_child(0).get_child(0).grab_focus.call_deferred()


func delete(path: String) -> void:
	GameState.delete_save(path)
	refresh()


func play(path: String) -> void:
	if GameState.load_game(path):
		Router.goto(Router.MAP)


## One save's row and its delete button, side by side.
func _entry(save: Dictionary, latest: bool) -> HBoxContainer:
	var entry := HBoxContainer.new()
	entry.add_theme_constant_override("separation", 8)
	var row := _row(save, latest)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.add_child(row)
	entry.add_child(_delete_button(save["path"]))
	return entry


## Pressing it once turns it into "SURE?"; pressing again deletes. Moving
## away from it (mouse or keyboard) cancels.
func _delete_button(path: String) -> Button:
	var button := Button.new()
	button.text = "DELETE"
	button.theme_type_variation = &"PinkButton"
	button.custom_minimum_size = Vector2(104, 66)
	var cancel := func():
		button.text = "DELETE"
	button.pressed.connect(func():
		if button.text == "SURE?":
			delete(path)
		else:
			button.text = "SURE?")
	button.mouse_exited.connect(func():
		if not button.has_focus():
			cancel.call())
	button.focus_exited.connect(cancel)
	return button


## One save: the heroine's name and where she is in the semester on the
## left, when it was saved on the right.
func _row(save: Dictionary, latest: bool) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"ListRow"
	button.custom_minimum_size = Vector2(0, 66)
	button.pressed.connect(play.bind(save["path"]))

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	button.add_child(margin)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var left := VBoxContainer.new()
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_theme_constant_override("separation", 2)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	var name_label := Label.new()
	name_label.text = save["player_name"]
	name_label.add_theme_font_override("font", UiStyle.body_font(800))
	name_label.add_theme_font_size_override("font_size", 20)
	left.add_child(name_label)
	left.add_child(UiStyle.caption(describe(save), UiStyle.CYAN_PALE, 12))

	if latest:
		var chip := UiStyle.chip("LATEST", UiStyle.PINK, UiStyle.TEXT)
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(chip)
	var when := Label.new()
	when.text = saved_when(save["saved_at"])
	when.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	when.add_theme_color_override("font_color", UiStyle.TEXT_MUTED)
	when.add_theme_font_size_override("font_size", 15)
	row.add_child(when)
	for child in [name_label, when]:
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return button


## Like "WEEK 3 · TUESDAY · NIGHT", or "SEMESTER OVER".
static func describe(save: Dictionary) -> String:
	if save["week"] > GameState.SEMESTER_WEEKS or save["ending"] != "":
		return "SEMESTER OVER"
	return "WEEK %d · %s · %s" % [save["week"], Calendar.DAY_NAMES[save["day"]].to_upper(), str(save["slot"]).to_upper()]


## Like "Nov 1, 9:14 PM", in the player's own time zone.
static func saved_when(unix: float) -> String:
	var local: int = int(unix) + int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var d := Time.get_datetime_dict_from_unix_time(local)
	var hour: int = d["hour"] % 12
	return "%s %d, %d:%02d %s" % [MONTHS[d["month"] - 1], d["day"], 12 if hour == 0 else hour,
		d["minute"], "PM" if d["hour"] >= 12 else "AM"]
