class_name MenuBackdrop
extends CanvasLayer
## Slow-scrolling school skyline shared by the menu screens, with น็อต jogging
## along the bottom so the front page has some life in it.
##
## Laid out in scenes/ui/backdrop.tscn; `build()` is what generated it.

@onready var _runner: Sprite2D = %Runner

var _layers: Array[TextureRect] = []
var _t := 0.0

func _ready() -> void:
	# The strips carry their own scroll speed, so adding another one in the
	# editor is enough — no code change needed.
	for c in get_children():
		if c is TextureRect and c.has_meta("speed"):
			_layers.append(c as TextureRect)

func _process(delta: float) -> void:
	_t += delta
	for l in _layers:
		l.position.x = -480 - fmod(_t * float(l.get_meta("speed")), 480.0)
	_runner.frame = 2 + (int(_t * 10.0) % 4)
	_runner.position.x = fmod(_t * 66.0, 560.0) - 40.0
	_runner.position.y = 246.0 + sin(_t * 10.0) * 1.0

# ===========================================================================
static func build() -> MenuBackdrop:
	var bd := MenuBackdrop.new()
	bd.name = "MenuBackdrop"
	bd.layer = -10

	var sky := TextureRect.new()
	sky.name = "Sky"
	sky.texture = load("res://assets/sprites/bg_sky.png")
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bd.add_child(sky)

	var i := 1
	for spec in [
		{"tex": "bg_school", "y": 62.0, "speed": 5.0, "h": 140.0, "mod": Color(0.75, 0.72, 0.9)},
		{"tex": "bg_trees", "y": 176.0, "speed": 12.0, "h": 70.0, "mod": Color(0.85, 0.9, 0.85)},
	]:
		var tr := TextureRect.new()
		tr.name = "Strip%d" % i
		tr.texture = load("res://assets/sprites/%s.png" % spec["tex"])
		tr.stretch_mode = TextureRect.STRETCH_TILE
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.size = Vector2(480 * 3, spec["h"])
		tr.position = Vector2(-480, spec["y"])
		tr.modulate = spec["mod"]
		tr.set_meta("speed", spec["speed"])
		bd.add_child(tr)
		i += 1

	var ground := ColorRect.new()
	ground.name = "Ground"
	ground.color = Color("2b2440")
	ground.position = Vector2(0, 238)
	ground.size = Vector2(480, 40)
	bd.add_child(ground)

	var runner := Sprite2D.new()
	UI.key(runner, "Runner")
	runner.texture = load("res://assets/sprites/char_not.png")
	runner.hframes = 11
	runner.centered = false
	runner.offset = Vector2(-8, -22)
	runner.position = Vector2(-30, 246)
	runner.scale = Vector2(1.6, 1.6)
	bd.add_child(runner)

	# a dark scrim so menu text always stays readable over the art
	var scrim := ColorRect.new()
	scrim.name = "Scrim"
	scrim.color = Color(0.06, 0.05, 0.10, 0.55)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bd.add_child(scrim)
	return bd
