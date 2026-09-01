class_name Entities
extends RefCounted
## Small world objects built in code: pickups, hiding spots, doors, the goal
## marker and the rolling PE balls. Grouping the tiny classes here keeps the
## scripts folder readable — each one is only a handful of lines.


## ---------------------------------------------------------------- pickup ---
class Pickup extends Area2D:
	signal taken(id: String)
	var id := "coin"
	var _t := 0.0
	var _base_y := 0.0

	func _init(item_id: String) -> void:
		id = item_id

	func _ready() -> void:
		collision_layer = 8
		collision_mask = 2
		monitoring = true
		var s := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = 11.0
		s.shape = c
		add_child(s)

		var spr := Sprite2D.new()
		spr.texture = load("res://assets/sprites/%s.png" % Game.ITEMS[id]["icon"])
		add_child(spr)

		# a soft glow so items read against busy tiles
		var halo := Sprite2D.new()
		halo.texture = load("res://assets/sprites/prop_safe_zone.png")
		halo.modulate = Color(1.0, 0.95, 0.6, 0.16)
		halo.z_index = -1
		add_child(halo)

		_base_y = position.y
		body_entered.connect(_on_body)

	func _process(delta: float) -> void:
		_t += delta
		position.y = _base_y + sin(_t * 2.6) * 2.0

	func _on_body(body: Node2D) -> void:
		if body is Player:
			(body as Player).add_item(id)
			taken.emit(id)
			Sfx.play("pickup")
			Fader.toast("ได้รับ: %s" % Game.ITEMS[id]["name"], Color(1.0, 0.86, 0.45))
			queue_free()


## ------------------------------------------------------------- hide spot ---
class HideSpot extends Area2D:
	const ART := {
		"locker": "prop_locker",
		"desk":   "prop_desk",
		"bush":   "prop_bush",
		"table":  "prop_table",
	}
	var kind := "locker"
	var occupied := false
	var _spr: Sprite2D

	func _init(k: String) -> void:
		kind = k

	func _ready() -> void:
		add_to_group("hide_spot")
		collision_layer = 8
		collision_mask = 2
		var tex: Texture2D = load("res://assets/sprites/%s.png" % ART.get(kind, "prop_locker"))

		_spr = Sprite2D.new()
		_spr.texture = tex
		_spr.centered = false
		_spr.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height())
		add_child(_spr)

		# Lockers and bushes stand in front of the player; a desk or a canteen
		# table has to be drawn over him so crouching under it reads properly.
		_spr.z_index = 1 if kind in ["desk", "table"] else -1

		var s := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(maxf(tex.get_width(), 14), tex.get_height())
		s.shape = r
		s.position = Vector2(0, -tex.get_height() / 2.0)
		add_child(s)

	func set_occupied(v: bool) -> void:
		occupied = v
		_spr.modulate = Color(0.82, 0.86, 1.0) if v else Color.WHITE

	func label() -> String:
		match kind:
			"locker": return "ซ่อนในตู้ล็อกเกอร์"
			"desk":   return "มุดใต้โต๊ะ"
			"bush":   return "ซ่อนในพุ่มไม้"
			_:        return "ซ่อนใต้โต๊ะอาหาร"


## ------------------------------------------------------------------ door ---
class Doorway extends Area2D:
	signal opened
	var locked := true
	var _spr: Sprite2D
	var _blocker: StaticBody2D

	func _init(is_locked: bool) -> void:
		locked = is_locked

	func _ready() -> void:
		add_to_group("doorway")
		collision_layer = 8
		collision_mask = 2
		var tex: Texture2D = load("res://assets/sprites/prop_door_locked.png" if locked else "res://assets/sprites/prop_door.png")
		_spr = Sprite2D.new()
		_spr.texture = tex
		_spr.centered = false
		_spr.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height())
		add_child(_spr)

		var s := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(28, tex.get_height())
		s.shape = r
		s.position = Vector2(0, -tex.get_height() / 2.0)
		add_child(s)

		if locked:
			_blocker = StaticBody2D.new()
			_blocker.collision_layer = 1 | 32
			var bs := CollisionShape2D.new()
			var br := RectangleShape2D.new()
			br.size = Vector2(10, tex.get_height())
			bs.shape = br
			bs.position = Vector2(0, -tex.get_height() / 2.0)
			_blocker.add_child(bs)
			add_child(_blocker)

	func unlock() -> void:
		if not locked:
			return
		locked = false
		_spr.texture = load("res://assets/sprites/prop_door.png")
		if is_instance_valid(_blocker):
			_blocker.queue_free()
		Sfx.play("unlock")
		opened.emit()


## ------------------------------------------------------------------ goal ---
class GoalZone extends Area2D:
	signal player_entered
	signal player_exited
	var inside := false
	var _t := 0.0
	var _spr: Sprite2D

	func _ready() -> void:
		collision_layer = 8
		collision_mask = 2
		var s := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(40, 40)
		s.shape = r
		s.position = Vector2(0, -20)
		add_child(s)

		_spr = Sprite2D.new()
		_spr.texture = load("res://assets/sprites/prop_safe_zone.png")
		_spr.position = Vector2(0, -22)
		_spr.modulate = Color(0.55, 1.0, 0.70, 0.85)
		add_child(_spr)

		body_entered.connect(func(b): if b is Player: inside = true; player_entered.emit())
		body_exited.connect(func(b): if b is Player: inside = false; player_exited.emit())

	func _process(delta: float) -> void:
		_t += delta
		var pulse := 0.85 + sin(_t * 3.2) * 0.15
		_spr.scale = Vector2.ONE * pulse
		_spr.modulate.a = 0.55 + sin(_t * 3.2) * 0.25


## ------------------------------------------------------- rolling PE ball ---
class Ball extends Area2D:
	var speed := 60.0
	var x_min := 0.0
	var x_max := 0.0
	var dir := 1
	var _spr: Sprite2D
	var _t := 0.0

	func _init(smin: float, smax: float, spd: float) -> void:
		x_min = smin
		x_max = smax
		speed = spd

	func _ready() -> void:
		collision_layer = 16
		collision_mask = 2
		var s := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = 7.0
		s.shape = c
		s.position = Vector2(0, -7)
		add_child(s)

		_spr = Sprite2D.new()
		_spr.texture = load("res://assets/sprites/item_coin.png")
		_spr.modulate = Color(1.0, 0.55, 0.35)
		_spr.position = Vector2(0, -7)
		add_child(_spr)

		body_entered.connect(_on_hit)

	func _physics_process(delta: float) -> void:
		position.x += dir * speed * delta
		if position.x > x_max:
			position.x = x_max
			dir = -1
		elif position.x < x_min:
			position.x = x_min
			dir = 1
		_t += delta
		_spr.rotation += dir * speed * delta * 0.06

	func _on_hit(body: Node2D) -> void:
		if body is Player:
			var p := body as Player
			p.stun(1.1)
			Fader.toast("โดนลูกบอล! เสียงดังไปทั่วสนาม", Color(1.0, 0.6, 0.5))


## ------------------------------------------- expanding ring for noise fx ---
class NoiseRing extends Node2D:
	var radius := 40.0
	var _t := 0.0

	func _init(r: float) -> void:
		radius = r

	func _process(delta: float) -> void:
		_t += delta
		if _t > 0.45:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k := _t / 0.45
		draw_arc(Vector2.ZERO, radius * k, 0.0, TAU, 28,
			Color(1.0, 0.95, 0.7, 0.5 * (1.0 - k)), 1.5)
