extends Node2D
## Builds a stage from LevelData and runs the whole gameplay loop: the
## countdown to the bell, the suspicion meter, item use, hiding, and the
## win/lose conditions from section 4.3 of the design document.

enum Phase { PLAY, WON, LOST }

const TILE := 16
# atlas column of each tile in assets/sprites/tiles.png
const T_FLOOR_TOP := 0
const T_FLOOR_FILL := 1
const T_WALL := 2
const T_WALL_TOP := 3
const T_PLATFORM := 4
const T_LADDER := 5
const T_BG_WALL := 6
const T_BG_WINDOW := 7
const T_BG_TILE := 8
const T_GRASS := 9
const T_DIRT := 10
const T_FENCE := 11

## What each setting looks like. `layers` are parallax strips drawn behind the
## world, slowest first; `factor` is how much of the camera's motion they take.
## Indoor stages leave their upper wall unpainted so the strip shows through.
const THEMES := {
	"hallway": {
		"outdoor": false, "base": "2b2440",
		"layers": [{"tex": "bg_hallway_deco", "y": 14.0, "factor": 0.30, "h": 160.0}],
		"motes": 26, "mote_tex": "fx_mote", "mote_tint": Color(1.0, 0.95, 0.8, 0.5),
	},
	"cafeteria": {
		"outdoor": false, "base": "35291f",
		"layers": [{"tex": "bg_cafeteria_deco", "y": 8.0, "factor": 0.30, "h": 160.0}],
		"motes": 20, "mote_tex": "fx_mote", "mote_tint": Color(1.0, 0.85, 0.6, 0.45),
	},
	"library": {
		"outdoor": false, "base": "241f18",
		"layers": [{"tex": "bg_library_deco", "y": 6.0, "factor": 0.30, "h": 160.0}],
		"motes": 34, "mote_tex": "fx_mote", "mote_tint": Color(1.0, 0.9, 0.65, 0.55),
	},
	"field": {
		"outdoor": true, "base": "8cc4e0",
		"layers": [
			{"tex": "bg_field_sky", "y": 0.0, "factor": 0.04, "h": 270.0},
			{"tex": "bg_field_far", "y": 56.0, "factor": 0.24, "h": 140.0},
			{"tex": "bg_field_trees", "y": 146.0, "factor": 0.52, "h": 70.0},
		],
		"clouds": 5, "motes": 14, "mote_tex": "fx_leaf", "mote_tint": Color(1, 1, 1, 0.9),
	},
	"gate": {
		"outdoor": true, "base": "6b4a7a",
		"layers": [
			{"tex": "bg_gate_sky", "y": 0.0, "factor": 0.04, "h": 270.0},
			{"tex": "bg_gate_far", "y": 56.0, "factor": 0.24, "h": 140.0},
			{"tex": "bg_gate_trees", "y": 146.0, "factor": 0.52, "h": 70.0},
		],
		"clouds": 4, "motes": 16, "mote_tex": "fx_leaf", "mote_tint": Color(0.9, 0.8, 0.6, 0.85),
	},
}

var data: Dictionary
var theme: Dictionary
var outdoor := false
var phase: Phase = Phase.PLAY

var player: Player
var hud: Hud
var camera: Camera2D
var goal: Entities.GoalZone

var suspicion := 0.0
var time_left := 0.0
var time_total := 0.0
var seen_count := 0
var in_dialogue := false

var _solid_cells := {}
var _solid_layer: TileMapLayer
var _bg_layer: TileMapLayer
var _entities: Node2D
var _bg_nodes: Array[Control] = []
var _bg_canvas: CanvasLayer
var _fx_canvas: CanvasLayer
var _clouds: Array[Sprite2D] = []
var _motes: Array[Sprite2D] = []
var _amb_t := 0.0
var _overlay: CanvasLayer
var _dialogue_cd := 0.0
var _bell_played := false

# ===========================================================================
func _ready() -> void:
	data = LevelData.get_level(Game.current_level)
	theme = THEMES.get(data["theme"], THEMES["hallway"])
	outdoor = theme["outdoor"]
	time_total = data["time"]
	time_left = time_total
	Game.reset_run()

	_build_background()
	_build_tiles()
	_entities = Node2D.new()
	add_child(_entities)
	_spawn_player()
	_spawn_world()
	_build_camera()

	hud = Hud.new()
	add_child(hud)
	hud.set_level_info(data["num"], data["name"])
	hud.show_objective(data["goal_text"], data["hint"])
	hud.update_inventory(player.inventory, player.selected)
	hud.update_suspicion(0.0)

	Sfx.play_music()

