extends Control
## The end of the semester. The route goes to the character with the most
## affection (if several are tied, the player picks one of them). Their
## ending plays as a dialogue in the date scene, then the player comes back
## here to see which ending they got.

@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var choices: VBoxContainer = %Choices
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	menu_button.pressed.connect(func(): Router.goto(Router.MAIN_MENU))
	if GameState.ending_id != "":
		_show_result(Endings.find(GameState.ending_id))
	elif GameState.has_flag("polyglot"):
		_show_polyglot()
	else:
		_show_route(Endings.route_characters())


func _show_route(top: Array[String]) -> void:
	title_label.text = "The semester is over"
	if top.size() == 1:
		var char_name: String = GameData.get_character(top[0]).get("name", top[0])
		subtitle_label.text = "You spent the most time with %s." % char_name
		var button := Button.new()
		button.name = top[0]
		button.text = "Spend the end of the semester with %s" % char_name
		button.pressed.connect(_on_chosen.bind(top[0]))
		choices.add_child(button)
		return
	subtitle_label.text = "It's a tie! Who do you want to spend the end of the semester with?"
	for id in top:
		var button := Button.new()
		button.name = id
		button.text = "%s  ·  %s (%d)" % [GameData.get_character(id).get("name", id), GameState.get_level(id)["title"], GameState.get_affection(id)]
		button.pressed.connect(_on_chosen.bind(id))
		choices.add_child(button)


func _show_polyglot() -> void:
	title_label.text = "The semester is over"
	subtitle_label.text = "You chose all four. Time to find out if it compiles."
	var button := Button.new()
	button.name = "polyglot"
	button.text = "Spend the end of the semester with everyone"
	button.pressed.connect(_play.bind(Endings.polyglot_ending()))
	choices.add_child(button)


func _on_chosen(character_id: String) -> void:
	_play(Endings.ending_for(character_id))


func _play(ending: Dictionary) -> void:
	GameState.ending_id = ending.get("id", "")
	GameState.save_game()
	Profile.record_ending(GameState.ending_id)
	Router.goto(Router.DATE, {"date_id": ending.get("dialogue", ""), "return_to": Router.ENDINGS})


func _show_result(ending: Dictionary) -> void:
	title_label.text = ending.get("title", "The End")
	subtitle_label.text = ending.get("summary", "")
	var again := Button.new()
	again.name = "Replay"
	again.text = "Watch it again"
	again.pressed.connect(func(): Router.goto(Router.DATE, {"date_id": ending.get("dialogue", ""), "return_to": Router.ENDINGS}))
	choices.add_child(again)
