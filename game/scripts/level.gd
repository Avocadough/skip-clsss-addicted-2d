extends Node2D
## Runs the gameplay loop of a stage: the countdown to the bell, the suspicion
## meter, item use, hiding, and the win/lose conditions from section 4.3 of
## the design document.
##
## The stage itself is not built here. Each one is laid out as a real scene in
## scenes/levels/level_NN.tscn — tiles, teachers, hiding spots and all — and
## this script picks it up and wires it together. Drag a new hiding spot into
## the 2D editor and it works with no code change: what this script looks for
## is the group each entity puts itself in, not a hard-coded list.

enum Phase { PLAY, WON, LOST }

const TILE := 16

## What drifts about in each setting. Dust and clouds are spawned at run time
## rather than baked, so a level scene stays readable in the Scene dock
## instead of carrying thirty identical mote nodes.
const AMBIENT := {
	"hallway":   {"clouds": 0, "motes": 26, "tex": "fx_mote", "tint": Color(1.0, 0.95, 0.80, 0.50)},
	"cafeteria": {"clouds": 0, "motes": 20, "tex": "fx_mote", "tint": Color(1.0, 0.85, 0.60, 0.45)},
	"library":   {"clouds": 0, "motes": 34, "tex": "fx_mote", "tint": Color(1.0, 0.90, 0.65, 0.55)},
	"field":     {"clouds": 5, "motes": 14, "tex": "fx_leaf", "tint": Color(1.0, 1.0, 1.0, 0.90)},
	"gate":      {"clouds": 4, "motes": 16, "tex": "fx_leaf", "tint": Color(0.9, 0.80, 0.60, 0.85)},
}

## Which stage this scene is. Everything else about it — the clock, the
## objective text, the ranking — is looked up from LevelData by this number.
@export var level_num := 1

var data: Dictionary
var outdoor := false
var phase: Phase = Phase.PLAY

var player: Player
var hud: Hud
var camera: Camera2D
var goal: GoalZone

var suspicion := 0.0
var time_left := 0.0
var time_total := 0.0
var seen_count := 0
var in_dialogue := false

var _entities: Node2D
var _bg_canvas: CanvasLayer
var _strips: Array[ParallaxStrip] = []
var _fx_canvas: CanvasLayer
var _clouds: Array[Sprite2D] = []
var _motes: Array[Sprite2D] = []
var _amb_t := 0.0
var _shake := 0.0
var _shake_left := 0.0
var _overlay: CanvasLayer
var _dialogue_cd := 0.0
var _bell_played := false

# ===========================================================================
func _ready() -> void:
	data = LevelData.get_level(level_num)
	Game.current_level = level_num
	outdoor = LevelData.THEMES.get(data["theme"], {}).get("outdoor", false)
	time_total = data["time"]
	time_left = time_total
	Game.reset_run()

	_collect_scene()
	_wire_entities()
	_setup_camera()
	_build_ambient()
	_build_hud()

	Sfx.play_music()

## Groups are tree-wide, and the stage being torn down is still in the tree
## while the next one starts up — so a raw group lookup can hand this level
## the previous one's teachers. Every lookup is scoped to our own branch.
func _group(name: String) -> Array:
	var out: Array = []
	for n in get_tree().get_nodes_in_group(name):
		if is_ancestor_of(n):
			out.append(n)
	return out

## Picks the laid-out scene apart. The fixed furniture is fetched by path; the
## things there can be any number of are fetched by group, so hand-placed ones
## are picked up exactly like baked ones.
func _collect_scene() -> void:
	player = $Player
	_entities = $Entities
	_bg_canvas = $Background
	for n in _bg_canvas.get_children():
		if n is ParallaxStrip:
			_strips.append(n as ParallaxStrip)
	var goals := _group("goal")
	goal = goals[0] as GoalZone if goals.size() > 0 else null

func _wire_entities() -> void:
	player.noise_mult = data.get("noise_mult", 1.0)
	player.noise_made.connect(_on_noise)
	player.item_used.connect(_on_item_used)
	player.inventory_changed.connect(func(): hud.update_inventory(player.inventory, player.selected))
	player.stunned.connect(func(): shake(4.5, 0.35))

	for n in _group("npc"):
		var npc := n as Npc
		npc.set_player(player)
		npc.caught.connect(_on_caught)
		npc.confront.connect(_on_confront)

	for c in _group("cctv"):
		(c as Cctv).set_player(player)

	for z in _group("classroom"):
		(z as ClassroomZone).player_entered.connect(func():
			if phase == Phase.PLAY:
				_lose("เดินกลับเข้าห้องเรียนก่อนเวลา — แพ้ทันที!"))

func _setup_camera() -> void:
	camera = player.camera
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = data["width"] * TILE
	camera.limit_bottom = data["height"] * TILE
	camera.make_current()

func _build_hud() -> void:
	hud = load("res://scenes/ui/hud.tscn").instantiate()
	add_child(hud)
	hud.set_level_info(data["num"], data["name"])
	hud.show_objective(data["goal_text"], data["hint"])
	hud.update_inventory(player.inventory, player.selected)
	hud.update_suspicion(0.0)

