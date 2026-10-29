extends Node
## Tiny helper for switching screens and passing data to the next one.
##
##     Router.goto(Router.DATE, {"date_id": "python_date_1"})
## then in the new scene:
##     var date_id = Router.params.get("date_id")
##
## Available everywhere as the `Router` autoload.

const MAIN_MENU := "res://scenes/main_menu.tscn"
const MAP := "res://scenes/campus_map.tscn"
const DATE := "res://scenes/date.tscn"

## Data for the scene being opened.
var params: Dictionary = {}


func goto(scene_path: String, p_params: Dictionary = {}) -> void:
	params = p_params
	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("Couldn't open %s: %s" % [scene_path, error_string(err)])
