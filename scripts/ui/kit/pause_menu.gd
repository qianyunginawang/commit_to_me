class_name PauseMenu
extends ColorRect
## The in-game menu, as a pop-up over the current screen: resume, history
## (when the screen has one), settings, or quit to the title screen. Quitting
## asks once more first. Esc closes it (or backs out of the quit question).
## While it's open the game is paused: typing text, Auto/Skip timers and
## anything else waiting to pop up all freeze, and carry on after Resume.

signal closed

## Shows a HISTORY button that closes the menu and calls this.
var on_history := Callable()

var _column: VBoxContainer
var _card: GlassPanel


func _init(history: Callable = Callable()) -> void:
	on_history = history


func _ready() -> void:
	name = "PauseMenu"
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	color = Color(UiStyle.SHADOW, 0.6)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_card = GlassPanel.new()
	_card.custom_minimum_size = Vector2(340, 0)
	add_child(_card)
	_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_card.grow_vertical = Control.GROW_DIRECTION_BOTH
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	_card.add_child(margin)
	_column = VBoxContainer.new()
	_column.add_theme_constant_override("separation", 14)
	margin.add_child(_column)
	show_buttons()


## The main list of buttons.
func show_buttons() -> void:
	_clear("Paused", 340)
	_button("RESUME", &"BrightButton", close)
	if on_history.is_valid():
		_button("HISTORY", &"", func():
			close()
			on_history.call())
	_button("SETTINGS", &"", open_settings)
	_button("QUIT TO TITLE", &"PinkButton", ask_quit)
	_focus.call_deferred(_column.get_child(0))


## "Are you sure?" before going back to the title screen.
func ask_quit() -> void:
	_clear("Quit to title", 420)
	var question := Label.new()
	question.name = "QuitQuestion"
	question.text = "Are you sure? Any unsaved progress will be lost."
	question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question.custom_minimum_size = Vector2(0, 56)
	question.add_theme_color_override("font_color", UiStyle.TEXT_SOFT)
	question.add_theme_font_size_override("font_size", 18)
	_column.add_child(question)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_column.add_child(row)
	var cancel := _button("CANCEL", &"BrightButton", show_buttons, row)
	_button("QUIT", &"PinkButton", quit_to_title, row)
	for b in row.get_children():
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_focus.call_deferred(cancel)


func is_asking_quit() -> bool:
	return _column.has_node("QuitQuestion")


func open_settings() -> void:
	var settings: Control = load(Router.SETTINGS).instantiate()
	settings.name = "SettingsOverlay"
	add_child(settings)


func quit_to_title() -> void:
	get_tree().paused = false
	GameState.save_game()
	Router.goto(Router.MAIN_MENU)


func close() -> void:
	closed.emit()
	if get_parent():
		get_parent().remove_child(self)
	queue_free()


func _exit_tree() -> void:
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if is_asking_quit():
			show_buttons()
		else:
			close()


func _focus(button: Button) -> void:
	if button.is_inside_tree():
		button.grab_focus()


func _clear(tab: String, width: float) -> void:
	_card.tab_text = tab
	_card.custom_minimum_size = Vector2(width, 0)
	for child in _column.get_children():
		_column.remove_child(child)
		child.queue_free()
	_card.reset_size()


func _button(text: String, variation: StringName, on_pressed: Callable, parent: Control = null) -> Button:
	var button := Button.new()
	button.text = text
	button.theme_type_variation = variation
	button.custom_minimum_size = Vector2(0, 46)
	button.pressed.connect(on_pressed)
	(parent if parent else _column).add_child(button)
	return button