# ---------------------------------------------------------------- tileset --
func _make_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer(0)
	ts.set_physics_layer_collision_layer(0, 1)

	var src := TileSetAtlasSource.new()
	src.texture = load("res://assets/sprites/tiles_%s.png" % data["theme"])
	src.texture_region_size = Vector2i(TILE, TILE)
	for i in 12:
		src.create_tile(Vector2i(i, 0))
	ts.add_source(src, 0)

	var full := PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)])
	for i in [T_FLOOR_TOP, T_FLOOR_FILL, T_WALL, T_WALL_TOP, T_GRASS, T_DIRT]:
		var td := src.get_tile_data(Vector2i(i, 0), 0)
		td.add_collision_polygon(0)
		td.set_collision_polygon_points(0, 0, full)

	# one-way ledge: only the top 5px collides, and only from above
	var thin := PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, -3), Vector2(-8, -3)])
	var tdp := src.get_tile_data(Vector2i(T_PLATFORM, 0), 0)
	tdp.add_collision_polygon(0)
	tdp.set_collision_polygon_points(0, 0, thin)
	tdp.set_collision_polygon_one_way(0, 0, true)
	return ts

func _build_tiles() -> void:
	var ts := _make_tileset()
	var W: int = data["width"]
	var H: int = data["height"]

	_bg_layer = TileMapLayer.new()
	_bg_layer.tile_set = ts
	_bg_layer.z_index = -6
	# Only ever painted with wall / window / ladder / fence tiles, and none of
	# those define a collision polygon, so this layer is decoration by nature.
	add_child(_bg_layer)

	_solid_layer = TileMapLayer.new()
	_solid_layer.tile_set = ts
	_solid_layer.z_index = -2
	add_child(_solid_layer)

	# Indoor stages tile only the wainscot band along the bottom. The wall
	# above it is left bare on purpose so the parallax strip behind the world
	# — bookcases, a serving counter, a row of classroom doors — shows through
	# and each interior reads as its own room.
	if not outdoor:
		var wainscot: int = H - 6      # a low dado, so most of the backdrop shows
		for y in range(wainscot, H):
			for x in range(1, W - 1):
				_bg_layer.set_cell(Vector2i(x, y), 0, Vector2i(T_BG_TILE, 0))
		for w in data.get("windows", []):
			for y in range(w[1], w[1] + w[3]):
				for x in range(w[0], w[0] + w[2]):
					_bg_layer.set_cell(Vector2i(x, y), 0, Vector2i(T_BG_WINDOW, 0))

	# collect every solid cell first so the "is this the surface?" test is cheap
	for r in data["solids"]:
		for y in range(r[1], r[1] + r[3]):
			for x in range(r[0], r[0] + r[2]):
				_solid_cells[Vector2i(x, y)] = true

	for cell in _solid_cells:
		var above := Vector2i(cell.x, cell.y - 1)
		var is_surface := not _solid_cells.has(above)
		var t: int
		if outdoor:
			t = T_GRASS if is_surface else T_DIRT
		else:
			t = T_FLOOR_TOP if is_surface else T_FLOOR_FILL
		_solid_layer.set_cell(cell, 0, Vector2i(t, 0))

	for p in data.get("platforms", []):
		for x in range(p[0], p[0] + p[2]):
			var c := Vector2i(x, p[1])
			if not _solid_cells.has(c):
				_solid_layer.set_cell(c, 0, Vector2i(T_PLATFORM, 0))

	for l in data.get("ladders", []):
		var is_fence: bool = l.size() > 3 and l[3] == "fence"
		var art := T_FENCE if is_fence else T_LADDER
		for y in range(l[1], l[1] + l[2]):
			_bg_layer.set_cell(Vector2i(l[0], y), 0, Vector2i(art, 0))
		_add_ladder_area(l[0], l[1], l[2])

func _add_ladder_area(tx: int, ty: int, h: int) -> void:
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	a.position = Vector2(tx * TILE + TILE / 2.0, (ty + h / 2.0) * TILE)
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(TILE - 2, h * TILE)
	s.shape = r
	a.add_child(s)
	a.body_entered.connect(func(b): if b is Player: (b as Player).ladders_touching += 1)
	a.body_exited.connect(func(b):
		if b is Player:
			var p := b as Player
			p.ladders_touching = maxi(0, p.ladders_touching - 1))
	add_child(a)

