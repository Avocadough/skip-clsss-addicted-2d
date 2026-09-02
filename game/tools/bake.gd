extends SceneTree
## Turns the layouts in level_data.gd into real, editable Godot scenes.
##   Godot.exe --headless --path game --script res://tools/bake.gd
##
## Writes:
##   resources/tileset_<theme>.tres   one tile set per setting
##   scenes/actors/*.tscn             น็อต, each watcher by name, the camera
##   scenes/items/*.tscn              one per item in Game.ITEMS
##   scenes/props/*.tscn              hiding spots, doors, ball, goal, zones
##   scenes/decor/*.tscn              scenery: bins, crates, whiteboards
##   scenes/ui/*.tscn                 HUD, menus, panels, dialogue
##   scenes/levels/level_NN.tscn      the five stages
##
## There is one scene per concrete thing rather than one generic scene with a
## setting on it: teacher.tscn and guard.tscn, item_key.tscn and item_coin.tscn,
## hide_locker.tscn and hide_bush.tscn. That is what you want to drag into a
## stage, and it is also what makes the stages instance them properly —
## PackedScene.pack() drops property overrides made on the children of an
## instance, so anything whose art differs has to differ in its own scene
## rather than in an override. Only position and a couple of exported values
## sit on the instance itself, and those live on the root, where they keep.
##
## Running this again overwrites all of the above, hand edits included.

const TILE := 16

# atlas column of each tile in assets/sprites/tiles_<theme>.png
const T_FLOOR_TOP := 0
const T_FLOOR_FILL := 1
const T_WALL := 2
const T_WALL_TOP := 3
const T_PLATFORM := 4
const T_LADDER := 5
const T_BG_WALL := 6
const T_BG_TILE := 7
const T_GRASS := 8
const T_DIRT := 9
const T_FENCE := 10

const SPR := "res://assets/sprites/%s.png"

## Where each kind of thing keeps its scene. Stages instance these, so moving
## one of these files means updating the path here and re-baking.
const PLAYER := "res://scenes/actors/player.tscn"
const CCTV := "res://scenes/actors/cctv.tscn"
const ACTOR := "res://scenes/actors/%s.tscn"
const ITEM := "res://scenes/items/item_%s.tscn"
const HIDE := "res://scenes/props/hide_%s.tscn"
const DECOR := "res://scenes/decor/%s.tscn"
const DOOR_LOCKED := "res://scenes/props/door_locked.tscn"
const DOOR_OPEN := "res://scenes/props/door_open.tscn"
const BALL := "res://scenes/props/ball.tscn"
const GOAL := "res://scenes/props/goal_zone.tscn"
const LADDER := "res://scenes/props/ladder_zone.tscn"
const CLASSROOM := "res://scenes/props/classroom_zone.tscn"

## Deferred, not run straight from _initialize: the UI helpers this needs in
## order to bake the classroom sign cannot compile until the autoloads they
## reference exist, and at _initialize time they do not yet.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	print("--- tile sets ---")
	for theme in LevelData.THEMES:
		_bake_tileset(theme)
	print("--- prefabs ---")
	_bake_prefabs()
	print("--- interface ---")
	_bake_ui()
	print("--- levels ---")
	for i in range(1, LevelData.count() + 1):
		_bake_level(i)
	print("\n=== done ===")
	quit()

# ---------------------------------------------------------------- saving --
## Everything the scene should contain has to be owned by its root, or
## PackedScene.pack() quietly leaves it out.
func _own(root: Node, n: Node) -> void:
	for c in n.get_children():
		c.owner = root
		# Do not walk into an instanced scene. Its children belong to it, and
		# claiming them here writes them out a second time as loose nodes.
		if c.scene_file_path == "":
			_own(root, c)

func _save_scene(root: Node, path: String) -> void:
	_own(root, root)
	var ps := PackedScene.new()
	var err := ps.pack(root)
	if err != OK:
		printerr("  pack failed: %s (%d)" % [path, err])
		root.free()
		return
	err = ResourceSaver.save(ps, path)
	if err != OK:
		printerr("  save failed: %s (%d)" % [path, err])
	else:
		print("  ", path)
	root.free()

