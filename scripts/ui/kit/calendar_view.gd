class_name CalendarView
extends ColorRect
## The semester calendar, as a pop-up over the current screen. A month grid
## on the left marks special events (story events in pink, deadlines and
## breaks in gold); pick a day to see everything on it, day and night,
## on the right. Today has a cyan ring. Close with the button or Esc.

signal closed

const CELL := Vector2(84, 66)
const STORY_COLOR := UiStyle.PINK
const INFO_COLOR := UiStyle.GOLD
const SLOT_NAMES := {"day": "DAY", "night": "NIGHT"}

## The month on show, as {"year", "month"}.
var month := {}
## Selected day, as days since the semester started (0 = week 1, Sunday).
var selected := 0

var _start_unix := 0
var _title: Label
var _grid: GridContainer
var _detail: VBoxContainer


func _ready() -> void:
	name = "CalendarOverlay"
	color = Color(UiStyle.SHADOW, 0.6)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_start_unix = Time.get_unix_time_from_datetime_string(GameData.calendar.get("start_date", "2030-09-01"))
	selected = clampi((GameState.week - 1) * 7 + GameState.day, 0, semester_days() - 1)
	var today := Time.get_datetime_dict_from_unix_time(_start_unix + selected * 86400)
	month = {"year": today["year"], "month": today["month"]}
	_build()
	refresh()


func semester_days() -> int:
	return int(GameData.calendar.get("weeks", GameState.SEMESTER_WEEKS)) * 7


## The special events on a semester day (story and info events, not the
## weekly ones). Hidden story routes stay hidden until their flag is set.
static func special_events(offset: int) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for event in _events_on(offset):
		if event.get("kind", "") != "recurring":
			found.append(event)
	return found


static func _events_on(offset: int) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var week := offset / 7 + 1
	var day := offset % 7
	for event in GameData.calendar.get("events", []):
		var flag: String = event.get("requires", "")
		if flag != "" and not GameState.has_flag(flag):
			continue
		for slot in ["day", "night"]:
			if Calendar.is_event_on(event, week, day, slot):
				var copy: Dictionary = event.duplicate()
				copy["slot"] = slot
				found.append(copy)
				break
	return found


func close() -> void:
	closed.emit()
	if get_parent():
		get_parent().remove_child(self)
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func show_month(step: int) -> void:
	var m: int = month["month"] + step
	var y: int = month["year"]
	if m < 1:
		m = 12
		y -= 1
	elif m > 12:
		m = 1
		y += 1
	# Only months that are part of the semester.
	var first := _offset_of(y, m, 1)
	var last := _offset_of(y, m, _days_in_month(y, m))
	if last < 0 or first >= semester_days():
		return
	month = {"year": y, "month": m}
	refresh()


func refresh() -> void:
	var y: int = month["year"]
	var m: int = month["month"]
	_title.text = "%s %d" % [Calendar.MONTH_NAMES[m - 1].to_upper(), y]
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	for d in Calendar.DAY_NAMES:
		var head := UiStyle.caption(d.left(3).to_upper(), UiStyle.TEXT_MUTED, 11)
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_grid.add_child(head)
	var first_weekday := (_offset_of(y, m, 1) % 7 + 7) % 7
	for i in first_weekday:
		_grid.add_child(_blank())
	for date in range(1, _days_in_month(y, m) + 1):
		_grid.add_child(_cell(date, _offset_of(y, m, date)))
	_show_detail()


func _offset_of(y: int, m: int, d: int) -> int:
	var unix := Time.get_unix_time_from_datetime_dict({"year": y, "month": m, "day": d, "hour": 0, "minute": 0, "second": 0})
	return int(floor((unix - _start_unix) / 86400.0))


static func _days_in_month(y: int, m: int) -> int:
	if m == 2:
		return 29 if (y % 4 == 0 and (y % 100 != 0 or y % 400 == 0)) else 28
	return 30 if m in [4, 6, 9, 11] else 31


func _blank() -> Control:
	var c := Control.new()
	c.custom_minimum_size = CELL
	return c


func _cell(date: int, offset: int) -> Control:
	var in_semester := offset >= 0 and offset < semester_days()
	var today := offset == (GameState.week - 1) * 7 + GameState.day
	var button := Button.new()
	button.name = "Day%d" % date
	button.custom_minimum_size = CELL
	button.theme_type_variation = &"ListRow"
	button.focus_mode = Control.FOCUS_NONE
	button.disabled = not in_semester
	button.toggle_mode = true
	button.button_pressed = offset == selected
	if today:
		var ring := UiStyle.button_box(Color(UiStyle.CYAN, 0.12), UiStyle.CYAN, 6)
		ring.set_border_width_all(2)
		for state in ["normal", "hover", "pressed", "hover_pressed"]:
			button.add_theme_stylebox_override(state, ring)
	button.pressed.connect(func():
		selected = offset
		refresh())

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 6
	column.offset_right = -6
	column.offset_top = 3
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 2)
	button.add_child(column)
	var number := Label.new()
	number.text = str(date)
	number.add_theme_font_override("font", UiStyle.label_font(1))
	number.add_theme_font_size_override("font_size", 13)
	var past := in_semester and offset < (GameState.week - 1) * 7 + GameState.day
	number.add_theme_color_override("font_color",
		UiStyle.TEXT_DIM if not in_semester or past else UiStyle.TEXT)
	column.add_child(number)
	if in_semester:
		var events := special_events(offset)
		for i in mini(events.size(), 2):
			column.add_child(_event_tag(events[i]))
		if events.size() > 2:
			column.add_child(UiStyle.caption("+%d MORE" % (events.size() - 2), UiStyle.TEXT_MUTED, 8))
	return button


