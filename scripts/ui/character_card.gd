extends PanelContainer
## One character on the "who do you want to date?" screen.

signal date_requested(character_id: String, date_id: String)

@onready var portrait: Portrait = %Portrait
@onready var name_label: Label = %NameLabel
@onready var language_label: Label = %LanguageLabel
@onready var tagline_label: Label = %TaglineLabel
@onready var affection_bar: ProgressBar = %AffectionBar
@onready var level_label: Label = %LevelLabel
@onready var date_button: Button = %DateButton

var character: Dictionary = {}
var _date_id: String = ""


## Call before adding the card to the scene tree.
func setup(p_character: Dictionary) -> void:
	character = p_character


func _ready() -> void:
	portrait.show_character(character)
	name_label.text = character.get("name", "???")
	language_label.text = character.get("language", "")
	tagline_label.text = character.get("tagline", "")
	date_button.pressed.connect(func(): date_requested.emit(character.get("id", ""), _date_id))
	refresh()


func refresh() -> void:
	var id: String = character.get("id", "")
	var value := GameState.get_affection(id)
	affection_bar.value = value
	level_label.text = "%s  (%d/%d)" % [GameState.get_level(id)["title"], value, GameState.MAX_AFFECTION]

	var all_dates: Array = character.get("dates", [])
	_date_id = GameState.next_date(all_dates)
	if _date_id != "":
		date_button.text = "Go on a date"
		date_button.disabled = false
	elif not all_dates.is_empty():
		_date_id = all_dates[-1]
		date_button.text = "Replay last date"
		date_button.disabled = false
	else:
		date_button.text = "Coming soon"
		date_button.disabled = true