# -------------------------------------------------------------- tile set --
func _bake_tileset(theme: String) -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer(0)
	ts.set_physics_layer_collision_layer(0, 1)

	var src := TileSetAtlasSource.new()
	src.texture = load(SPR % ("tiles_" + theme))
	src.texture_region_size = Vector2i(TILE, TILE)
	for i in T_FENCE + 1:
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

	var path := "res://resources/tileset_%s.tres" % theme
	var err := ResourceSaver.save(ts, path)
	print("  ", path if err == OK else "FAILED " + path)

# ===========================================================================
#  Node factories — one per kind of thing a stage can contain. Both the
#  prefab scenes and the baked stages are built from these, so a prefab and
#  the copy sitting in a level are always the same shape.
# ===========================================================================
func _sprite(name: String, tex_name: String) -> Sprite2D:
	var s := Sprite2D.new()
	s.name = name
	s.texture = load(SPR % tex_name)
	return s

func _rect_shape(name: String, size: Vector2, offset := Vector2.ZERO) -> CollisionShape2D:
	var cs := CollisionShape2D.new()
	cs.name = name
	var r := RectangleShape2D.new()
	r.size = size
	cs.shape = r
	cs.position = offset
	return cs

func _circle_shape(name: String, radius: float, offset := Vector2.ZERO) -> CollisionShape2D:
	var cs := CollisionShape2D.new()
	cs.name = name
	var c := CircleShape2D.new()
	c.radius = radius
	cs.shape = c
	cs.position = offset
	return cs

# ------------------------------------------------------------------ actors --
func _new_player() -> CharacterBody2D:
	var p := CharacterBody2D.new()
	p.name = "Player"
	p.set_script(load("res://scripts/player.gd"))
	p.collision_layer = 2
	p.collision_mask = 1
	p.add_child(_rect_shape("Shape", Vector2(10, 20), Vector2(0, -10)))

	var spr := _sprite("Sprite", "char_not")
	spr.hframes = 11
	spr.centered = false
	spr.offset = Vector2(-8, -22)
	p.add_child(spr)

	var cam := Camera2D.new()
	cam.name = "Camera"
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	p.add_child(cam)
	return p

func _new_npc(kind := "teacher", pmin := 0.0, pmax := 0.0) -> CharacterBody2D:
	var n := CharacterBody2D.new()
	n.name = "Npc"
	n.set_script(load("res://scripts/npc.gd"))
	n.collision_layer = 4
	n.collision_mask = 1
	n.add_child(_rect_shape("Shape", Vector2(10, 20), Vector2(0, -10)))

	var cone := Polygon2D.new()
	cone.name = "Cone"
	cone.color = Color(1.0, 0.90, 0.45, 0.16)
	cone.z_index = -1
	n.add_child(cone)

	var spr := Sprite2D.new()
	spr.name = "Sprite"
	spr.hframes = 11
	spr.centered = false
	spr.offset = Vector2(-8, -22)
	n.add_child(spr)

	var bubble := Sprite2D.new()
	bubble.name = "Bubble"
	bubble.position = Vector2(0, -32)
	bubble.visible = false
	n.add_child(bubble)

	# assigning `kind` puts the matching sprite sheet on through its setter
	n.patrol_min = pmin
	n.patrol_max = pmax
	n.kind = kind
	return n

