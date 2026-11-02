class_name Looks
extends RefCounted
## How each speaker looks in the UI: name banner colors, language tag and
## portrait. Love interests take theirs from data/characters/<id>.json
## ("banner_color", "banner_text_color", "card_color", "day_language", and a
## "night" block for Jay). Quack and the player are set here.

## How speakers who aren't love interests look in dialogue.
const SPEAKER_LOOKS := {
	"quack": {"name": "Quack", "banner_color": "#ff3d7f", "banner_text_color": "#ffffff",
		"language": "Rubber duck", "portrait": "res://assets/portraits/quack.png"},
	"player": {"banner_color": "#ffd166", "banner_text_color": "#06121f", "language": ""},
}


## How a speaker looks right now: {name, banner_color, banner_text_color,
## language, portrait, card_color}. Jay's look follows the time of day
## (TypeScript by day, JavaScript by night, from the "night" block in
## data/characters/javascript.json).
static func speaker_look(speaker: String, slot: String = "day") -> Dictionary:
	var look: Dictionary = {}
	if SPEAKER_LOOKS.has(speaker):
		look = SPEAKER_LOOKS[speaker].duplicate()
	else:
		var character: Dictionary = GameData.get_character(speaker)
		if character.is_empty():
			return {}
		look = {
			"name": character.get("name", speaker),
			"banner_color": character.get("banner_color", "#ff3d7f"),
			"banner_text_color": character.get("banner_text_color", "#ffffff"),
			"card_color": character.get("card_color", "#16284a"),
			"language": character.get("day_language", character.get("language", "")),
			"portrait": character.get("portrait", ""),
		}
		if slot == "night" and character.has("night"):
			var day_portrait: String = look["portrait"]
			look.merge(character["night"], true)
			# Until the night art exists, Night Jay uses the day portrait.
			if not ResourceLoader.exists(look["portrait"]):
				look["portrait"] = day_portrait
	if speaker == "player":
		look["name"] = GameState.player_name
	return look