func _event_tag(event: Dictionary) -> Label:
	var tag := Label.new()
	tag.text = event.get("name", "")
	tag.clip_text = true
	tag.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tag.add_theme_font_size_override("font_size", 9)
	tag.add_theme_font_override("font", UiStyle.body_font(800))
	var c := STORY_COLOR if event.get("kind") == "story" else INFO_COLOR
	tag.add_theme_color_override("font_color", UiStyle.INK)
	tag.add_theme_stylebox_override("normal", UiStyle.chip_box(c))
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tag


## Everything on the selected day: special events, then the weekly ones,
## under DAY and NIGHT.
func _show_detail() -> void:
	for child in _detail.get_children():
		_detail.remove_child(child)
		child.queue_free()
	var week := selected / 7 + 1
	var day := selected % 7
	var heading := Label.new()
	heading.text = Calendar.date_for(week, day)
	heading.theme_type_variation = &"Title"
	heading.add_theme_font_size_override("font_size", 26)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_child(heading)
	_detail.add_child(UiStyle.caption("WEEK %d OF %d" % [week, semester_days() / 7], UiStyle.CYAN_PALE, 11))
	var events := _events_on(selected)
	events.sort_custom(func(a, b): return a.get("kind") != "recurring" and b.get("kind") == "recurring")
	for slot in ["day", "night"]:
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 4)
		_detail.add_child(gap)
		_detail.add_child(UiStyle.caption(SLOT_NAMES[slot], UiStyle.SLOT_COLORS[slot], 12))
		var any := false
		for event in events:
			if event["slot"] == slot:
				_detail.add_child(_detail_row(event))
				any = true
		if not any:
			_detail.add_child(_muted("Nothing scheduled"))


func _detail_row(event: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	var name_label := Label.new()
	var special: bool = event.get("kind") != "recurring"
	name_label.text = ("★ " if special else "") + event.get("name", "")
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_font_override("font", UiStyle.body_font(800 if special else 600))
	name_label.add_theme_color_override("font_color",
		(STORY_COLOR if event.get("kind") == "story" else INFO_COLOR) if special else UiStyle.TEXT)
	box.add_child(name_label)
	var bits: PackedStringArray = []
	var place: String = GameData.locations.get(event.get("location", ""), {}).get("name", "")
	if place != "":
		bits.append(place)
	var people: PackedStringArray = []
	for id in event.get("characters", []):
		people.append(GameData.get_character(id).get("name", id))
	if people.size() == 4:
		bits.append("Everyone")
	elif not people.is_empty():
		bits.append(", ".join(people))
	if not bits.is_empty():
		box.add_child(_muted(" · ".join(bits)))
	return box


func _muted(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", UiStyle.TEXT_MUTED)
	return label


func _build() -> void:
	var card := GlassPanel.new()
	card.tab_text = "Calendar"
	add_child(card)
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	margin.add_child(row)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	row.add_child(left)
	var header := HBoxContainer.new()
	left.add_child(header)
	var prev := Button.new()
	prev.name = "PrevMonth"
	prev.text = "◀"
	prev.custom_minimum_size = Vector2(44, 36)
	prev.pressed.connect(show_month.bind(-1))
	header.add_child(prev)
	_title = Label.new()
	_title.add_theme_font_override("font", UiStyle.display_font())
	_title.add_theme_font_size_override("font_size", 28)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	var next := Button.new()
	next.name = "NextMonth"
	next.text = "▶"
	next.custom_minimum_size = Vector2(44, 36)
	next.pressed.connect(show_month.bind(1))
	header.add_child(next)
	_grid = GridContainer.new()
	_grid.columns = 7
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	left.add_child(_grid)
	var legend := HBoxContainer.new()
	legend.add_theme_constant_override("separation", 16)
	legend.add_child(_legend_item(STORY_COLOR, "STORY EVENT"))
	legend.add_child(_legend_item(INFO_COLOR, "DEADLINE / BREAK"))
	legend.add_child(_legend_item(UiStyle.CYAN, "TODAY"))
	left.add_child(legend)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(280, 0)
	right.add_theme_constant_override("separation", 10)
	row.add_child(right)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	_detail = VBoxContainer.new()
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.add_theme_constant_override("separation", 6)
	scroll.add_child(_detail)
	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "CLOSE"
	close_button.custom_minimum_size = Vector2(0, 42)
	close_button.pressed.connect(close)
	right.add_child(close_button)


func _legend_item(c: Color, text: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var swatch := ColorRect.new()
	swatch.color = c
	swatch.custom_minimum_size = Vector2(12, 12)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(swatch)
	row.add_child(UiStyle.caption(text, UiStyle.TEXT_MUTED, 10))
	return row
