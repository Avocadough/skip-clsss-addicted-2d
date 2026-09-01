class_name Player
extends CharacterBody2D
## น็อต — the student trying to skip class.
##
## The sprite's origin sits at his feet, and the whole 11-frame sheet is
## driven by hand (frame 0-1 idle, 2-5 walk, 6 jump, 7 fall, 8-9 crouch,
## 10 caught) rather than through an AnimationPlayer resource.

signal noise_made(pos: Vector2, radius: float)
signal item_used(id: String)
signal inventory_changed
signal hidden_changed(is_hidden: bool)

const WALK_SPEED := 74.0
const RUN_SPEED := 132.0
const CROUCH_SPEED := 40.0
const CLIMB_SPEED := 66.0
const ACCEL := 1100.0
const FRICTION := 1500.0
const AIR_ACCEL := 620.0
const JUMP_VELOCITY := -272.0
const MAX_FALL := 420.0
const COYOTE := 0.10
const JUMP_BUFFER := 0.12

const NOISE_RUN := 118.0
const NOISE_WALK := 58.0
const NOISE_LAND := 96.0

var sprite: Sprite2D
var _shape: CollisionShape2D
var _rect_stand := RectangleShape2D.new()
var _rect_crouch := RectangleShape2D.new()

var facing := 1
var crouching := false
var climbing := false
var is_hidden := false
var stun_time := 0.0
var disguise_time := 0.0
var ladders_touching := 0

var inventory: Array[String] = []
var selected := 0
var noise_mult := 1.0

var _coyote := 0.0
var _buffer := 0.0
var _anim_t := 0.0
var _step_t := 0.0
var _was_on_floor := true
var _frozen := false

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1

	_rect_stand.size = Vector2(10, 20)
	_rect_crouch.size = Vector2(10, 11)

	_shape = CollisionShape2D.new()
	_shape.shape = _rect_stand
	_shape.position = Vector2(0, -10)
	add_child(_shape)

	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/sprites/char_not.png")
	sprite.hframes = 11
	sprite.centered = false
	sprite.offset = Vector2(-8, -22)
	add_child(sprite)

func freeze() -> void:
	_frozen = true
	velocity = Vector2.ZERO

# ---------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if disguise_time > 0.0:
		disguise_time -= delta
		sprite.modulate = Color(0.80, 0.74, 0.95) if disguise_time > 0.0 else Color.WHITE

	if _frozen:
		sprite.frame = 10
		return

	if stun_time > 0.0:
		stun_time -= delta
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		velocity.y = minf(velocity.y + get_gravity().y * delta, MAX_FALL)
		move_and_slide()
		sprite.frame = 10
		sprite.rotation = sin(stun_time * 40.0) * 0.12
		return
	sprite.rotation = 0.0

	if is_hidden:
		velocity = Vector2.ZERO
		sprite.frame = 8
		return

	_handle_items()

	var dir := Input.get_axis("move_left", "move_right")
	var want_up := Input.is_action_pressed("move_up")
	var want_down := Input.is_action_pressed("move_down")

	# ------------------------------------------------------------- climbing --
	if ladders_touching > 0 and (want_up or want_down or climbing):
		if want_up or want_down:
			climbing = true
	else:
		climbing = false

	if climbing:
		velocity.y = (int(want_down) - int(want_up)) * CLIMB_SPEED
		velocity.x = dir * CLIMB_SPEED * 0.7
		if Input.is_action_just_pressed("jump"):
			climbing = false
			velocity.y = JUMP_VELOCITY * 0.8
			Sfx.play("jump")
		move_and_slide()
		_anim_t += delta * (4.0 if absf(velocity.y) > 4.0 else 0.0)
		sprite.frame = 2 + (int(_anim_t) % 4)
		_emit_steps(delta, NOISE_WALK * 0.5, 0.55)
		return

	# --------------------------------------------------------------- crouch --
	var want_crouch := want_down and is_on_floor()
	if crouching and not want_crouch and _can_stand():
		crouching = false
	elif want_crouch:
		crouching = true
	_shape.shape = _rect_crouch if crouching else _rect_stand
	_shape.position = Vector2(0, -5.5 if crouching else -10.0)

	# ------------------------------------------------------------ move/jump --
	var running := Input.is_action_pressed("run") and not crouching and is_on_floor()
	var target := dir * (CROUCH_SPEED if crouching else (RUN_SPEED if running else WALK_SPEED))
	var a := ACCEL if is_on_floor() else AIR_ACCEL
	if absf(dir) > 0.05:
		velocity.x = move_toward(velocity.x, target, a * delta)
		facing = 1 if dir > 0.0 else -1
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	_coyote = COYOTE if is_on_floor() else maxf(0.0, _coyote - delta)
	_buffer = JUMP_BUFFER if Input.is_action_just_pressed("jump") else maxf(0.0, _buffer - delta)
	if _buffer > 0.0 and _coyote > 0.0 and not crouching:
		velocity.y = JUMP_VELOCITY
		_coyote = 0.0
		_buffer = 0.0
		Sfx.play("jump")
		emit_noise(NOISE_WALK)
	# variable jump height
	if Input.is_action_just_released("jump") and velocity.y < JUMP_VELOCITY * 0.45:
		velocity.y = JUMP_VELOCITY * 0.45

	velocity.y = minf(velocity.y + get_gravity().y * delta, MAX_FALL)
	move_and_slide()

	if is_on_floor() and not _was_on_floor:
		Sfx.play("land", randf_range(0.94, 1.06))
		emit_noise(NOISE_LAND)
	_was_on_floor = is_on_floor()

	# ---------------------------------------------------------------- noise --
	if is_on_floor() and absf(velocity.x) > 6.0:
		if running:
			_emit_steps(delta, NOISE_RUN, 0.26)
		elif crouching:
			_emit_steps(delta, 0.0, 0.7)
		else:
			_emit_steps(delta, NOISE_WALK, 0.40)
	else:
		_step_t = 0.18

	_animate(delta, dir, running)

