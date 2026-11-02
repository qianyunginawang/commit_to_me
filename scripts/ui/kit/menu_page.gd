class_name MenuPage
extends Control
## A title-screen page: the title backdrop with one glass panel in the
## middle, and a Back button that returns to the title screen (Esc does too).
## The new game, continue and settings pages extend this.

var panel: GlassPanel
## Put the page's content in here.
var body: VBoxContainer
## The bottom row: Back on the left. Add the page's own buttons after it.
var footer: HBoxContainer
var back_button: Button


func build_page(tab: String, panel_size: Vector2) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var backdrop := TitleBackdrop.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	panel = GlassPanel.new()
	panel.tab_text = tab
	panel.custom_minimum_size = panel_size
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 22)
	margin.add_child(column)

	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)

	footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	column.add_child(footer)
	back_button = Button.new()
	back_button.text = "BACK"
	back_button.custom_minimum_size = Vector2(140, 44)
	back_button.pressed.connect(go_back)
	footer.add_child(back_button)


## Pushes the page's own buttons to the right end of the footer.
func add_footer_spacer() -> void:
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)


## Back to the title screen, or, when opened over a scene (Settings from the
## pause menu), just closes.
func go_back() -> void:
	if get_tree().current_scene != self:
		get_parent().remove_child(self)
		queue_free()
		return
	Router.goto(Router.MAIN_MENU)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		go_back()
