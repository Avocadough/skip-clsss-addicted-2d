class_name Npc
extends CharacterBody2D
## Patrolling watcher: teacher, class monitor, guard, librarian, coach or a
## background student. Implements the "Line of Sight" and "Noise System"
## rules — a real cone clipped against the walls, awareness that builds while
## you stand in it, and investigation of anything it hears.

signal caught(npc: Npc)
signal confront(npc: Npc)

enum State { PATROL, LOOK, INVESTIGATE, ALERT }

const STATS := {
	"teacher":   {"sprite": "char_teacher",   "speed": 30.0, "range": 108.0, "fov": 56.0, "see": 0.85, "hear": 1.0, "catch": "lose",     "label": "ครูประจำชั้น"},
	"monitor":   {"sprite": "char_monitor",   "speed": 44.0, "range": 84.0,  "fov": 64.0, "see": 0.70, "hear": 1.0, "catch": "dialogue", "label": "หัวหน้าห้อง"},
	"guard":     {"sprite": "char_guard",     "speed": 34.0, "range": 124.0, "fov": 50.0, "see": 1.05, "hear": 1.1, "catch": "lose",     "label": "รปภ."},
	"librarian": {"sprite": "char_librarian", "speed": 26.0, "range": 96.0,  "fov": 62.0, "see": 0.80, "hear": 1.7, "catch": "lose",     "label": "บรรณารักษ์"},
	"coach":     {"sprite": "char_coach",     "speed": 38.0, "range": 104.0, "fov": 54.0, "see": 0.90, "hear": 1.0, "catch": "lose",     "label": "ครูพละ"},
	"student":   {"sprite": "char_student",   "speed": 20.0, "range": 62.0,  "fov": 72.0, "see": 0.45, "hear": 0.8, "catch": "shout",    "label": "เพื่อนขี้ฟ้อง"},
	"student2":  {"sprite": "char_student2",  "speed": 22.0, "range": 62.0,  "fov": 72.0, "see": 0.45, "hear": 0.8, "catch": "shout",    "label": "เพื่อนขี้ฟ้อง"},
}

const EYE_HEIGHT := -15.0
const RAY_COUNT := 13
const CATCH_DIST := 15.0

var kind := "teacher"
var stats: Dictionary
var patrol_min := 0.0
var patrol_max := 0.0

var state: State = State.PATROL
var facing := 1
var awareness := 0.0                ## 0 = oblivious, 1 = fully alerted
var can_see_player := false
var blocked_until := 0.0            ## set by the wet-floor sign
var distract_pos := Vector2.ZERO

var _player: Player
var _cone: Polygon2D
var _sprite: Sprite2D
var _bubble: Sprite2D
var _look_timer := 0.0
var _lost_timer := 0.0
var _anim_t := 0.0
var _target := Vector2.ZERO
var _tex_alert: Texture2D
var _tex_question: Texture2D

func setup(type: String, pmin: float, pmax: float) -> void:
	kind = type
	stats = STATS.get(type, STATS["teacher"])
	patrol_min = pmin
	patrol_max = pmax

func _ready() -> void:
	add_to_group("npc")
	collision_layer = 4
	collision_mask = 1
	if stats.is_empty():
		stats = STATS["teacher"]

	var shape := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(10, 20)
	shape.shape = r
	shape.position = Vector2(0, -10)
	add_child(shape)

	_cone = Polygon2D.new()
	_cone.color = Color(1.0, 0.90, 0.45, 0.16)
	_cone.z_index = -1
	add_child(_cone)

	_sprite = Sprite2D.new()
	_sprite.texture = load("res://assets/sprites/%s.png" % stats["sprite"])
	_sprite.hframes = 11
	_sprite.centered = false
	_sprite.offset = Vector2(-8, -22)
	add_child(_sprite)

	_tex_alert = load("res://assets/sprites/fx_alert.png")
	_tex_question = load("res://assets/sprites/fx_question.png")
	_bubble = Sprite2D.new()
	_bubble.position = Vector2(0, -32)
	_bubble.visible = false
	add_child(_bubble)

	_target = global_position

func set_player(p: Player) -> void:
	_player = p