# ------------------------------------------------------------- background --
func _build_background() -> void:
	_bg_canvas = CanvasLayer.new()
	_bg_canvas.layer = -10
	add_child(_bg_canvas)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(theme["base"])
	_bg_canvas.add_child(backdrop)

	for spec in theme["layers"]:
		var tr := TextureRect.new()
		tr.texture = load("res://assets/sprites/%s.png" % spec["tex"])
		tr.stretch_mode = TextureRect.STRETCH_TILE
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.size = Vector2(480 * 3, spec["h"])
		tr.position = Vector2(-480, spec["y"])
		tr.set_meta("factor", spec["factor"])
		tr.set_meta("base_y", spec["y"])
		_bg_canvas.add_child(tr)
		_bg_nodes.append(tr)

	_build_ambient()

## Clouds drifting across the sky outdoors, dust turning in the light indoors.
## Both live in canvas space and simply wrap, which costs nothing and gives the
## stages a bit of motion even when the player is standing still.
func _build_ambient() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = data["num"] * 7919

	for i in int(theme.get("clouds", 0)):
		var c := Sprite2D.new()
		c.texture = load("res://assets/sprites/cloud_%s.png" % ["a", "b", "c"][i % 3])
		c.position = Vector2(rng.randf_range(0, 480), rng.randf_range(18, 96))
		c.modulate = Color(1, 1, 1, rng.randf_range(0.45, 0.8))
		c.set_meta("speed", rng.randf_range(3.0, 9.0))
		_bg_canvas.add_child(c)
		_clouds.append(c)

	_fx_canvas = CanvasLayer.new()
	_fx_canvas.layer = 5                    # over the world, under the HUD
	add_child(_fx_canvas)
	var tex: Texture2D = load("res://assets/sprites/%s.png" % theme.get("mote_tex", "fx_mote"))
	for i in int(theme.get("motes", 0)):
		var m := Sprite2D.new()
		m.texture = tex
		m.position = Vector2(rng.randf_range(0, 480), rng.randf_range(0, 270))
		m.modulate = theme.get("mote_tint", Color(1, 1, 1, 0.5))
		m.set_meta("vx", rng.randf_range(-9.0, 9.0) if not outdoor else rng.randf_range(-26.0, -9.0))
		m.set_meta("vy", rng.randf_range(3.0, 11.0))
		m.set_meta("phase", rng.randf_range(0.0, TAU))
		_fx_canvas.add_child(m)
		_motes.append(m)

func _update_background(delta: float) -> void:
	if camera == null:
		return
	var cam := camera.get_screen_center_position()
	for n in _bg_nodes:
		var f: float = n.get_meta("factor")
		n.position.x = -480 - fmod(cam.x * f, 480.0)
		n.position.y = float(n.get_meta("base_y")) - (cam.y - 135.0) * f * 0.5

	_amb_t += delta
	for c in _clouds:
		c.position.x -= float(c.get_meta("speed")) * delta
		if c.position.x < -90.0:
			c.position.x = 500.0
	for m in _motes:
		m.position.x += float(m.get_meta("vx")) * delta
		m.position.y += float(m.get_meta("vy")) * delta
		# a slow sideways sway so they drift rather than fall in straight lines
		m.position.x += sin(_amb_t * 0.8 + float(m.get_meta("phase"))) * 6.0 * delta
		if m.position.y > 278.0:
			m.position.y = -8.0
			m.position.x = randf_range(0.0, 480.0)
		if m.position.x < -8.0:
			m.position.x = 486.0
		elif m.position.x > 486.0:
			m.position.x = -8.0

# ----------------------------------------------------------------- spawns --
func _spawn_player() -> void:
	player = Player.new()
	player.position = _tile_pos(data["spawn"])
	player.noise_mult = data.get("noise_mult", 1.0)
	player.noise_made.connect(_on_noise)
	player.item_used.connect(_on_item_used)
	player.inventory_changed.connect(func(): hud.update_inventory(player.inventory, player.selected))
	add_child(player)