func _new_cctv(angle := 90.0, sweep := 45.0, view_range := 92.0,
		period := 4.5, phase := 0.0) -> Node2D:
	var c := Node2D.new()
	c.name = "Cctv"
	c.set_script(load("res://scripts/cctv.gd"))

	var cone := Polygon2D.new()
	cone.name = "Cone"
	cone.color = Color(1.0, 0.45, 0.45, 0.14)
	cone.z_index = -1
	c.add_child(cone)

	c.add_child(_sprite("Body", "prop_cctv"))

	# blinking status light so a live camera reads at a glance
	var lamp := _sprite("Lamp", "fx_alert")
	lamp.position = Vector2(0, -16)
	lamp.visible = false
	c.add_child(lamp)

	c.base_angle = angle
	c.sweep = sweep
	c.view_range = view_range
	c.period = period
	c.phase = phase
	return c

# ------------------------------------------------------------------- props --
func _new_pickup(id := "coin") -> Area2D:
	var p := Area2D.new()
	p.name = "Pickup"
	p.set_script(load("res://scripts/entities/pickup.gd"))
	p.collision_layer = 8
	p.collision_mask = 2
	p.add_child(_circle_shape("Shape", 11.0))

	# a soft glow so items read against busy tiles
	var halo := _sprite("Halo", "prop_safe_zone")
	halo.modulate = Color(1.0, 0.95, 0.6, 0.16)
	halo.z_index = -1
	p.add_child(halo)

	var spr := Sprite2D.new()
	spr.name = "Sprite"
	p.add_child(spr)

	p.id = id                       # the setter puts the matching icon on
	return p

func _new_hide(kind := "locker") -> Area2D:
	var h := Area2D.new()
	h.name = "HideSpot"
	h.set_script(load("res://scripts/entities/hide_spot.gd"))
	h.collision_layer = 8
	h.collision_mask = 2

	var spr := Sprite2D.new()
	spr.name = "Sprite"
	h.add_child(spr)

	var cs := CollisionShape2D.new()
	cs.name = "Shape"
	h.add_child(cs)

	h.kind = kind                   # art, hit box and prompt all follow
	return h

func _new_door(locked := true) -> Area2D:
	var d := Area2D.new()
	d.name = "Doorway"
	d.set_script(load("res://scripts/entities/doorway.gd"))
	d.collision_layer = 8
	d.collision_mask = 2

	var spr := Sprite2D.new()
	spr.name = "Sprite"
	d.add_child(spr)

	var cs := CollisionShape2D.new()
	cs.name = "Shape"
	d.add_child(cs)

	var blocker := StaticBody2D.new()
	blocker.name = "Blocker"
	blocker.collision_layer = 1 | 32
	var bs := CollisionShape2D.new()
	bs.name = "Shape"
	blocker.add_child(bs)
	d.add_child(blocker)

	d.locked = locked               # sizes both shapes and picks the art
	return d

func _new_goal() -> Area2D:
	var g := Area2D.new()
	g.name = "Goal"
	g.set_script(load("res://scripts/entities/goal_zone.gd"))
	g.collision_layer = 8
	g.collision_mask = 2
	g.add_child(_rect_shape("Shape", Vector2(40, 40), Vector2(0, -20)))

	var spr := _sprite("Sprite", "prop_safe_zone")
	spr.position = Vector2(0, -22)
	spr.modulate = Color(0.55, 1.0, 0.70, 0.85)
	g.add_child(spr)
	return g

func _new_ball(x_min := 0.0, x_max := 0.0, speed := 60.0) -> Area2D:
	var b := Area2D.new()
	b.name = "Ball"
	b.set_script(load("res://scripts/entities/ball.gd"))
	b.collision_layer = 16
	b.collision_mask = 2
	b.add_child(_circle_shape("Shape", 7.0, Vector2(0, -7)))

	var spr := _sprite("Sprite", "item_coin")
	spr.modulate = Color(1.0, 0.55, 0.35)
	spr.position = Vector2(0, -7)
	b.add_child(spr)

	b.x_min = x_min
	b.x_max = x_max
	b.speed = speed
	return b

func _new_ladder_zone(tiles_high := 3) -> Area2D:
	var a := Area2D.new()
	a.name = "LadderZone"
	a.set_script(load("res://scripts/entities/ladder_zone.gd"))
	a.collision_layer = 0
	a.collision_mask = 2
	var cs := CollisionShape2D.new()
	cs.name = "Shape"
	a.add_child(cs)
	a.tiles_high = tiles_high        # the setter sizes the trigger
	return a

