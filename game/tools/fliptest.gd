extends SceneTree
## Measures where the player sprite actually lands on screen facing right vs
## facing left. Sprite2D mirrors a frame about the LEFT edge of its dest rect,
## so flip_h shifts the art by one frame width unless the offset compensates.
##   Godot.exe --path game --script res://tools/fliptest.gd --resolution 480x270

var _shots := 0
var _phase := 0
var _wait := 0.0
var _p: Node2D
var _root2d: Node2D

func _initialize() -> void:
	_root2d = Node2D.new()
	root.add_child(_root2d)

	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.9, 0.4)          # loud background = easy to threshold
	bg.size = Vector2(480, 270)
	var cl := CanvasLayer.new()
	cl.layer = -20
	cl.add_child(bg)
	_root2d.add_child(cl)

	_p = load("res://scripts/player.gd").new()
	_p.position = Vector2(240, 200)
	_root2d.add_child(_p)
	_p.freeze()          # no floor in this harness, so stop gravity dragging him off-screen
	_wait = 0.4

func _measure(tag: String) -> void:
	var img := root.get_texture().get_image()
	var minx := 9999
	var maxx := -1
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			# anything that is not the green backdrop is character pixels
			if not (c.g > 0.7 and c.r < 0.4):
				minx = mini(minx, x)
				maxx = maxi(maxx, x)
	var mid := (minx + maxx) / 2.0
	print("  %-14s  left=%3d  right=%3d  centre=%6.1f  (player x = 240)" % [tag, minx, maxx, mid])

func _process(delta: float) -> bool:
	_wait -= delta
	if _wait > 0.0:
		return false
	match _phase:
		0:
			_p.facing = 1
			_p.sprite.flip_h = false
			_p.sprite.offset.x = -8
			_wait = 0.15
			_phase = 1
		1:
			_measure("facing RIGHT")
			_p.facing = -1
			_p.sprite.flip_h = true
			_p.sprite.offset.x = 8
			_wait = 0.15
			_phase = 2
		2:
			_measure("facing LEFT  (offset +8, current)")
			_p.sprite.offset.x = -8
			_wait = 0.15
			_phase = 3
		3:
			_measure("facing LEFT  (offset -8, proposed)")
			print("\n  (centres should match; a gap of ~16 means the offset compensation is wrong)")
			quit()
	return false
