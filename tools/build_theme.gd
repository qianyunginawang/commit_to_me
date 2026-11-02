extends SceneTree
## Rebuilds assets/theme.tres (the game-wide theme) from scripts/ui/kit/ui_style.gd.
##
##   godot --headless --path . -s tools/build_theme.gd
##
## Theme type variations you can set on a node's theme_type_variation:
##   Button:  PinkButton (exit, leave), BrightButton (the main action),
##            ChoiceButton (dialogue choices), ListRow (rows in a list),
##            QuickButton (History / Auto / Skip under the dialogue),
##            DialogueChoice (answers inside the dialogue box)
##   Label:   Caption (small spaced caps), Title (Anton)

const OUT := "res://assets/theme.tres"


func _initialize() -> void:
	var theme := build()
	var err := ResourceSaver.save(theme, OUT)
	print("Saved %s (%s)" % [OUT, error_string(err)])
	quit(0 if err == OK else 1)


static func build() -> Theme:
	var t := Theme.new()
	t.default_font = UiStyle.body_font(600)
	t.default_font_size = 18

	# Labels and text
	t.set_color("font_color", "Label", UiStyle.TEXT)
	t.set_color("default_color", "RichTextLabel", UiStyle.TEXT)
	t.set_font("normal_font", "RichTextLabel", UiStyle.body_font(600))
	t.set_font("bold_font", "RichTextLabel", UiStyle.body_font(800))
	t.set_type_variation("Caption", "Label")
	t.set_font("font", "Caption", UiStyle.label_font(3))
	t.set_font_size("font_size", "Caption", 11)
	t.set_color("font_color", "Caption", UiStyle.TEXT_MUTED)
	t.set_type_variation("Title", "Label")
	t.set_font("font", "Title", UiStyle.display_font())
	t.set_font_size("font_size", "Title", 36)

	# Buttons: glass with a cyan edge, cut corners, spaced caps
	_button(t, "Button",
		UiStyle.button_box(Color(0.1, 0.2, 0.33, 0.92), Color(0.5, 0.9, 1, 0.6)),
		UiStyle.button_box(Color(0.14, 0.29, 0.46, 0.95), UiStyle.CYAN_PALE),
		UiStyle.button_box(UiStyle.CYAN, UiStyle.CYAN),
		UiStyle.button_box(Color(0.05, 0.09, 0.16, 0.8), Color(0.5, 0.9, 1, 0.18)))
	t.set_font("font", "Button", UiStyle.label_font(2))
	t.set_font_size("font_size", "Button", 14)
	t.set_color("font_color", "Button", UiStyle.TEXT_SOFT)
	t.set_color("font_hover_color", "Button", UiStyle.TEXT)
	t.set_color("font_focus_color", "Button", UiStyle.TEXT)
	t.set_color("font_pressed_color", "Button", UiStyle.INK)
	t.set_color("font_hover_pressed_color", "Button", UiStyle.INK)
	t.set_color("font_disabled_color", "Button", UiStyle.TEXT_DIM)
	var focus := UiStyle.button_box(Color.TRANSPARENT, UiStyle.GOLD)
	focus.draw_center = false
	t.set_stylebox("focus", "Button", focus)

	t.set_type_variation("PinkButton", "Button")
	_button(t, "PinkButton",
		UiStyle.button_box(Color(0.47, 0.08, 0.22, 0.92), UiStyle.PINK),
		UiStyle.button_box(Color(0.62, 0.11, 0.3, 0.95), Color("#ff8fb4")),
		UiStyle.button_box(UiStyle.PINK, UiStyle.PINK),
		UiStyle.button_box(Color(0.2, 0.05, 0.1, 0.8), Color(UiStyle.PINK, 0.3)))
	t.set_color("font_color", "PinkButton", Color("#ffe0ea"))

	t.set_type_variation("BrightButton", "Button")
	_button(t, "BrightButton",
		UiStyle.button_box(UiStyle.CYAN, UiStyle.CYAN),
		UiStyle.button_box(UiStyle.CYAN_PALE, UiStyle.TEXT),
		UiStyle.button_box(UiStyle.TEXT, UiStyle.TEXT),
		UiStyle.button_box(Color(0.05, 0.09, 0.16, 0.8), Color(0.5, 0.9, 1, 0.18)))
	t.set_color("font_color", "BrightButton", UiStyle.INK)
	t.set_color("font_hover_color", "BrightButton", UiStyle.INK)
	t.set_color("font_focus_color", "BrightButton", UiStyle.INK)

	# Dialogue choices: slanted, Nunito, pink edge on hover
	t.set_type_variation("ChoiceButton", "Button")
	var choice := func(bg: Color, border: Color) -> StyleBoxFlat:
		var box := UiStyle.slanted_box(bg, border, 0.28)
		box.content_margin_left = 24
		box.content_margin_right = 24
		box.content_margin_top = 12
		box.content_margin_bottom = 12
		return box
	_button(t, "ChoiceButton",
		choice.call(Color(0.063, 0.118, 0.212, 0.94), Color(0.5, 0.9, 1, 0.6)),
		choice.call(Color(0.22, 0.09, 0.2, 0.96), UiStyle.PINK),
		choice.call(UiStyle.PINK, UiStyle.PINK),
		choice.call(Color(0.05, 0.09, 0.16, 0.8), Color(0.5, 0.9, 1, 0.2)))
	t.set_font("font", "ChoiceButton", UiStyle.body_font(700))
	t.set_font_size("font_size", "ChoiceButton", 18)
	t.set_color("font_color", "ChoiceButton", UiStyle.TEXT)
	t.set_color("font_pressed_color", "ChoiceButton", UiStyle.TEXT)
	var choice_focus: StyleBoxFlat = choice.call(Color.TRANSPARENT, UiStyle.PINK)
	choice_focus.draw_center = false
	t.set_stylebox("focus", "ChoiceButton", choice_focus)

	# Rows in a list (lessons, scenes): a toggle, pink when picked
	t.set_type_variation("ListRow", "Button")
	var row := func(bg: Color, border: Color) -> StyleBoxFlat:
		var box := UiStyle.button_box(bg, border)
		box.content_margin_left = 14
		box.content_margin_right = 14
		box.content_margin_top = 6
		box.content_margin_bottom = 6
		return box
	_button(t, "ListRow",
		row.call(Color(0.37, 0.88, 1, 0.06), Color(0.5, 0.9, 1, 0.35)),
		row.call(Color(0.37, 0.88, 1, 0.14), Color(0.5, 0.9, 1, 0.7)),
		row.call(Color(1, 0.24, 0.5, 0.18), UiStyle.PINK),
		row.call(Color(0.37, 0.88, 1, 0.03), Color(0.5, 0.9, 1, 0.15)))
	t.set_font("font", "ListRow", UiStyle.body_font(600))
	t.set_font_size("font_size", "ListRow", 15)
	t.set_color("font_color", "ListRow", UiStyle.TEXT)
	t.set_color("font_pressed_color", "ListRow", UiStyle.TEXT)
	t.set_color("font_hover_pressed_color", "ListRow", UiStyle.TEXT)
	t.set_color("font_disabled_color", "ListRow", UiStyle.TEXT_DIM)
	t.set_constant("h_separation", "ListRow", 10)

	# Small text buttons under the dialogue (History, Auto, Skip): no box
	# until hovered; a toggled one glows cyan
	t.set_type_variation("QuickButton", "Button")
	var quiet := StyleBoxFlat.new()
	quiet.bg_color = Color.TRANSPARENT
	quiet.set_content_margin_all(4)
	var quiet_hover := UiStyle.button_box(Color(0.14, 0.29, 0.46, 0.6), Color(UiStyle.CYAN, 0.4), 6)
	var quiet_on := UiStyle.button_box(Color(UiStyle.CYAN, 0.18), UiStyle.CYAN, 6)
	_button(t, "QuickButton", quiet, quiet_hover, quiet_on, quiet)
	t.set_font_size("font_size", "QuickButton", 12)
	t.set_color("font_color", "QuickButton", UiStyle.TEXT_MUTED)
	t.set_color("font_hover_color", "QuickButton", UiStyle.TEXT)
	t.set_color("font_pressed_color", "QuickButton", UiStyle.CYAN)
	t.set_color("font_hover_pressed_color", "QuickButton", UiStyle.CYAN_PALE)

	# Answers listed inside the dialogue box: plain text until highlighted
	# (by the arrow keys or the mouse), then a cyan bar
	t.set_type_variation("DialogueChoice", "Button")
	var answer := StyleBoxFlat.new()
	answer.bg_color = Color.TRANSPARENT
	answer.content_margin_left = 14
	answer.content_margin_right = 14
	answer.content_margin_top = 4
	answer.content_margin_bottom = 4
	var answer_on := UiStyle.button_box(Color(UiStyle.CYAN, 0.16), Color(UiStyle.CYAN, 0.8), 6)
	answer_on.content_margin_left = 14
	answer_on.content_margin_right = 14
	answer_on.content_margin_top = 4
	answer_on.content_margin_bottom = 4
	_button(t, "DialogueChoice", answer, answer, answer_on, answer)
	t.set_stylebox("focus", "DialogueChoice", answer_on)
	t.set_font("font", "DialogueChoice", UiStyle.body_font(700))
	t.set_font_size("font_size", "DialogueChoice", 19)
	t.set_color("font_color", "DialogueChoice", UiStyle.TEXT_MUTED)
	t.set_color("font_hover_color", "DialogueChoice", UiStyle.TEXT_MUTED)
	t.set_color("font_focus_color", "DialogueChoice", UiStyle.TEXT)
	t.set_color("font_pressed_color", "DialogueChoice", UiStyle.TEXT)
	t.set_color("font_hover_pressed_color", "DialogueChoice", UiStyle.TEXT)
	t.set_constant("align_to_largest_stylebox", "DialogueChoice", 1)

	# Panels: glass frames
	var panel := UiStyle.glass_box()
	panel.set_content_margin_all(20)
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("panel", "Panel", UiStyle.glass_box())

	# A frame drawn over character art: a cyan edge
	t.set_type_variation("PortraitFrame", "Panel")
	var frame := StyleBoxFlat.new()
	frame.draw_center = false
	frame.border_color = Color(UiStyle.CYAN, 0.85)
	frame.set_border_width_all(2)
	t.set_stylebox("panel", "PortraitFrame", frame)

	# Text input
	var edit := UiStyle.button_box(Color(0.03, 0.06, 0.11, 0.95), Color(0.5, 0.9, 1, 0.6))
	edit.content_margin_top = 10
	edit.content_margin_bottom = 10
	t.set_stylebox("normal", "LineEdit", edit)
	var edit_focus := UiStyle.button_box(Color(0.03, 0.06, 0.11, 0.95), UiStyle.CYAN)
	edit_focus.set_border_width_all(2)
	t.set_stylebox("focus", "LineEdit", edit_focus)
	t.set_font("font", "LineEdit", UiStyle.body_font(700))
	t.set_font_size("font_size", "LineEdit", 22)
	t.set_color("font_color", "LineEdit", UiStyle.TEXT)
	t.set_color("caret_color", "LineEdit", UiStyle.CYAN)
	t.set_color("selection_color", "LineEdit", Color(UiStyle.PINK, 0.45))

	# Affection bars: pink glow on a dim track
	var track := StyleBoxFlat.new()
	track.bg_color = Color(1, 0.24, 0.5, 0.18)
	var fill := StyleBoxFlat.new()
	fill.bg_color = UiStyle.PINK
	fill.shadow_color = Color(1, 0.24, 0.5, 0.55)
	fill.shadow_size = 6
	t.set_stylebox("background", "ProgressBar", track)
	t.set_stylebox("fill", "ProgressBar", fill)

	# Code editor and popups pick up the glass look too
	var popup := UiStyle.glass_box(8)
	popup.set_content_margin_all(8)
	t.set_stylebox("panel", "PopupMenu", popup)
	t.set_stylebox("panel", "TooltipPanel", popup)
	t.set_font("font", "TooltipLabel", UiStyle.body_font(600))
	t.set_color("font_color", "TooltipLabel", UiStyle.TEXT)

	# Thin cyan scroll bars
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Color(UiStyle.CYAN, 0.55)
	grabber.content_margin_left = 3
	grabber.content_margin_right = 3
	var scroll_bg := StyleBoxFlat.new()
	scroll_bg.bg_color = Color(UiStyle.CYAN, 0.08)
	scroll_bg.content_margin_left = 3
	scroll_bg.content_margin_right = 3
	for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
		t.set_stylebox(state, "VScrollBar", grabber)
	t.set_stylebox("scroll", "VScrollBar", scroll_bg)

	# Sliders: a dim track filling with cyan, and a white knob with a cyan ring
	var slider := StyleBoxFlat.new()
	slider.bg_color = Color(UiStyle.CYAN_PALE, 0.18)
	slider.content_margin_top = 3
	slider.content_margin_bottom = 3
	var slider_fill := StyleBoxFlat.new()
	slider_fill.bg_color = UiStyle.CYAN
	slider_fill.content_margin_top = 3
	slider_fill.content_margin_bottom = 3
	t.set_stylebox("slider", "HSlider", slider)
	t.set_stylebox("grabber_area", "HSlider", slider_fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", slider_fill)
	t.set_icon("grabber", "HSlider", _knob(UiStyle.CYAN))
	t.set_icon("grabber_highlight", "HSlider", _knob(UiStyle.GOLD))
	t.set_icon("grabber_disabled", "HSlider", _knob(UiStyle.TEXT_DIM))
	var slider_focus := StyleBoxFlat.new()
	slider_focus.draw_center = false
	t.set_stylebox("focus", "HSlider", slider_focus)
	return t


## A 20 px knob: white with a coloured ring, smoothed at the edges.
static func _knob(ring: Color) -> ImageTexture:
	const SIZE := 20
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var c := Vector2(SIZE, SIZE) / 2.0
	for y in SIZE:
		for x in SIZE:
			var d := (Vector2(x, y) + Vector2(0.5, 0.5)).distance_to(c)
			var col := UiStyle.TEXT if d < 6.5 else ring
			col.a = clampf(9.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


static func _button(t: Theme, type: String, normal: StyleBox, hover: StyleBox, pressed: StyleBox, disabled: StyleBox) -> void:
	t.set_stylebox("normal", type, normal)
	t.set_stylebox("hover", type, hover)
	t.set_stylebox("pressed", type, pressed)
	t.set_stylebox("hover_pressed", type, pressed)
	t.set_stylebox("disabled", type, disabled)