func _spawn_world() -> void:
	for cfg in data.get("npcs", []):
		var n := Npc.new()
		n.setup(cfg["type"], cfg["patrol"][0] * TILE + 8.0, cfg["patrol"][1] * TILE + 8.0)
		n.position = _tile_pos([cfg["x"], cfg["y"]])
		n.set_player(player)
		n.caught.connect(_on_caught)
		n.confront.connect(_on_confront)
		_entities.add_child(n)

	for cfg in data.get("cameras", []):
		var c := Cctv.new()
		c.setup(cfg)
		c.position = _center_pos([cfg["x"], cfg["y"]])
		c.set_player(player)
		_entities.add_child(c)

	for cfg in data.get("items", []):
		var p := Entities.Pickup.new(cfg["id"])
		p.position = _center_pos([cfg["x"], cfg["y"]])
		_entities.add_child(p)

	for cfg in data.get("hides", []):
		var h := Entities.HideSpot.new(cfg["type"])
		h.position = _tile_pos([cfg["x"], cfg["y"]])
		_entities.add_child(h)

	for cfg in data.get("doors", []):
		var d := Entities.Doorway.new(cfg.get("locked", true))
		d.position = _tile_pos([cfg["x"], cfg["y"]])
		_entities.add_child(d)

	for cfg in data.get("balls", []):
		var b := Entities.Ball.new(cfg["range"][0] * TILE, cfg["range"][1] * TILE, cfg["speed"])
		b.position = _tile_pos([cfg["x"], cfg["y"]])
		_entities.add_child(b)

	for cfg in data.get("props", []):
		var tex: Texture2D = load("res://assets/sprites/%s.png" % cfg["name"])
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height())
		s.position = _tile_pos([cfg["x"], cfg["y"]])
		s.z_index = -3
		_entities.add_child(s)

	goal = Entities.GoalZone.new()
	goal.position = _tile_pos(data["goal"])
	_entities.add_child(goal)

	var cr: Array = data.get("classroom", [])
	if cr.size() == 4:
		var a := Area2D.new()
		a.collision_layer = 0
		a.collision_mask = 2
		a.position = Vector2((cr[0] + cr[2] / 2.0) * TILE, (cr[1] + cr[3] / 2.0) * TILE)
		var s2 := CollisionShape2D.new()
		var r2 := RectangleShape2D.new()
		r2.size = Vector2(cr[2] * TILE, cr[3] * TILE)
		s2.shape = r2
		a.add_child(s2)
		a.body_entered.connect(func(b):
			if b is Player and phase == Phase.PLAY:
				_lose("เดินกลับเข้าห้องเรียนก่อนเวลา — แพ้ทันที!"))
		add_child(a)

		var warn := UI.label("ห้องเรียน\n(ห้ามเข้า!)", 11, UI.RED, true)
		warn.position = Vector2(cr[0] * TILE, (cr[1] - 1) * TILE)
		warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(warn)

func _build_camera() -> void:
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = data["width"] * TILE
	camera.limit_bottom = data["height"] * TILE
	player.add_child(camera)
	camera.make_current()

func _tile_pos(t) -> Vector2:
	return Vector2(t[0] * TILE + TILE / 2.0, t[1] * TILE)

func _center_pos(t) -> Vector2:
	return Vector2(t[0] * TILE + TILE / 2.0, t[1] * TILE + TILE / 2.0)

# ===========================================================================
#  Game loop
# ===========================================================================
func _process(delta: float) -> void:
	_update_background(delta)
	if phase != Phase.PLAY:
		return
	if in_dialogue:
		return

	_dialogue_cd = maxf(0.0, _dialogue_cd - delta)

	# ------------------------------------------------------------- clock ---
	time_left = maxf(0.0, time_left - delta)
	hud.update_timer(time_left)
	if time_left <= 10.0 and not _bell_played:
		_bell_played = true
		Sfx.play("tick")
	if time_left <= 0.0:
		_on_bell()
		return

	_update_suspicion(delta)
	_update_prompt()

	# levels 1-4 finish the moment you reach the skip point
	if goal.inside and not data.get("must_survive", false):
		_win()

