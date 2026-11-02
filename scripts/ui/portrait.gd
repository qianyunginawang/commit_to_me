class_name Portrait
extends Control
## Shows a character's portrait image, or a colored placeholder with their
## initial if no art exists yet. Drop art into assets/portraits/<id>.png
## and it shows up automatically.

@onready var placeholder: ColorRect = %Placeholder
@onready var initial_label: Label = %Initial
@onready var image: TextureRect = %Image

## True when the art has a see-through background (like Quack), so it stands
## in the scene without a frame around it.
var is_cutout := false


func show_character(character: Dictionary) -> void:
	_show(character.get("portrait", ""), character.get("name", "?"),
		character.get("color", "#888888"), character.get("accent", "#ffffff"))


## Shows a look from Looks.speaker_look (so Jay can change with the time of day).
func show_look(look: Dictionary) -> void:
	_show(look.get("portrait", ""), look.get("name", "?"),
		look.get("card_color", look.get("banner_color", "#16284a")), look.get("banner_color", "#ffffff"))


func _show(path: String, display_name: String, color: String, accent: String) -> void:
	if not is_node_ready():
		# Called before the portrait is in the scene tree: show it once it is.
		ready.connect(_show.bind(path, display_name, color, accent), CONNECT_ONE_SHOT)
		return
	if path != "" and ResourceLoader.exists(path):
		image.texture = load(path)
		var art := image.texture.get_image()
		is_cutout = art != null and art.detect_alpha() != Image.ALPHA_NONE
		image.visible = true
		placeholder.visible = false
	else:
		is_cutout = false
		image.visible = false
		placeholder.visible = true
		placeholder.color = Color.from_string(color, Color.GRAY)
		initial_label.text = display_name.left(1)
		initial_label.add_theme_font_override("font", UiStyle.display_font())
		initial_label.add_theme_color_override("font_color", Color.from_string(accent, Color.WHITE))