func _new_classroom_zone(tiles := Vector2i(4, 4)) -> Area2D:
	var a := Area2D.new()
	a.name = "Classroom"
	a.set_script(load("res://scripts/entities/classroom_zone.gd"))
	a.collision_layer = 0
	a.collision_mask = 2
	var cs := CollisionShape2D.new()
	cs.name = "Shape"
	a.add_child(cs)
	a.tiles = tiles
	return a

## A piece of scenery: a bin, a whiteboard, a crate stacked against a wall.
## No behaviour, but it gets a scene like everything else so it can be dragged
## into a stage and nudged around.
func _new_decor(tex_name: String) -> Sprite2D:
	var tex: Texture2D = load(SPR % tex_name)
	var s := Sprite2D.new()
	s.name = _pascal(tex_name.replace("prop_", ""))
	s.texture = tex
	s.centered = false
	s.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height())
	s.z_index = -3
	return s

# ----------------------------------------------------------------- prefabs --
## One scene per concrete thing in the game — this teacher, that item, this
## hiding spot — rather than one generic scene with a setting on it. Dragging
## `guard.tscn` into a stage gives you a guard, and because nothing then has
## to be changed on a child node, the stages can instance these properly
## instead of carrying flattened copies.
func _bake_prefabs() -> void:
	_save_scene(_new_player(), PLAYER)

	var npc_stats: Dictionary = load("res://scripts/npc.gd").get_script_constant_map()["STATS"]
	for kind in npc_stats:
		var n := _new_npc(kind)
		n.name = kind.capitalize()
		_save_scene(n, ACTOR % kind)
	_save_scene(_new_cctv(), CCTV)

	for id in root.get_node("Game").ITEMS:
		var p := _new_pickup(id)
		p.name = "Item" + id.capitalize()
		_save_scene(p, ITEM % id)

	var hide_art: Dictionary = load("res://scripts/entities/hide_spot.gd").get_script_constant_map()["ART"]
	for kind in hide_art:
		var h := _new_hide(kind)
		h.name = "Hide" + kind.capitalize()
		_save_scene(h, HIDE % kind)

	_save_scene(_new_door(true), DOOR_LOCKED)
	_save_scene(_new_door(false), DOOR_OPEN)
	_save_scene(_new_goal(), GOAL)
	_save_scene(_new_ball(), BALL)
	_save_scene(_new_ladder_zone(), LADDER)
	_save_scene(_new_classroom_zone(), CLASSROOM)

	for name in _decor_names():
		_save_scene(_new_decor(name), DECOR % name)

## Every piece of scenery any stage asks for, so none is missed.
func _decor_names() -> Array:
	var names := {}
	for i in range(1, LevelData.count() + 1):
		for cfg in LevelData.get_level(i).get("props", []):
			names[cfg["name"]] = true
	var out: Array = names.keys()
	out.sort()
	return out

# ===========================================================================
#  Stage assembly
# ===========================================================================
func _tile_pos(t) -> Vector2:
	return Vector2(t[0] * TILE + TILE / 2.0, t[1] * TILE)

func _center_pos(t) -> Vector2:
	return Vector2(t[0] * TILE + TILE / 2.0, t[1] * TILE + TILE / 2.0)