# ---------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if _player == null:
		return
	_sense(delta)
	_act(delta)
	_move(delta)
	_draw_cone()
	_update_bubble()

# ------------------------------------------------------------------ senses --
func _sense(delta: float) -> void:
	can_see_player = _check_sight()
	var gain := 0.0
	if can_see_player:
		var d := global_position.distance_to(_player.global_position)
		var near := clampf(1.0 - d / maxf(stats["range"], 1.0), 0.0, 1.0)
		gain = float(stats["see"]) * (0.45 + 0.85 * near)
		if _player.crouching:
			gain *= 0.55
		if _player.disguise_time > 0.0:
			gain *= 0.25
		awareness = minf(1.0, awareness + gain * delta)
	else:
		var decay := 0.34 if state == State.ALERT else 0.55
		awareness = maxf(0.0, awareness - decay * delta)

func _check_sight() -> bool:
	if _player == null or _player.is_hidden:
		return false
	var eye := global_position + Vector2(0, EYE_HEIGHT)
	var target := _player.global_position + Vector2(0, -11)
	var to := target - eye
	if to.length() > float(stats["range"]):
		return false
	var forward := Vector2(facing, 0)
	if absf(rad_to_deg(forward.angle_to(to))) > float(stats["fov"]) * 0.5:
		return false
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(eye, target, 1 | 32)
	q.exclude = [get_rid()]
	return space.intersect_ray(q).is_empty()

func hear(pos: Vector2, radius: float) -> void:
	if state == State.ALERT:
		return
	var d := global_position.distance_to(pos)
	if d > radius * float(stats["hear"]):
		return
	# Sound only pulls attention if it is not muffled by a whole wall.
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, EYE_HEIGHT), pos, 1)
	q.exclude = [get_rid()]
	var muffled := not space.intersect_ray(q).is_empty()
	awareness = minf(0.95, awareness + (0.20 if muffled else 0.42))
	_go_investigate(pos)

func distract(pos: Vector2) -> void:
	## Thrown-coin lure: pulls the NPC away even from a suspicious state.
	if state == State.ALERT:
		return
	_go_investigate(pos)
	_look_timer = 3.0

func block_path(duration: float) -> void:
	blocked_until = float(Time.get_ticks_msec()) / 1000.0 + duration

func _go_investigate(pos: Vector2) -> void:
	state = State.INVESTIGATE
	_target = Vector2(pos.x, global_position.y)
	_look_timer = 2.2

# ------------------------------------------------------------------- brain --
func _act(delta: float) -> void:
	match state:
		State.PATROL:
			_target.x = patrol_max if facing > 0 else patrol_min
			if absf(global_position.x - _target.x) < 4.0:
				state = State.LOOK
				_look_timer = randf_range(0.9, 1.7)
			if awareness >= 1.0:
				_enter_alert()
			elif awareness > 0.35:
				state = State.LOOK
				_look_timer = 0.8

		State.LOOK:
			_look_timer -= delta
			if awareness >= 1.0:
				_enter_alert()
			elif _look_timer <= 0.0:
				if can_see_player:
					_look_timer = 0.5
				else:
					facing = -facing if absf(global_position.x - _target.x) < 6.0 else facing
					state = State.PATROL

		State.INVESTIGATE:
			if awareness >= 1.0:
				_enter_alert()
			elif absf(global_position.x - _target.x) < 6.0:
				_look_timer -= delta
				if _look_timer <= 0.0:
					state = State.PATROL
					_target.x = clampf(global_position.x, patrol_min, patrol_max)

		State.ALERT:
			if can_see_player:
				_lost_timer = 0.0
				_target = _player.global_position
			else:
				_lost_timer += delta
				if _lost_timer > 2.6:
					state = State.INVESTIGATE
					_look_timer = 2.0
					awareness = 0.5
			if _within_catch_range():
				_do_catch()

func _enter_alert() -> void:
	if state == State.ALERT:
		return
	state = State.ALERT
	_lost_timer = 0.0
	Sfx.play("alert")

func _within_catch_range() -> bool:
	if _player.is_hidden:
		return false
	var d := _player.global_position - global_position
	return absf(d.x) < CATCH_DIST and absf(d.y) < 24.0

