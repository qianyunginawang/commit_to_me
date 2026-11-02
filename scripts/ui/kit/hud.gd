class_name Hud
extends Control
## The always-on info card in the top left:
##   NAME
##   CS Freshman
##   WEEK 3/14 · TUESDAY · [NIGHT]
##   PLACE
## Call refresh() when the name, time or place changes.

const SLOT_LABELS := {"day": "DAY", "dusk": "DUSK", "night": "NIGHT"}
const CARD := Rect2(16, 14, 340, 112)

@export var show_player := true
## The last line, like "MAIN QUAD · ORIENTATION DAY" or "WHERE TO TODAY?".
var place_text := ""

var _card_panel: Panel
var _name_label: Label
var _time_label: Label
var _slot_chip: Label
var _place_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_card()
	refresh()


func refresh(p_place_text: String = place_text, slot_override: String = "") -> void:
	place_text = p_place_text
	_card_panel.visible = show_player
	_name_label.text = GameState.player_name.to_upper()
	_time_label.text = "WEEK %d/%d  ·  %s" % [GameState.week, GameState.SEMESTER_WEEKS,
		Calendar.DAY_NAMES[mini(GameState.day, 6)].to_upper()]
	var slot := slot_override if slot_override != "" else GameState.slot
	_slot_chip.text = SLOT_LABELS.get(slot, slot.to_upper())
	_slot_chip.add_theme_stylebox_override("normal", UiStyle.chip_box(UiStyle.SLOT_COLORS.get(slot, UiStyle.GOLD)))
	_place_label.text = place_text.to_upper()
	_place_label.visible = place_text != ""


## How many lessons (dialogues with a code challenge) the player has passed.
static func lessons_done() -> int:
	var count := 0
	for id in GameState.completed_dates:
		if GameData.dialogue_challenge(id) != "":
			count += 1
	return count


func _build_card() -> void:
	_card_panel = Panel.new()
	_card_panel.position = CARD.position
	_card_panel.size = CARD.size
	_card_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := UiStyle.glass_box(18)
	box.corner_radius_top_left = 0
	box.corner_radius_bottom_left = 0
	_card_panel.add_theme_stylebox_override("panel", box)
	add_child(_card_panel)

	var column := VBoxContainer.new()
	column.position = Vector2(20, 10)
	column.size = CARD.size - Vector2(40, 20)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 3)
	_card_panel.add_child(column)

	_name_label = _text("", UiStyle.label_font(2), 19, UiStyle.TEXT)
	column.add_child(_name_label)
	column.add_child(_text("CS Freshman", UiStyle.body_font(600), 13, UiStyle.TEXT_MUTED))

	var time_row := HBoxContainer.new()
	time_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	time_row.add_theme_constant_override("separation", 10)
	column.add_child(time_row)
	_time_label = _text("", UiStyle.label_font(2), 13, UiStyle.TEXT)
	time_row.add_child(_time_label)
	_slot_chip = UiStyle.chip("DAY", UiStyle.GOLD, UiStyle.INK, 11)
	_slot_chip.custom_minimum_size = Vector2(54, 0)
	_slot_chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_slot_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	time_row.add_child(_slot_chip)

	_place_label = _text("", UiStyle.label_font(2), 11, UiStyle.CYAN_PALE)
	_place_label.clip_text = true
	_place_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(_place_label)


func _text(text: String, font: Font, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