func _bake_level(num: int) -> void:
	var d := LevelData.get_level(num)
	var theme: Dictionary = LevelData.THEMES.get(d["theme"], LevelData.THEMES["hallway"])
	var outdoor: bool = theme["outdoor"]
	var ts: TileSet = load("res://resources/tileset_%s.tres" % d["theme"])

	var root := Node2D.new()
	root.name = "Level"
	root.set_script(load("res://scripts/level.gd"))
	root.level_num = num

	root.add_child(_build_background(theme))
	for layer in _build_tiles(d, outdoor, ts):
		root.add_child(layer)
	root.add_child(_build_ladders(d))
	root.add_child(_build_entities(d))

	var player := _instance(PLAYER)
	player.position = _tile_pos(d["spawn"])
	root.add_child(player)

	# The room you are meant to be skipping: walking back in loses the stage.
	var cr: Array = d.get("classroom", [])
	if cr.size() == 4:
		var zone := _instance(CLASSROOM)
		zone.set("tiles", Vector2i(cr[2], cr[3]))
		zone.position = Vector2((cr[0] + cr[2] / 2.0) * TILE, (cr[1] + cr[3] / 2.0) * TILE)
		root.add_child(zone)

		# Loaded by path rather than by class name on purpose. Naming UI here
		# would pull it into this tool's own compile pass, which runs before
		# the autoloads UI refers to exist — and the whole tool then fails to
		# load. By the time this line runs the tree is up and it compiles fine.
		var ui: GDScript = load("res://scripts/ui/ui.gd")
		var sign_label: Label = ui.label("ห้องเรียน\n(ห้ามเข้า!)", 11, ui.RED, true)
		sign_label.name = "ClassroomSign"
		sign_label.position = Vector2(cr[0] * TILE, (cr[1] - 1) * TILE)
		sign_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		root.add_child(sign_label)

	_save_scene(root, LevelData.scene_path(num))

# ------------------------------------------------------------- background --
func _build_background(theme: Dictionary) -> CanvasLayer:
	var cl := CanvasLayer.new()
	cl.name = "Background"
	cl.layer = -10

	var base := ColorRect.new()
	base.name = "Base"
	base.set_anchors_preset(Control.PRESET_FULL_RECT)
	base.color = Color(theme["base"])
	cl.add_child(base)

	var i := 0
	for spec in theme["layers"]:
		var tr := TextureRect.new()
		tr.set_script(load("res://scripts/fx/parallax_strip.gd"))
		tr.name = "Strip%d" % (i + 1)
		tr.texture = load(SPR % spec["tex"])
		tr.stretch_mode = TextureRect.STRETCH_TILE
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.size = Vector2(480 * 3, spec["h"])
		tr.position = Vector2(-480, spec["y"])
		tr.scroll_factor = spec["factor"]
		cl.add_child(tr)
		i += 1
	return cl

# ------------------------------------------------------------------ tiles --
func _build_tiles(d: Dictionary, outdoor: bool, ts: TileSet) -> Array:
	var W: int = d["width"]
	var H: int = d["height"]

	var bg := TileMapLayer.new()
	bg.name = "BgTiles"
	bg.tile_set = ts
	bg.z_index = -6
	# Only ever painted with wall / window / ladder / fence tiles, and none of
	# those define a collision polygon, so this layer is decoration by nature.

	var solid := TileMapLayer.new()
	solid.name = "SolidTiles"
	solid.tile_set = ts
	solid.z_index = -2

	# Indoor stages tile only the wainscot band along the bottom. The wall
	# above it is left bare on purpose so the parallax strip behind the world
	# — bookcases, a serving counter, a row of classroom doors — shows through
	# and each interior reads as its own room.
	if not outdoor:
		var wainscot: int = H - 6      # a low dado, so most of the backdrop shows
		for y in range(wainscot, H):
			for x in range(1, W - 1):
				bg.set_cell(Vector2i(x, y), 0, Vector2i(T_BG_TILE, 0))

	# collect every solid cell first so the "is this the surface?" test is cheap
	var solid_cells := {}
	for r in d["solids"]:
		for y in range(r[1], r[1] + r[3]):
			for x in range(r[0], r[0] + r[2]):
				solid_cells[Vector2i(x, y)] = true

	# Wall blocks are solid too, but painted as masonry rather than ground —
	# they are the partitions a locked door sits in, and a column of turf
	# hanging in mid-air would look absurd outdoors.
	var wall_cells := {}
	for r in d.get("wallblocks", []):
		for y in range(r[1], r[1] + r[3]):
			for x in range(r[0], r[0] + r[2]):
				wall_cells[Vector2i(x, y)] = true
				solid_cells[Vector2i(x, y)] = true

	for cell in solid_cells:
		var above := Vector2i(cell.x, cell.y - 1)
		var is_surface := not solid_cells.has(above)
		var t: int
		if wall_cells.has(cell):
			t = T_WALL_TOP if is_surface else T_WALL
		elif outdoor:
			t = T_GRASS if is_surface else T_DIRT
		else:
			t = T_FLOOR_TOP if is_surface else T_FLOOR_FILL
		solid.set_cell(cell, 0, Vector2i(t, 0))

	for p in d.get("platforms", []):
		for x in range(p[0], p[0] + p[2]):
			var c := Vector2i(x, p[1])
			if not solid_cells.has(c):
				solid.set_cell(c, 0, Vector2i(T_PLATFORM, 0))

	for l in d.get("ladders", []):
		var is_fence: bool = l.size() > 3 and l[3] == "fence"
		var art := T_FENCE if is_fence else T_LADDER
		for y in range(l[1], l[1] + l[2]):
			bg.set_cell(Vector2i(l[0], y), 0, Vector2i(art, 0))

	return [bg, solid]