func _update_suspicion(delta: float) -> void:
	var watched := false
	var strength := 0.0
	for n in get_tree().get_nodes_in_group("npc"):
		var npc := n as Npc
		if npc == null:
			continue
		if npc.can_see_player:
			watched = true
			strength = maxf(strength, npc.awareness)
		if npc.state == Npc.State.ALERT:
			watched = true
			strength = maxf(strength, 1.0)
	for c in get_tree().get_nodes_in_group("cctv"):
		if (c as Cctv).sees:
			watched = true
			strength = maxf(strength, 0.8)

	if watched:
		suspicion = minf(100.0, suspicion + (16.0 + 26.0 * strength) * delta)
		if not player.is_hidden:
			hud.flash() if strength >= 1.0 and randf() < delta * 2.0 else null
	else:
		var recover := 22.0 if player.is_hidden else 11.0
		suspicion = maxf(0.0, suspicion - recover * delta)

	Game.run_peak_suspicion = maxf(Game.run_peak_suspicion, suspicion)
	hud.update_suspicion(suspicion)
	if suspicion >= 100.0:
		_lose("ค่าความสงสัยเต็ม 100% — ถูกส่งกลับเข้าห้องเรียน")

# --------------------------------------------------------------- prompts ---
func _update_prompt() -> void:
	if player.is_hidden:
		hud.set_prompt("กด E เพื่อออกจากที่ซ่อน")
		return
	var spot := _nearest_hide()
	if spot != null:
		hud.set_prompt("กด E — %s" % spot.label())
		return
	var door := _nearest_door()
	if door != null:
		if player.has_item("key"):
			hud.set_prompt("กด E — ใช้กุญแจเปิดประตู")
		else:
			hud.set_prompt("ประตูล็อกอยู่ — ต้องหากุญแจก่อน")
		return
	if data.get("must_survive", false) and goal.inside:
		hud.set_prompt("อยู่ใน Safe Zone แล้ว! รอกริ่งดัง...")
		return
	hud.set_prompt("")

func _nearest_hide() -> Entities.HideSpot:
	var best: Entities.HideSpot = null
	var bd := 26.0
	for h in get_tree().get_nodes_in_group("hide_spot"):
		var d := player.global_position.distance_to((h as Node2D).global_position)
		if d < bd:
			bd = d
			best = h
	return best

func _nearest_door() -> Entities.Doorway:
	var best: Entities.Doorway = null
	var bd := 30.0
	for d in get_tree().get_nodes_in_group("doorway"):
		var door := d as Entities.Doorway
		if not door.locked:
			continue
		var dist := player.global_position.distance_to(door.global_position)
		if dist < bd:
			bd = dist
			best = door
	return best

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and phase == Phase.PLAY and not in_dialogue:
		_show_pause()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("restart") and phase == Phase.PLAY:
		Fader.goto("res://scenes/level.tscn")
		return
	if not event.is_action_pressed("interact") or phase != Phase.PLAY or in_dialogue:
		return

	if player.is_hidden:
		player.set_hidden(false)
		for h in get_tree().get_nodes_in_group("hide_spot"):
			(h as Entities.HideSpot).set_occupied(false)
		Sfx.play("hide", 1.2)
		return
	var spot := _nearest_hide()
	if spot != null:
		player.set_hidden(true)
		spot.set_occupied(true)
		Sfx.play("hide")
		Fader.toast(spot.label() + " — ปลอดภัยชั่วคราว", UI.GREEN)
		return
	var door := _nearest_door()
	if door != null and player.has_item("key"):
		player.consume_item("key")
		door.unlock()
		Fader.toast("ปลดล็อกประตูแล้ว!", UI.YELLOW)

# ------------------------------------------------------------------ items --
func _on_item_used(id: String) -> void:
	match id:
		"nursecard":
			suspicion = maxf(0.0, suspicion - 35.0)
			player.consume_item(id)
			Sfx.play("pickup", 0.9)
			Fader.toast("ยื่นบัตรห้องพยาบาล — ความสงสัยลดลง", UI.GREEN)
		"coin":
			_throw_coin()
			player.consume_item(id)
		"hoodie":
			player.disguise(9.0)
			player.consume_item(id)
			Sfx.play("hide")
			Fader.toast("ใส่ฮู้ดปลอมตัว 9 วินาที!", UI.PURPLE)
		"wetsign":
			_place_wetsign()
			player.consume_item(id)
		"key":
			Fader.toast("เดินไปที่ประตูที่ล็อก แล้วกด E", UI.YELLOW)
		"notebook":
			Fader.toast("เก็บไว้ใช้ตอนหัวหน้าห้องเข้ามาถาม", UI.YELLOW)

