class_name Icons
extends RefCounted
## Small line icons (24x24 SVG, drawn with "currentColor" strokes) turned into
## textures at runtime, so they need no image files or imports.
##
##   button.icon = Icons.get_icon("play", Color.WHITE)

const SVG := {
	"code": '<polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/>',
	"terminal": '<polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/>',
	"reset": '<path d="M3 12a9 9 0 1 0 3-6.7"/><polyline points="3 3 3 9 9 9"/>',
	"play": '<polygon points="6 4 20 12 6 20 6 4" fill="currentColor"/>',
	"bulb": '<path d="M9 18h6"/><path d="M10 22h4"/><path d="M12 2a7 7 0 0 0-4 12.7c.6.5 1 1.3 1 2.3h6c0-1 .4-1.8 1-2.3A7 7 0 0 0 12 2z"/>',
	"arrow": '<line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/>',
}

static var _cache: Dictionary = {}


## The icon [param icon_name] in [param color], [param px] pixels square.
static func get_icon(icon_name: String, color: Color, px: int = 16) -> Texture2D:
	var key := "%s/%s/%d" % [icon_name, color.to_html(), px]
	if _cache.has(key):
		return _cache[key]
	var hex := "#" + color.to_html(false)
	var body: String = SVG.get(icon_name, "").replace("currentColor", hex)
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="%s" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">%s</svg>' % [hex, body]
	var image := Image.new()
	image.load_svg_from_string(svg, px / 24.0)
	var texture := ImageTexture.create_from_image(image)
	_cache[key] = texture
	return texture
