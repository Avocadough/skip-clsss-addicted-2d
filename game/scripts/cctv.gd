class_name Cctv
extends Node2D
## กล้องวงจรปิด — a sweeping vision cone bolted to the ceiling. It never
## chases you, it just raises suspicion fast and shouts for whoever is nearby.

signal seeing(delta: float)

const RAY_COUNT := 11

var base_angle := 90.0
var sweep := 45.0
var view_range := 92.0
var period := 4.5
var phase := 0.0

var _player: Player
var _cone: Polygon2D
var _lamp: Sprite2D
var _t := 0.0
var _angle := 90.0
var _alert_cooldown := 0.0
var sees := false

func setup(cfg: Dictionary) -> void:
	base_angle = cfg.get("angle", 90.0)
	sweep = cfg.get("sweep", 45.0)
	view_range = cfg.get("range", 92.0)
	period = cfg.get("period", 4.5)
	phase = cfg.get("phase", 0.0)

func _ready() -> void:
	add_to_group("cctv")
	_t = phase

	_cone = Polygon2D.new()
	_cone.color = Color(1.0, 0.45, 0.45, 0.14)
	_cone.z_index = -1
	add_child(_cone)

	var body := Sprite2D.new()
	body.texture = load("res://assets/sprites/prop_cctv.png")
	body.centered = true
	add_child(body)

	# blinking status light so a live camera reads at a glance
	_lamp = Sprite2D.new()
	_lamp.texture = load("res://assets/sprites/fx_alert.png")
	_lamp.position = Vector2(0, -16)
	_lamp.visible = false
	add_child(_lamp)

func set_player(p: Player) -> void:
	_player = p

func _physics_process(delta: float) -> void:
	_t += delta
	_angle = base_angle + sin(_t / maxf(period, 0.1) * TAU) * sweep
	_alert_cooldown = maxf(0.0, _alert_cooldown - delta)

	sees = _check_sight()
	if sees:
		seeing.emit(delta)
		if _alert_cooldown <= 0.0:
			_alert_cooldown = 2.4
			Sfx.play("alert", 1.4, -6.0)
			for n in get_tree().get_nodes_in_group("npc"):
				if n is Npc:
					(n as Npc).hear(_player.global_position, 190.0)
	_lamp.visible = sees
	_draw_cone()

func _check_sight() -> bool:
	if _player == null or _player.is_hidden:
		return false
	if _player.disguise_time > 0.0:
		return false            # the hoodie also fools the lens
	var target := _player.global_position + Vector2(0, -11)
	var to := target - global_position
	if to.length() > view_range:
		return false
	var forward := Vector2.from_angle(deg_to_rad(_angle))
	if absf(rad_to_deg(forward.angle_to(to))) > sweep * 0.5 + 12.0:
		return false
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(global_position, target, 1 | 32)
	return space.intersect_ray(q).is_empty()

func _draw_cone() -> void:
	var half := deg_to_rad(sweep * 0.5 + 12.0)
	var base := deg_to_rad(_angle)
	var space := get_world_2d().direct_space_state
	var pts := PackedVector2Array()
	pts.append(Vector2.ZERO)
	for i in RAY_COUNT:
		var a := base - half + (2.0 * half) * (float(i) / (RAY_COUNT - 1))
		var to := global_position + Vector2.from_angle(a) * view_range
		var q := PhysicsRayQueryParameters2D.create(global_position, to, 1 | 32)
		var hit := space.intersect_ray(q)
		var end: Vector2 = hit["position"] if hit.has("position") else to
		pts.append(end - global_position)
	_cone.polygon = pts
	_cone.color = Color(1.0, 0.30, 0.30, 0.36) if sees else Color(1.0, 0.50, 0.50, 0.19)
