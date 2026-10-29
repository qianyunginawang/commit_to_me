extends Control
## "Who will you commit to today?" Shows the date and time, who's around,
## and lets the player go on a date or let time pass.

const CharacterCardScene := preload("res://scenes/character_card.tscn")

@onready var cards: HBoxContainer = %Cards
@onready var greeting: Label = %Greeting
@onready var menu_button: Button = %MenuButton
@onready var time_label: Label = %TimeLabel
@onready var events_label: Label = %EventsLabel
@onready var wait_button: Button = %WaitButton


func _ready() -> void:
	greeting.text = "Who will you commit to today, %s?" % GameState.player_name
	menu_button.pressed.connect(func(): Router.goto(Router.MAIN_MENU))
	wait_button.pressed.connect(_on_wait)
	for id in GameData.character_ids():
		var card := CharacterCardScene.instantiate()
		card.setup(GameData.get_character(id))
		card.date_requested.connect(_on_date_requested)
		cards.add_child(card)
	_refresh_time()


func _refresh_time() -> void:
	time_label.text = Calendar.describe_now()
	var names: PackedStringArray = []
	for event in Calendar.events_now():
		names.append(event.get("name", ""))
	events_label.text = ("Happening now: " + ", ".join(names)) if not names.is_empty() else "Nothing special is happening right now."
	wait_button.text = "Wait until tonight" if GameState.slot == "day" else "Wait until tomorrow"
	wait_button.disabled = GameState.is_semester_over()
	for card in cards.get_children():
		if card.is_node_ready():
			card.refresh()


func _on_wait() -> void:
	GameState.advance_time()
	GameState.save_game()
	_refresh_time()


func _on_date_requested(_character_id: String, date_id: String, event_id: String) -> void:
	Router.goto(Router.DATE, {"date_id": date_id, "event_id": event_id})
