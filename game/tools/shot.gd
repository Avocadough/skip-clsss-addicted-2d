extends SceneTree
## Dev helper: boots each scene, lets it run for a moment (optionally holding
## "walk right" so the camera moves off the spawn point) and writes a PNG.
##   Godot.exe --path game --script res://tools/shot.gd --resolution 960x540

var _queue: Array = []
var _wait := 0.0
var _current: Node = null
var _out := ""
var _hold := false
var _shots := 0

func _initialize() -> void:
	_queue = [
		{"scene": "res://scenes/main_menu.tscn", "out": "shot_menu.png", "wait": 0.7, "hold": false},
		{"scene": "res://scenes/level_select.tscn", "out": "shot_select.png", "wait": 0.7, "hold": false},
		{"scene": "res://scenes/level.tscn", "out": "shot_lv1.png", "wait": 6.0, "hold": true, "level": 1},
		{"scene": "res://scenes/level.tscn", "out": "shot_lv2.png", "wait": 6.0, "hold": true, "level": 2},
		{"scene": "res://scenes/level.tscn", "out": "shot_lv3.png", "wait": 6.0, "hold": true, "level": 3},
		{"scene": "res://scenes/level.tscn", "out": "shot_lv4.png", "wait": 6.0, "hold": true, "level": 4},
		{"scene": "res://scenes/level.tscn", "out": "shot_lv5.png", "wait": 6.0, "hold": true, "level": 5},
	]
	_next()

func _next() -> void:
	if _current != null:
		if _hold:
			Input.action_release("move_right")
		_current.queue_free()
		_current = null
	if _queue.is_empty():
		print("captured %d screenshots" % _shots)
		quit()
		return
	var job: Dictionary = _queue.pop_front()
	if job.has("level"):
		root.get_node("Game").current_level = job["level"]
	_current = load(job["scene"]).instantiate()
	root.add_child(_current)
	_out = job["out"]
	_wait = job["wait"]
	_hold = job["hold"]
	if _hold:
		Input.action_press("move_right")

func _process(_delta: float) -> bool:
	if _current == null:
		return false
	_wait -= _delta
	if _wait > 0.0:
		return false
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://shots/" + _out))
	print("  ", _out)
	_shots += 1
	_next()
	return false