# ---------------------------------------------------------------- ladders --
func _instance(path: String) -> Node2D:
	return load(path).instantiate()

# ---------------------------------------------------------------- ladders --
func _build_ladders(d: Dictionary) -> Node2D:
	var holder := Node2D.new()
	holder.name = "Ladders"
	var i := 1
	for l in d.get("ladders", []):
		var is_fence: bool = l.size() > 3 and l[3] == "fence"
		var zone := _instance(LADDER)
		zone.name = "%s%d" % ["Fence" if is_fence else "Ladder", i]
		zone.set("tiles_high", l[2])
		zone.position = Vector2(l[0] * TILE + TILE / 2.0, (l[1] + l[2] / 2.0) * TILE)
		holder.add_child(zone)
		i += 1
	return holder

# --------------------------------------------------------------- entities --
## Everything here is an instance of the scene for that exact thing, so the
## Scene dock reads as a list of what is in the stage and opening one takes
## you to the scene it came from. Names are spelled out — HideBush2, ItemKey1
## — because the dock is how you find things once a stage is open.
func _build_entities(d: Dictionary) -> Node2D:
	var ents := Node2D.new()
	ents.name = "Entities"
	var seen := {}

	for cfg in d.get("npcs", []):
		var n := _instance(ACTOR % cfg["type"])
		n.position = _tile_pos([cfg["x"], cfg["y"]])
		n.set("patrol_min", cfg["patrol"][0] * TILE + 8.0)
		n.set("patrol_max", cfg["patrol"][1] * TILE + 8.0)
		n.name = _uniq(seen, cfg["type"].capitalize())
		ents.add_child(n)

	for cfg in d.get("cameras", []):
		var c := _instance(CCTV)
		c.position = _center_pos([cfg["x"], cfg["y"]])
		c.set("base_angle", cfg.get("angle", 90.0))
		c.set("sweep", cfg.get("sweep", 45.0))
		c.set("view_range", cfg.get("range", 92.0))
		c.set("period", cfg.get("period", 4.5))
		c.set("phase", cfg.get("phase", 0.0))
		c.name = _uniq(seen, "Cctv")
		ents.add_child(c)

	for cfg in d.get("items", []):
		var p := _instance(ITEM % cfg["id"])
		p.position = _center_pos([cfg["x"], cfg["y"]])
		p.name = _uniq(seen, "Item" + cfg["id"].capitalize())
		ents.add_child(p)

	for cfg in d.get("hides", []):
		var h := _instance(HIDE % cfg["type"])
		h.position = _tile_pos([cfg["x"], cfg["y"]])
		h.name = _uniq(seen, "Hide" + cfg["type"].capitalize())
		ents.add_child(h)

	for cfg in d.get("doors", []):
		var dr := _instance(DOOR_LOCKED if cfg.get("locked", true) else DOOR_OPEN)
		dr.position = _tile_pos([cfg["x"], cfg["y"]])
		dr.name = _uniq(seen, "Door")
		ents.add_child(dr)

	for cfg in d.get("balls", []):
		var b := _instance(BALL)
		b.position = _tile_pos([cfg["x"], cfg["y"]])
		b.set("x_min", cfg["range"][0] * TILE)
		b.set("x_max", cfg["range"][1] * TILE)
		b.set("speed", cfg["speed"])
		b.name = _uniq(seen, "Ball")
		ents.add_child(b)

	for cfg in d.get("props", []):
		var s := _instance(DECOR % cfg["name"])
		s.position = _tile_pos([cfg["x"], cfg["y"]])
		s.name = _uniq(seen, _pascal(cfg["name"].replace("prop_", "")))
		ents.add_child(s)

	var goal := _instance(GOAL)
	goal.name = "Goal"
	goal.position = _tile_pos(d["goal"])
	ents.add_child(goal)
	return ents

