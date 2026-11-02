extends MenuPage
## Settings: volume, fullscreen, text speed and Quack's hints. Changes apply
## and save right away (see the Settings autoload).

## setting key -> its slider or switch, so tests can reach them.
var controls: Dictionary = {}


func _ready() -> void:
	build_page("Settings", Vector2(840, 0))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 60)
	grid.add_theme_constant_override("v_separation", 26)
	body.add_child(grid)

	var audio := _section(grid, "Audio")
	_slider(audio, "master_volume", "Master")
	_slider(audio, "music_volume", "Music")
	_slider(audio, "voice_volume", "Quack's voice", UiStyle.GOLD)
	var video := _section(grid, "Video")
	_toggle(video, "fullscreen", "Fullscreen")
	var gameplay := _section(grid, "Gameplay")
	_slider(gameplay, "text_speed", "Text speed")
	_slider(gameplay, "auto_speed", "Auto speed")
	var options := _section(grid, "Options")
	_toggle(options, "quack_hints", "Quack's hints in lessons")
	controls["master_volume"].grab_focus.call_deferred()


func _section(grid: GridContainer, title: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(340, 0)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 14)
	var heading := Label.new()
	heading.text = "◆  %s  ◆" % title.to_upper()
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font", UiStyle.label_font(5))
	heading.add_theme_font_size_override("font_size", 16)
	heading.add_theme_color_override("font_color", UiStyle.TEXT)
	heading.add_theme_color_override("font_shadow_color", Color(UiStyle.CYAN, 0.6))
	heading.add_theme_constant_override("shadow_outline_size", 8)
	heading.add_theme_constant_override("shadow_offset_x", 0)
	heading.add_theme_constant_override("shadow_offset_y", 0)
	box.add_child(heading)
	grid.add_child(box)
	return box


func _slider(box: VBoxContainer, key: String, label_text: String, color: Color = UiStyle.CYAN) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)
	row.add_child(_name_label(label_text, 118))
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 5
	slider.value = roundf(Settings.get_value(key) * 100.0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if color != UiStyle.CYAN:
		var fill := (get_theme_stylebox("grabber_area", "HSlider") as StyleBoxFlat).duplicate()
		fill.bg_color = color
		slider.add_theme_stylebox_override("grabber_area", fill)
		slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	row.add_child(slider)
	var percent := Label.new()
	percent.custom_minimum_size = Vector2(48, 0)
	percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	percent.add_theme_font_override("font", UiStyle.label_font(1))
	percent.add_theme_font_size_override("font_size", 14)
	percent.text = "%d%%" % slider.value
	row.add_child(percent)
	slider.value_changed.connect(func(v: float):
		percent.text = "%d%%" % v
		Settings.set_value(key, v / 100.0))
	controls[key] = slider


func _toggle(box: VBoxContainer, key: String, label_text: String) -> void:
	var row := HBoxContainer.new()
	box.add_child(row)
	var label := _name_label(label_text, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 17)
	row.add_child(label)
	var toggle := ToggleSwitch.new()
	toggle.button_pressed = Settings.get_value(key)
	toggle.toggled.connect(func(on: bool): Settings.set_value(key, on))
	row.add_child(toggle)
	controls[key] = toggle


func _name_label(text: String, width: float) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(width, 0)
	label.add_theme_color_override("font_color", UiStyle.TEXT_SOFT)
	label.add_theme_font_size_override("font_size", 16)
	return label
