class_name MenuBackdrop
extends CanvasLayer
## Slow-scrolling school skyline shared by the menu screens, with น็อต jogging
## along the bottom so the front page has some life in it.

var _layers: Array[TextureRect] = []
var _runner: Sprite2D
var _t := 0.0

func _ready() -> void:
	layer = -10
	var sky := TextureRect.new()
	sky.texture = load("res://assets/sprites/bg_sky.png")
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sky)

	for spec in [
		{"tex": "bg_school", "y": 62.0, "speed": 5.0, "h": 140.0, "mod": Color(0.75, 0.72, 0.9)},
		{"tex": "bg_trees", "y": 176.0, "speed": 12.0, "h": 70.0, "mod": Color(0.85, 0.9, 0.85)},
	]:
		var tr := TextureRect.new()
		tr.texture = load("res://assets/sprites/%s.png" % spec["tex"])
		tr.stretch_mode = TextureRect.STRETCH_TILE
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.size = Vector2(480 * 3, spec["h"])
		tr.position = Vector2(-480, spec["y"])
		tr.modulate = spec["mod"]
		tr.set_meta("speed", spec["speed"])
		tr.set_meta("base_y", spec["y"])
		add_child(tr)
		_layers.append(tr)

	var ground := ColorRect.new()
	ground.color = Color("2b2440")
	ground.position = Vector2(0, 238)
	ground.size = Vector2(480, 40)
	add_child(ground)

	_runner = Sprite2D.new()
	_runner.texture = load("res://assets/sprites/char_not.png")
	_runner.hframes = 11
	_runner.centered = false
	_runner.offset = Vector2(-8, -22)
	_runner.position = Vector2(-30, 246)
	_runner.scale = Vector2(1.6, 1.6)
	add_child(_runner)

	# a dark scrim so menu text always stays readable over the art
	var scrim := ColorRect.new()
	scrim.color = Color(0.06, 0.05, 0.10, 0.55)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

func _process(delta: float) -> void:
	_t += delta
	for l in _layers:
		l.position.x = -480 - fmod(_t * float(l.get_meta("speed")), 480.0)
	_runner.frame = 2 + (int(_t * 10.0) % 4)
	_runner.position.x = fmod(_t * 66.0, 560.0) - 40.0
	_runner.position.y = 246.0 + sin(_t * 10.0) * 1.0
