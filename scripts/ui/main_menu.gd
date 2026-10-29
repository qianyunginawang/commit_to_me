extends Control
## Title screen: start a new game, continue a saved one, or quit.

@onready var name_edit: LineEdit = %NameEdit
@onready var new_game_button: Button = %NewGameButton
@onready var continue_button: Button = %ContinueButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	continue_button.visible = GameState.has_save()
	new_game_button.pressed.connect(_on_new_game)
	continue_button.pressed.connect(_on_continue)
	quit_button.pressed.connect(func(): get_tree().quit())
	name_edit.text_submitted.connect(func(_t): _on_new_game())
	name_edit.text = GameState.DEFAULT_PLAYER_NAME
	name_edit.select_all()
	name_edit.grab_focus()
	GameData.warm_up_runtimes()


func _on_new_game() -> void:
	GameState.new_game(name_edit.text)
	GameState.save_game()
	Router.goto(Router.MAP)


func _on_continue() -> void:
	if GameState.load_game():
		Router.goto(Router.MAP)
