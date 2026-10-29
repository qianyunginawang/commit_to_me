extends PanelContainer
## One character at a location on the campus map. Shows where the
## character is right now and the lesson they can do there.

signal date_requested(character_id: String, date_id: String, event_id: String)

@onready var portrait: Portrait = %Portrait
@onready var name_label: Label = %NameLabel
@onready var language_label: Label = %LanguageLabel
@onready var tagline_label: Label = %TaglineLabel
@onready var affection_bar: ProgressBar = %AffectionBar
@onready var level_label: Label = %LevelLabel
@onready var date_button: Button = %DateButton

var character: Dictionary = {}
var _date_id: String = ""
var _event_id: String = ""


## Call before adding the card to the scene tree.
func setup(p_character: Dictionary) -> void:
	character = p_character


func _ready() -> void:
	portrait.show_character(character)
	name_label.text = character.get("name", "???")
	language_label.text = character.get("language", "")
	tagline_label.text = character.get("tagline", "")
	date_button.pressed.connect(func(): date_requested.emit(character.get("id", ""), _date_id, _event_id))
	refresh()


func refresh() -> void:
	var id: String = character.get("id", "")
	var value := GameState.get_affection(id)
	affection_bar.value = value
	level_label.text = "%s  (%d/%d)" % [GameState.get_level(id)["title"], value, GameState.MAX_AFFECTION]

	_date_id = ""
	_event_id = ""
	var here := Calendar.opportunity_for(id)
	if here.is_empty():
		date_button.text = "Not around right now"
		date_button.disabled = true
		return
	_event_id = here["event"]["id"]
	var event_name: String = here["event"].get("name", "")
	if not here["lessons"].is_empty():
		var lesson: Dictionary = here["lessons"][0]
		_date_id = lesson["dialogue"]
		date_button.text = lesson.get("title", "Lesson")
		date_button.disabled = false
		return

	# Nothing to learn here yet: fall back to the character's first dates.
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
		date_button.text = "Nothing new to learn"
		date_button.disabled = true
