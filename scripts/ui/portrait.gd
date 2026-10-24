class_name Portrait
extends Control
## Shows a character's portrait image, or a colored placeholder with their
## initial if no art exists yet. Drop art into assets/portraits/<id>.png
## and it shows up automatically.

@onready var placeholder: ColorRect = %Placeholder
@onready var initial_label: Label = %Initial
@onready var image: TextureRect = %Image


func show_character(character: Dictionary) -> void:
	var path: String = character.get("portrait", "")
	if path != "" and ResourceLoader.exists(path):
		image.texture = load(path)
		image.visible = true
		placeholder.visible = false
	else:
		image.visible = false
		placeholder.visible = true
		placeholder.color = Color.from_string(character.get("color", "#888888"), Color.GRAY)
		initial_label.text = String(character.get("name", "?")).left(1)
		var accent := Color.from_string(character.get("accent", "#ffffff"), Color.WHITE)
		initial_label.add_theme_color_override("font_color", accent)