func _can_stand() -> bool:
	## Refuses to un-crouch while there is something directly overhead.
	var space := get_world_2d().direct_space_state
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = _rect_stand
	q.transform = Transform2D(0.0, global_position + Vector2(0, -10))
	q.collision_mask = 1
	q.exclude = [get_rid()]
	return space.intersect_shape(q, 1).is_empty()

func _animate(delta: float, dir: float, running: bool) -> void:
	# Sprite2D mirrors the frame inside its existing rect, so the offset must
	# stay put — shifting it here used to teleport him a whole frame sideways
	# every time he turned around.
	sprite.flip_h = facing < 0

	if not is_on_floor():
		sprite.frame = 6 if velocity.y < 0.0 else 7
		return
	if crouching:
		_anim_t += delta * (6.0 if absf(velocity.x) > 6.0 else 1.4)
		sprite.frame = 8 + (int(_anim_t) % 2)
		return
	if absf(velocity.x) > 8.0:
		_anim_t += delta * (11.0 if running else 7.0)
		sprite.frame = 2 + (int(_anim_t) % 4)
	else:
		_anim_t += delta * 1.7
		sprite.frame = int(_anim_t) % 2

func _emit_steps(delta: float, radius: float, period: float) -> void:
	_step_t -= delta
	if _step_t > 0.0:
		return
	_step_t = period
	if radius > 0.0:
		emit_noise(radius)
	Sfx.play("step", randf_range(0.9, 1.15), -6.0 if radius > NOISE_WALK else -12.0)

func emit_noise(radius: float) -> void:
	if radius <= 0.0:
		return
	noise_made.emit(global_position, radius * noise_mult)

# ---------------------------------------------------------------------------
func _handle_items() -> void:
	if inventory.is_empty():
		return
	if Input.is_action_just_pressed("cycle_item"):
		selected = (selected + 1) % inventory.size()
		Sfx.play("move")
		inventory_changed.emit()
	if Input.is_action_just_pressed("use_item"):
		var id := inventory[selected]
		item_used.emit(id)

func add_item(id: String) -> void:
	inventory.append(id)
	selected = inventory.size() - 1
	inventory_changed.emit()

func consume_selected() -> void:
	if selected < inventory.size():
		inventory.remove_at(selected)
	selected = clampi(selected, 0, maxi(0, inventory.size() - 1))
	inventory_changed.emit()

func has_item(id: String) -> bool:
	return inventory.has(id)

func consume_item(id: String) -> bool:
	var i := inventory.find(id)
	if i < 0:
		return false
	inventory.remove_at(i)
	selected = clampi(selected, 0, maxi(0, inventory.size() - 1))
	inventory_changed.emit()
	return true

func set_hidden(v: bool) -> void:
	is_hidden = v
	sprite.visible = not v
	hidden_changed.emit(v)

func stun(duration: float) -> void:
	if is_hidden or stun_time > 0.0:
		return
	stun_time = duration
	velocity = Vector2(-facing * 60.0, -110.0)
	emit_noise(NOISE_RUN)
	Sfx.play("land", 0.7)

func disguise(duration: float) -> void:
	disguise_time = duration