# ------------------------------------------------------------- background --
## Clouds drifting across the sky outdoors, dust turning in the light indoors.
## Both live in canvas space and simply wrap, which costs nothing and gives the
## stages a bit of motion even when the player is standing still.
func _build_ambient() -> void:
	var amb: Dictionary = AMBIENT.get(data["theme"], AMBIENT["hallway"])
	var rng := RandomNumberGenerator.new()
	rng.seed = data["num"] * 7919

	for i in int(amb["clouds"]):
		var c := Sprite2D.new()
		c.texture = load("res://assets/sprites/cloud_%s.png" % ["a", "b", "c"][i % 3])
		c.position = Vector2(rng.randf_range(0, 480), rng.randf_range(18, 96))
		c.modulate = Color(1, 1, 1, rng.randf_range(0.45, 0.8))
		c.set_meta("speed", rng.randf_range(3.0, 9.0))
		_bg_canvas.add_child(c)
		_clouds.append(c)

	_fx_canvas = CanvasLayer.new()
	_fx_canvas.name = "Ambient"
	_fx_canvas.layer = 5                    # over the world, under the HUD
	add_child(_fx_canvas)
	var tex: Texture2D = load("res://assets/sprites/%s.png" % amb["tex"])
	for i in int(amb["motes"]):
		var m := Sprite2D.new()
		m.texture = tex
		m.position = Vector2(rng.randf_range(0, 480), rng.randf_range(0, 270))
		m.modulate = amb["tint"]
		m.set_meta("vx", rng.randf_range(-9.0, 9.0) if not outdoor else rng.randf_range(-26.0, -9.0))
		m.set_meta("vy", rng.randf_range(3.0, 11.0))
		m.set_meta("phase", rng.randf_range(0.0, TAU))
		_fx_canvas.add_child(m)
		_motes.append(m)

func _update_background(delta: float) -> void:
	if camera == null:
		return
	var cam := camera.get_screen_center_position()
	for n in _strips:
		n.position.x = -480 - fmod(cam.x * n.scroll_factor, 480.0)
		n.position.y = n.base_y - (cam.y - 135.0) * n.scroll_factor * 0.5

	if _shake_left > 0.0:
		_shake_left -= delta
		var k := clampf(_shake_left / 0.35, 0.0, 1.0)
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake * k
		if _shake_left <= 0.0:
			camera.offset = Vector2.ZERO
			_shake = 0.0

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

## Short camera kick so a hit registers physically, not just as a message.
func shake(amount: float, duration: float) -> void:
	_shake = maxf(_shake, amount)
	_shake_left = maxf(_shake_left, duration)

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
	for n in _group("npc"):
		var npc := n as Npc
		if npc == null:
			continue
		if npc.can_see_player:
			watched = true
			strength = maxf(strength, npc.awareness)
		if npc.state == Npc.State.ALERT:
			watched = true
			strength = maxf(strength, 1.0)
	for c in _group("cctv"):
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

func _nearest_hide() -> HideSpot:
	var best: HideSpot = null
	var bd := 26.0
	for h in _group("hide_spot"):
		var d := player.global_position.distance_to((h as Node2D).global_position)
		if d < bd:
			bd = d
			best = h
	return best

func _nearest_door() -> Doorway:
	var best: Doorway = null
	var bd := 30.0
	for d in _group("doorway"):
		var door := d as Doorway
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
		Fader.goto(LevelData.scene_path(level_num))
		return
	if not event.is_action_pressed("interact") or phase != Phase.PLAY or in_dialogue:
		return

	if player.is_hidden:
		player.set_hidden(false)
		for h in _group("hide_spot"):
			(h as HideSpot).set_occupied(false)
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
		for n in _group("npc"):
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
	var r := NoiseRing.new()
	r.radius = radius
	r.position = pos
	return r

func _on_noise(pos: Vector2, radius: float) -> void:
	_entities.add_child(_ring(pos, radius))
	for n in _group("npc"):
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
	var dlg: ExcuseDialogue = load("res://scenes/ui/dialogue.tscn").instantiate()
	add_child(dlg)
	dlg.open(npc.stats["label"], Game.EXCUSES.pick_random(), player.inventory)
	dlg.resolved.connect(func(good: bool, used: String):
		in_dialogue = false
		_dialogue_cd = 4.0
		if used != "":
			player.consume_item(used)
		if good:
			suspicion = maxf(0.0, suspicion - 22.0)
			npc.look_away(Npc.CONVINCED_TIME, true)
			Fader.toast("รอดไปได้! หัวหน้าห้องเชื่อแล้ว — รีบเดินไปเลย", UI.GREEN)
		else:
			suspicion = minf(100.0, suspicion + 34.0)
			npc.look_away(Npc.BRUSHED_OFF_TIME, false)
			Fader.toast("ตอบไม่เนียน — ความสงสัยพุ่ง! รีบหนี", UI.RED)
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

## Both end-of-stage cards and the pause menu are scenes; the level only says
## what goes in them and what the buttons should do.
func _show_overlay(title: String, subtitle: String, lines: Array,
		accent: Color, show_next: bool) -> void:
	_clear_overlay()
	var panel: ResultPanel = load("res://scenes/ui/result_panel.tscn").instantiate()
	_overlay = panel
	add_child(panel)
	panel.show_result(title, subtitle, lines, accent, show_next)
	panel.next_pressed.connect(func(): Fader.goto(LevelData.scene_path(level_num + 1)))
	panel.retry_pressed.connect(func(): Fader.goto(LevelData.scene_path(level_num)))
	panel.menu_pressed.connect(func(): Fader.goto("res://scenes/level_select.tscn"))

func _show_pause() -> void:
	get_tree().paused = true
	_clear_overlay()
	var panel: PausePanel = load("res://scenes/ui/pause_panel.tscn").instantiate()
	_overlay = panel
	add_child(panel)
	panel.setup(data["goal_text"])
	panel.resume_pressed.connect(func():
		get_tree().paused = false
		_clear_overlay())
	panel.restart_pressed.connect(func():
		get_tree().paused = false
		Fader.goto(LevelData.scene_path(level_num)))
	panel.menu_pressed.connect(func():
		get_tree().paused = false
		Fader.goto("res://scenes/level_select.tscn"))