func _throw_coin() -> void:
	var from := player.global_position + Vector2(0, -12)
	var to := from + Vector2(player.facing * 108.0, 0)
	var coin := Sprite2D.new()
	coin.texture = load("res://assets/sprites/item_coin.png")
	coin.position = from
	add_child(coin)
	Sfx.play("throw")

	var tw := create_tween()
	tw.tween_method(func(k: float):
		coin.position = from.lerp(to, k) + Vector2(0, -34.0 * sin(k * PI))
		coin.rotation = k * 12.0, 0.0, 1.0, 0.55)
	tw.tween_callback(func():
		Sfx.play("click", 1.4)
		_entities.add_child(_ring(to, 150.0))
		for n in get_tree().get_nodes_in_group("npc"):
			var npc := n as Npc
			if npc.global_position.distance_to(to) < 190.0:
				npc.distract(to)
		Fader.toast("เหรียญตกเสียงดัง — NPC เดินไปดู", UI.YELLOW)
		coin.queue_free())

func _place_wetsign() -> void:
	var sign_spr := Sprite2D.new()
	sign_spr.texture = load("res://assets/sprites/item_wetsign.png")
	sign_spr.position = player.global_position + Vector2(0, -8)
	_entities.add_child(sign_spr)
	Fader.toast("วางป้ายพื้นเปียก — NPC จะไม่เดินผ่าน", UI.YELLOW)

	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 4
	area.position = sign_spr.position
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(30, 34)
	s.shape = r
	area.add_child(s)
	area.body_entered.connect(func(b):
		if b is Npc:
			(b as Npc).block_path(3.0))
	_entities.add_child(area)

	# the sign only holds them off for a while
	var t := get_tree().create_timer(12.0)
	t.timeout.connect(func():
		if is_instance_valid(sign_spr): sign_spr.queue_free()
		if is_instance_valid(area): area.queue_free())

func _ring(pos: Vector2, radius: float) -> Node2D:
	var r := Entities.NoiseRing.new(radius)
	r.position = pos
	return r

func _on_noise(pos: Vector2, radius: float) -> void:
	_entities.add_child(_ring(pos, radius))
	for n in get_tree().get_nodes_in_group("npc"):
		(n as Npc).hear(pos, radius)

# ------------------------------------------------------------- resolution --
func _on_caught(npc: Npc) -> void:
	if phase != Phase.PLAY:
		return
	_lose("%s จับได้! โดนพากลับเข้าห้องเรียน" % npc.stats["label"])

func _on_confront(npc: Npc) -> void:
	if phase != Phase.PLAY or in_dialogue or _dialogue_cd > 0.0:
		return
	in_dialogue = true
	Game.run_times_seen += 1
	var dlg := ExcuseDialogue.new()
	add_child(dlg)
	dlg.open(npc.stats["label"], Game.EXCUSES.pick_random(), player.inventory)
	dlg.resolved.connect(func(good: bool, used: String):
		in_dialogue = false
		_dialogue_cd = 4.0
		if used != "":
			player.consume_item(used)
		if good:
			suspicion = maxf(0.0, suspicion - 22.0)
			npc.awareness = 0.0
			npc.state = Npc.State.PATROL
			npc.blocked_until = 0.0
			Fader.toast("รอดไปได้! หัวหน้าห้องเชื่อแล้ว", UI.GREEN)
		else:
			suspicion = minf(100.0, suspicion + 34.0)
			npc.awareness = 1.0
			Fader.toast("ตอบไม่เนียน — ความสงสัยพุ่ง!", UI.RED)
			if suspicion >= 100.0:
				_lose("ตอบข้ออ้างผิด ความสงสัยเต็ม — โดนพากลับห้อง"))

func _on_bell() -> void:
	Sfx.play("bell")
	if data.get("must_survive", false):
		if goal.inside:
			_win()
		else:
			_lose("กริ่งดังแล้วแต่ยังไม่ถึง Safe Zone — โดนจับได้")
	else:
		_lose("หมดเวลา! กริ่งเข้าเรียนดังก่อนที่จะหนีพ้น")

