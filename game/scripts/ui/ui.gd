class_name UI
extends RefCounted
## Shared look-and-feel helpers. Everything is built in code so the whole game
## has one panel style, one font and one palette.

const FONT_PATH := "res://assets/fonts/NotoSansThai-VF.ttf"

const INK      := Color("241f31")
const INK_SOFT := Color("332b45")
const CREAM    := Color("f2e2b6")
const WHITE    := Color("f5f1e6")
const PURPLE   := Color("b6a6e0")
const PINK     := Color("f0b8c8")
const GREEN    := Color("8fc99a")
const RED      := Color("e0776f")
const YELLOW   := Color("f2d06b")
const BLUEGRAY := Color("7d94b5")

static func font() -> Font:
	return load(FONT_PATH)

static func font_bold() -> Font:
	var fv := FontVariation.new()
	fv.base_font = load(FONT_PATH)
	fv.variation_embolden = 0.55
	return fv

static func label(text: String, size: int = 14, color: Color = WHITE, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font_bold() if bold else font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", 5)
	return l

static func panel(bg: Color = Color(0.09, 0.075, 0.13, 0.92), border: Color = CREAM) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", panel_style(bg, border))
	return p

## The game is laid out for a 480x270 design viewport, so panel padding is
## deliberately tight — `mv` in particular, since vertical space is what runs
## out first on the menu screens.
static func panel_style(bg: Color, border: Color, width: int = 2,
		mh: int = 10, mv: int = 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.content_margin_left = mh
	sb.content_margin_right = mh
	sb.content_margin_top = mv
	sb.content_margin_bottom = mv
	return sb

static func button(text: String, size: int = 15) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", font_bold())
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", CREAM)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", PURPLE)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(0.45, 0.42, 0.52))
	b.add_theme_stylebox_override("normal", panel_style(Color(0.13, 0.11, 0.19, 0.95), Color(0.45, 0.40, 0.58), 2, 10, 3))
	b.add_theme_stylebox_override("hover", panel_style(Color(0.22, 0.18, 0.31, 0.98), CREAM, 2, 10, 3))
	b.add_theme_stylebox_override("pressed", panel_style(Color(0.10, 0.09, 0.15, 1.0), PURPLE, 2, 10, 3))
	b.add_theme_stylebox_override("focus", panel_style(Color(0, 0, 0, 0), CREAM, 2, 10, 3))
	b.add_theme_stylebox_override("disabled", panel_style(Color(0.11, 0.10, 0.14, 0.8), Color(0.30, 0.28, 0.35), 2, 10, 3))
	b.custom_minimum_size.y = size + 13
	b.mouse_entered.connect(func(): Sfx.play("move"))
	b.pressed.connect(func(): Sfx.play("click"))
	return b

static func icon(name: String, size: int = 16) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load("res://assets/sprites/%s.png" % name)
	t.custom_minimum_size = Vector2(size, size)
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return t

static func spacer(h: float = 8.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = h
	return c

## Rank badge colour used by the results screen and the level select.
static func rank_color(rank: String) -> Color:
	match rank:
		"S": return YELLOW
		"A": return GREEN
		"B": return BLUEGRAY
		_:   return Color(0.72, 0.68, 0.78)

## Names a node and marks it reachable as %Name from the scene root, so a
## script can still find it after someone moves it about in the editor.
static func key(node: Node, node_name: String) -> Node:
	node.name = node_name
	node.unique_name_in_owner = true
	return node
