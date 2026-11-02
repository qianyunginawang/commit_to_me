extends Node
## Player settings (volume, text and auto speed, fullscreen, Quack's hints), saved to
## user://settings.cfg. They belong to the player, not a save slot.
##
## Available everywhere as the `Settings` autoload.

signal changed

## Audio buses the volume sliders control. Music and Voice are made on
## startup if the project doesn't have them yet.
const BUSES := {"master_volume": "Master", "music_volume": "Music", "voice_volume": "Voice"}

## Dialogue types this many characters per second at the slowest and fastest
## text speed.
const SLOWEST_TEXT := 15.0
const FASTEST_TEXT := 90.0

const DEFAULTS := {
	"master_volume": 0.8,
	"music_volume": 0.7,
	"voice_volume": 0.7,
	"text_speed": 0.4,
	"auto_speed": 0.5,
	"fullscreen": false,
	"quack_hints": true,
}

var settings_path := "user://settings.cfg"
var values: Dictionary = DEFAULTS.duplicate()


func _ready() -> void:
	for bus in BUSES.values():
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	load_settings()
	_apply_all()


func get_value(key: String) -> Variant:
	return values.get(key, DEFAULTS.get(key))


func set_value(key: String, value: Variant) -> void:
	if values.get(key) == value:
		return
	values[key] = value
	_apply(key)
	save_settings()
	changed.emit()


## How fast dialogue types out, from the text speed setting.
func chars_per_second() -> float:
	return lerpf(SLOWEST_TEXT, FASTEST_TEXT, get_value("text_speed"))


## How long Auto waits after a line finishes typing before moving on: from
## 3 seconds (slowest) to 0.4 (fastest), plus a little for long lines.
func auto_delay(characters: int) -> float:
	return lerpf(3.0, 0.4, get_value("auto_speed")) + 0.01 * characters


func quack_hints() -> bool:
	return get_value("quack_hints")


func load_settings() -> void:
	values = DEFAULTS.duplicate()
	var cfg := ConfigFile.new()
	if cfg.load(settings_path) != OK:
		return
	for key in DEFAULTS:
		var saved = cfg.get_value("settings", key, DEFAULTS[key])
		if typeof(saved) == typeof(DEFAULTS[key]) or (saved is int and DEFAULTS[key] is float):
			values[key] = type_convert(saved, typeof(DEFAULTS[key]))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for key in values:
		cfg.set_value("settings", key, values[key])
	cfg.save(settings_path)


func _apply_all() -> void:
	for key in values:
		_apply(key)


func _apply(key: String) -> void:
	if BUSES.has(key):
		var bus := AudioServer.get_bus_index(BUSES[key])
		if bus != -1:
			var volume: float = values[key]
			AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.0001)))
			AudioServer.set_bus_mute(bus, volume <= 0.0)
	elif key == "fullscreen" and DisplayServer.get_name() != "headless":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if values[key] else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)
