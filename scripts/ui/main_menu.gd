extends Control
## Title screen: continue a saved game, start a new one, settings, or quit.

## A new game opens with orientation, where Quack asks the player's name.
const OPENING_SCENE := "orientation"
const OPENING_EVENT := "orientation"

@onready var continue_button: Button = %ContinueButton
@onready var new_game_button: Button = %NewGameButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var endings_label: Label = %EndingsLabel
@onready var title_label: Label = %Title


func _ready() -> void:
	continue_button.pressed.connect(func(): Router.goto(Router.LOAD_GAME))
	new_game_button.pressed.connect(new_game)
	settings_button.pressed.connect(func(): Router.goto(Router.SETTINGS))
	quit_button.pressed.connect(func(): get_tree().quit())
	# Continue is greyed out until there's a save to continue. The first
	# button you can press is the bright one, and has focus for the keyboard.
	continue_button.disabled = not GameState.has_any_save()
	var main := new_game_button if continue_button.disabled else continue_button
	main.theme_type_variation = &"BrightButton"
	main.grab_focus.call_deferred()
	UiStyle.style_banner(title_label, "Commit to Me", UiStyle.PINK, UiStyle.TEXT, 84)
	title_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var count := Profile.ending_count()
	endings_label.text = "ENDINGS SEEN: %d/%d" % [count["seen"], count["total"]]
	endings_label.visible = count["seen"] > 0
	GameData.warm_up_runtimes()


## Starts a new game in its own save slot (old saves are kept) and plays
## orientation. The slot is first written once the player gives their name.
func new_game() -> void:
	GameState.new_game("")
	GameState.start_new_save()
	Router.goto(Router.DATE, {"date_id": OPENING_SCENE, "event_id": OPENING_EVENT})