func _do_catch() -> void:
	match stats["catch"]:
		"dialogue":
			confront.emit(self)
		"shout":
			# A tattling classmate does not grab you, they yell for a teacher.
			awareness = 1.0
			Sfx.play("alert", 1.25)
			for other in get_tree().get_nodes_in_group("npc"):
				if other != self and other is Npc:
					(other as Npc).hear(global_position, 150.0)
			state = State.INVESTIGATE
			_look_timer = 1.5
		_:
			caught.emit(self)

# ------------------------------------------------------------------- move ---
func _move(delta: float) -> void:
	var speed := float(stats["speed"])
	var now := float(Time.get_ticks_msec()) / 1000.0
	var dir := 0.0

	if now < blocked_until:
		# stopped by the wet-floor sign: turn around and wait it out
		dir = 0.0
	else:
		match state:
			State.PATROL:
				dir = signf(_target.x - global_position.x)
			State.LOOK:
				dir = 0.0
			State.INVESTIGATE:
				dir = signf(_target.x - global_position.x) if absf(_target.x - global_position.x) > 6.0 else 0.0
				speed *= 1.25
			State.ALERT:
				dir = signf(_target.x - global_position.x) if absf(_target.x - global_position.x) > 6.0 else 0.0
				speed *= 1.75

	if absf(dir) > 0.01:
		facing = int(dir)
		velocity.x = dir * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		if state == State.LOOK and _look_timer > 0.0 and not can_see_player:
			# glance both ways while standing still
			if fmod(_look_timer, 0.9) < 0.45:
				facing = -1
			else:
				facing = 1

	# hop over the small crates and bleacher steps that dot the levels
	if is_on_wall() and is_on_floor() and absf(dir) > 0.01:
		velocity.y = -230.0

	velocity.y = minf(velocity.y + get_gravity().y * delta, 420.0)
	move_and_slide()
	_animate(delta)

func _animate(delta: float) -> void:
	_sprite.flip_h = facing < 0
	_sprite.offset.x = 8 if _sprite.flip_h else -8
	if absf(velocity.x) > 8.0:
		_anim_t += delta * (11.0 if state == State.ALERT else 7.0)
		_sprite.frame = 2 + (int(_anim_t) % 4)
	else:
		_anim_t += delta * 1.6
		_sprite.frame = 10 if state == State.ALERT else int(_anim_t) % 2

# ------------------------------------------------------------------- view ---
func _draw_cone() -> void:
	var eye_local := Vector2(0, EYE_HEIGHT)
	var eye := global_position + eye_local
	var range_px := float(stats["range"])
	var half := deg_to_rad(float(stats["fov"]) * 0.5)
	var base := 0.0 if facing > 0 else PI
	var space := get_world_2d().direct_space_state

	var pts := PackedVector2Array()
	pts.append(eye_local)
	for i in RAY_COUNT:
		var a := base - half + (2.0 * half) * (float(i) / (RAY_COUNT - 1))
		var dir := Vector2(cos(a), sin(a))
		var to := eye + dir * range_px
		var q := PhysicsRayQueryParameters2D.create(eye, to, 1 | 32)
		q.exclude = [get_rid()]
		var hit := space.intersect_ray(q)
		var end: Vector2 = hit["position"] if hit.has("position") else to
		pts.append(end - global_position)
	_cone.polygon = pts

	var c: Color
	if state == State.ALERT:
		c = Color(1.0, 0.32, 0.32, 0.36)
	elif awareness > 0.25:
		c = Color(1.0, 0.62, 0.28, 0.22 + awareness * 0.16)
	else:
		c = Color(1.0, 0.92, 0.5, 0.20)
	_cone.color = c

func _update_bubble() -> void:
	if state == State.ALERT:
		_bubble.texture = _tex_alert
		_bubble.visible = true
	elif awareness > 0.30 or state == State.INVESTIGATE:
		_bubble.texture = _tex_question
		_bubble.visible = true
	else:
		_bubble.visible = false
	if _bubble.visible:
		_bubble.position.y = -32 + sin(float(Time.get_ticks_msec()) / 160.0) * 1.5