## snake_case to PascalCase. String.capitalize() would give "Exit Sign", and a
## node name with a space in it is legal but reads badly in the Scene dock.
func _pascal(s: String) -> String:
	return s.capitalize().replace(" ", "")

func _uniq(seen: Dictionary, stem: String) -> String:
	var n: int = seen.get(stem, 0) + 1
	seen[stem] = n
	return "%s%d" % [stem, n]

# ===========================================================================
#  Interface
#
#  Each screen keeps its own layout in a static build() next to the script
#  that drives it, so the two never drift apart. They are loaded by path
#  rather than by class name: naming them here would drag them, and the
#  autoloads they refer to, into the compile pass of this tool.
# ===========================================================================
func _bake_ui() -> void:
	var hud: GDScript = load("res://scripts/ui/hud.gd")
	_save_scene(hud.build(), "res://scenes/ui/hud.tscn")
	_save_scene(hud.build_slot(), "res://scenes/ui/item_slot.tscn")

	var backdrop: GDScript = load("res://scripts/ui/backdrop.gd")
	_save_scene(backdrop.build(), "res://scenes/ui/backdrop.tscn")

	var boot: GDScript = load("res://scripts/ui/boot.gd")
	_save_scene(boot.build(), "res://scenes/boot.tscn")

	var modal: GDScript = load("res://scripts/ui/modal.gd")
	_save_scene(modal.build(), "res://scenes/ui/modal.tscn")

	var menu: GDScript = load("res://scripts/ui/main_menu.gd")
	_save_scene(menu.build_how_to(), "res://scenes/ui/howto_page.tscn")
	_save_scene(menu.build_credits(), "res://scenes/ui/about_page.tscn")
	_save_scene(menu.build(), "res://scenes/main_menu.tscn")

	var card: GDScript = load("res://scripts/ui/level_card.gd")
	_save_scene(card.build(), "res://scenes/ui/level_card.tscn")

	var select: GDScript = load("res://scripts/ui/level_select.gd")
	_save_scene(select.build(), "res://scenes/level_select.tscn")

	var dialogue: GDScript = load("res://scripts/ui/dialogue.gd")
	_save_scene(dialogue.build_answer(), "res://scenes/ui/answer_button.tscn")
	_save_scene(dialogue.build(), "res://scenes/ui/dialogue.tscn")

	var result: GDScript = load("res://scripts/ui/result_panel.gd")
	_save_scene(result.build(), "res://scenes/ui/result_panel.tscn")

	var pause: GDScript = load("res://scripts/ui/pause_panel.gd")
	_save_scene(pause.build(), "res://scenes/ui/pause_panel.tscn")

	var fader: GDScript = load("res://scripts/fader.gd")
	_save_scene(fader.build(), "res://scenes/ui/fader.tscn")
