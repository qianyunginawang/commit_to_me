class_name UiStyle
extends RefCounted
## The "Modern Anime" look (see the Art Styles design canvas, style 02):
## glass-circuit frames with glowing cyan edges, slanted name banners, and
## three fonts: Anton (big names), Chakra Petch (labels and buttons) and
## Nunito (dialogue and body text).
##
## assets/theme.tres is built from this file by tools/build_theme.gd. Change
## colors or fonts here, then run:
##   godot --headless --path . -s tools/build_theme.gd

# --- Colors ---------------------------------------------------------------------

const NAVY := Color("#0b1426")         # page background
const NAVY_2 := Color("#16284a")       # raised surfaces
const GLASS := Color(0.063, 0.118, 0.212, 0.95)  # inside a glass frame
const CYAN := Color("#5fe0ff")          # glowing edges, highlights
const CYAN_PALE := Color("#9af0ff")
const PINK := Color("#ff3d7f")          # selected, new, the main accent
const GOLD := Color("#ffd166")          # day, "you are here"
const LILAC := Color("#a99bff")         # night
const DUSK := Color("#ff8a5c")
const INK := Color("#06121f")           # dark text on bright chips
const TEXT := Color("#ffffff")
const TEXT_SOFT := Color("#dff8ff")
const TEXT_MUTED := Color("#9cc6d8")
const TEXT_DIM := Color("#6f86a8")
const SHADOW := Color("#05070d")

## Slot chip colors in the HUD.
const SLOT_COLORS := {"day": GOLD, "dusk": DUSK, "night": LILAC}

# --- Fonts ------------------------------------------------------------------------

const ANTON := preload("res://assets/fonts/Anton-Regular.ttf")
const CHAKRA_BOLD := preload("res://assets/fonts/ChakraPetch-Bold.ttf")
const NUNITO := preload("res://assets/fonts/Nunito-Variable.ttf")

static var _fonts: Dictionary = {}


## Anton, for names and big titles.
static func display_font() -> Font:
	return _variation("display", ANTON, 0, 1)


## Chakra Petch Bold with wide letter spacing, for labels, chips and buttons.
static func label_font(spacing: int = 2) -> Font:
	return _variation("label_%d" % spacing, CHAKRA_BOLD, 0, spacing)


## Nunito, for dialogue and body text. weight is 200 to 1000.
static func body_font(weight: int = 500) -> Font:
	return _variation("body_%d" % weight, NUNITO, weight, 0)


static func _variation(key: String, base: Font, weight: int, spacing: int) -> Font:
	if _fonts.has(key):
		return _fonts[key]
	var font := FontVariation.new()
	font.base_font = base
	if weight > 0:
		font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	font.spacing_glyph = spacing
	_fonts[key] = font
	return font


# --- Style boxes -------------------------------------------------------------------

## A glass frame: dark navy inside, a thin glowing border, and cut corners.
static func glass_box(cut: int = 14, border: Color = Color(CYAN, 0.75), bg: Color = GLASS) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(cut)
	box.corner_detail = 1   # one segment per corner = a cut corner, not a round one
	box.anti_aliasing = true
	return box


## A button shape: top-left and bottom-right corners cut.
static func button_box(bg: Color, border: Color, cut: int = 8) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(1)
	box.corner_radius_top_left = cut
	box.corner_radius_bottom_right = cut
	box.corner_detail = 1
	box.set_content_margin_all(8)
	box.content_margin_left = 18
	box.content_margin_right = 18
	return box


## A slanted parallelogram (name banners, dialogue choices).
static func slanted_box(bg: Color, border: Color = Color.TRANSPARENT, slant: float = 0.25) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.skew = Vector2(slant, 0)
	if border.a > 0:
		box.border_color = border
		box.set_border_width_all(1)
	box.anti_aliasing = true
	return box


## A flat colored chip behind small caps text (language tags, "NEW").
static func chip_box(bg: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 1
	box.content_margin_bottom = 1
	return box


# --- Ready-made labels ---------------------------------------------------------------

## Small spaced-out caps label, like "HERE NOW" or "LESSONS HERE".
static func caption(text: String, color: Color = TEXT_MUTED, size: int = 11) -> Label:
	var label := Label.new()
	label.text = text.to_upper()
	label.add_theme_font_override("font", label_font(3))
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


## A slanted name banner with a hard shadow, like the dialogue speaker name.
static func banner(text: String, bg: Color = PINK, fg: Color = TEXT, size: int = 30) -> Label:
	var label := Label.new()
	style_banner(label, text, bg, fg, size)
	label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return label


## Turns an existing label into a banner. With max_width, the font shrinks
## until the text fits.
static func style_banner(label: Label, text: String, bg: Color = PINK, fg: Color = TEXT, size: int = 30, max_width: float = 0.0) -> void:
	label.text = text.to_upper()
	var font := display_font()
	if max_width > 0:
		while size > 14 and font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 42 > max_width:
			size -= 2
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", fg)
	var box := slanted_box(bg)
	box.shadow_color = SHADOW
	box.shadow_size = 1
	box.shadow_offset = Vector2(5, 5)
	box.content_margin_left = 20
	box.content_margin_right = 22
	box.content_margin_top = 0
	box.content_margin_bottom = 0
	label.add_theme_stylebox_override("normal", box)


## A small solid chip: dark caps text on a bright color.
static func chip(text: String, bg: Color = CYAN, fg: Color = INK, size: int = 11) -> Label:
	var label := Label.new()
	label.text = text.to_upper()
	label.add_theme_font_override("font", label_font(2))
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", fg)
	label.add_theme_stylebox_override("normal", chip_box(bg))
	label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return label
