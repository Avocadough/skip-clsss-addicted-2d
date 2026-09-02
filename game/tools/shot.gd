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
var _at := -1

func _initialize() -> void:
	_queue = [
		{"scene": "res://scenes/main_menu.tscn", "out": "shot_menu.png", "wait": 0.7, "hold": false},
		{"scene": "res://scenes/level_select.tscn", "out": "shot_select.png", "wait": 0.7, "hold": false},
		{"scene": "res://scenes/main_menu.tscn", "out": "shot_howto.png", "wait": 0.7, "hold": false, "call": "_show_how_to"},
		{"scene": "res://scenes/main_menu.tscn", "out": "shot_credits.png", "wait": 0.7, "hold": false, "call": "_show_credits"},
		{"scene": LevelData.scene_path(1), "out": "shot_lv1.png", "wait": 6.0, "hold": true, "level": 1},
		{"scene": LevelData.scene_path(2), "out": "shot_lv2.png", "wait": 6.0, "hold": true, "level": 2},
		{"scene": LevelData.scene_path(3), "out": "shot_lv3.png", "wait": 5.0, "hold": false, "level": 3},
		{"scene": LevelData.scene_path(3), "out": "shot_lv3_door.png", "wait": 5.0, "hold": false, "level": 3, "at": 55, "peace": true},
		{"scene": LevelData.scene_path(5), "out": "shot_lv5_gate.png", "wait": 5.0, "hold": false, "level": 5, "at": 53, "peace": true},
		{"scene": LevelData.scene_path(4), "out": "shot_lv4.png", "wait": 6.0, "hold": true, "level": 4},
		{"scene": LevelData.scene_path(5), "out": "shot_lv5.png", "wait": 6.0, "hold": true, "level": 5},
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
	if job.has("call"):
		_current.call(job["call"])
	if job.get("peace", false):
		# Clear the watchers so a framing shot can sit still without the stage
		# ending in an arrest before the capture.
		for group in ["npc", "cctv"]:
			for n in _current.get_tree().get_nodes_in_group(group):
				n.queue_free()
	_out = job["out"]
	_wait = job["wait"]
	_hold = job["hold"]
	_at = job.get("at", -1)
	if _hold:
		Input.action_press("move_right")

func _process(_delta: float) -> bool:
	if _current == null:
		return false
	# Park the player at a given tile so a specific part of a stage can be
	# framed — handy for checking a door or a ledge without playing to it.
	if _at >= 0 and _current != null and _current.get("player") != null:
		_current.player.global_position.x = _at * 16.0 + 8.0
	_wait -= _delta
	if _wait > 0.0:
		return false
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://shots/" + _out))
	print("  ", _out)
	_shots += 1
	_next()
	return false