func _win() -> void:
	if phase != Phase.PLAY:
		return
	phase = Phase.WON
	player.freeze()
	Sfx.play("win")
	var rank := Game.rank_for(time_left, time_total, Game.run_times_seen, Game.run_peak_suspicion)
	Game.last_rank = rank
	Game.complete_level(data["num"], rank, time_left)

	var lines := [
		"เวลาที่เหลือ: %.1f วินาที" % time_left,
		"โดนเห็น: %d ครั้ง" % Game.run_times_seen,
		"ความสงสัยสูงสุด: %d%%" % int(Game.run_peak_suspicion),
	]
	var has_next: bool = data["num"] < LevelData.count()
	_show_overlay("โดดเรียนสำเร็จ!", "เกรดความเนียน: %s" % rank, lines,
		UI.rank_color(rank), has_next)

func _lose(reason: String) -> void:
	if phase != Phase.PLAY:
		return
	phase = Phase.LOST
	player.freeze()
	Sfx.play("lose")
	hud.flash()
	Game.last_fail_reason = reason
	_show_overlay("โดนจับได้!", reason, ["กด R เพื่อเริ่มด่านใหม่ทันที"], UI.RED, false)

# ---------------------------------------------------------------- overlays --
func _clear_overlay() -> void:
	Fader.clear_toast()
	if is_instance_valid(_overlay):
		_overlay.queue_free()
		_overlay = null

func _show_overlay(title: String, subtitle: String, lines: Array,
		accent: Color, show_next: bool) -> void:
	_clear_overlay()
	_overlay = CanvasLayer.new()
	_overlay.layer = 30
	_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.04, 0.08, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(dim)

	var box := UI.panel(Color(0.10, 0.085, 0.15, 0.98), accent)
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -180
	box.offset_right = 180
	box.offset_top = -118
	box.offset_bottom = 118
	_overlay.add_child(box)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	box.add_child(v)

	var t := UI.label(title, 24, accent, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)

	var st := UI.label(subtitle, 14, UI.WHITE, true)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	st.custom_minimum_size.x = 330
	v.add_child(st)
	v.add_child(UI.spacer(2))

	for line in lines:
		var l := UI.label(line, 13, Color(0.82, 0.79, 0.88))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	v.add_child(UI.spacer(6))

	if show_next:
		var nb := UI.button("ไปด่านต่อไป »", 15)
		nb.pressed.connect(func():
			Game.current_level = data["num"] + 1
			Fader.goto("res://scenes/level.tscn"))
		v.add_child(nb)

	var rb := UI.button("เล่นด่านนี้ใหม่", 14)
	rb.pressed.connect(func(): Fader.goto("res://scenes/level.tscn"))
	v.add_child(rb)

	var mb := UI.button("กลับไปเลือกด่าน", 14)
	mb.pressed.connect(func(): Fader.goto("res://scenes/level_select.tscn"))
	v.add_child(mb)

	for c in v.get_children():
		if c is Button:
			(c as Button).call_deferred("grab_focus")
			break

func _show_pause() -> void:
	get_tree().paused = true
	_clear_overlay()
	_overlay = CanvasLayer.new()
	_overlay.layer = 30
	_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.04, 0.08, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(dim)

	var box := UI.panel(Color(0.10, 0.085, 0.15, 0.98), UI.PURPLE)
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -160
	box.offset_right = 160
	box.offset_top = -120
	box.offset_bottom = 120
	_overlay.add_child(box)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	box.add_child(v)

	var t := UI.label("หยุดชั่วคราว", 22, UI.PURPLE, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var g := UI.label(data["goal_text"], 12, Color(0.82, 0.79, 0.88))
	g.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	g.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	g.custom_minimum_size.x = 290
	v.add_child(g)
	v.add_child(UI.spacer(4))

	var resume := UI.button("เล่นต่อ", 15)
	resume.pressed.connect(func():
		get_tree().paused = false
		_clear_overlay())
	v.add_child(resume)

	var restart := UI.button("เริ่มด่านนี้ใหม่", 14)
	restart.pressed.connect(func():
		get_tree().paused = false
		Fader.goto("res://scenes/level.tscn"))
	v.add_child(restart)

	var music := UI.button("เพลง: %s" % ("เปิด" if Game.music_on else "ปิด"), 14)
	music.pressed.connect(func():
		Sfx.set_music_enabled(not Game.music_on)
		music.text = "เพลง: %s" % ("เปิด" if Game.music_on else "ปิด"))
	v.add_child(music)

	var back := UI.button("กลับไปเลือกด่าน", 14)
	back.pressed.connect(func():
		get_tree().paused = false
		Fader.goto("res://scenes/level_select.tscn"))
	v.add_child(back)

	resume.call_deferred("grab_focus")
