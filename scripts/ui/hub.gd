extends Control
## "Who will you commit to today?" Pick a character and go on a date.

const CharacterCardScene := preload("res://scenes/character_card.tscn")

@onready var cards: HBoxContainer = %Cards
@onready var greeting: Label = %Greeting
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	greeting.text = "Who will you commit to today, %s?" % GameState.player_name
	menu_button.pressed.connect(func(): Router.goto(Router.MAIN_MENU))
	for id in GameData.character_ids():
		var card := CharacterCardScene.instantiate()
		card.setup(GameData.get_character(id))
		card.date_requested.connect(_on_date_requested)
		cards.add_child(card)


func _on_date_requested(_character_id: String, date_id: String) -> void:
	Router.goto(Router.DATE, {"date_id": date_id})
