extends SceneTree
## Turns the layouts in level_data.gd into real, editable Godot scenes.
##   Godot.exe --headless --path game --script res://tools/bake.gd
##
## Writes:
##   resources/tileset_<theme>.tres   one tile set per setting
##   scenes/actors/*.tscn             player, npc, cctv — prefabs to drag in
##   scenes/props/*.tscn              pickup, hiding spot, door, goal, ball
##   scenes/levels/level_NN.tscn      the five stages, laid out node by node
##
## The level scenes are what the game loads and what you edit in the 2D view.
## Entities are written into them as plain nodes rather than as instances of
## the prefabs: PackedScene.pack() drops property overrides made on the
## children of an instance, so an instanced hiding spot would lose its art and
## its hit box on the way to disk. Written out flat, every stage is complete
## and self-contained — and the prefabs are still there to drag in when you
## want to add something new.
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
const T_BG_WINDOW := 7
const T_BG_TILE := 8
const T_GRASS := 9
const T_DIRT := 10
const T_FENCE := 11

const SPR := "res://assets/sprites/%s.png"

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
	a.add_child(_rect_shape("Shape", Vector2(TILE - 2, tiles_high * TILE)))
	return a

func _new_classroom_zone(size := Vector2(64, 64)) -> Area2D:
	var a := Area2D.new()
	a.name = "Classroom"
	a.set_script(load("res://scripts/entities/classroom_zone.gd"))
	a.collision_layer = 0
	a.collision_mask = 2
	a.add_child(_rect_shape("Shape", size))
	return a

# ----------------------------------------------------------------- prefabs --
## Standalone copies of each entity, so a new one can be dragged straight into
## a stage from the FileSystem dock.
func _bake_prefabs() -> void:
	_save_scene(_new_player(), "res://scenes/actors/player.tscn")
	_save_scene(_new_npc(), "res://scenes/actors/npc.tscn")
	_save_scene(_new_cctv(), "res://scenes/actors/cctv.tscn")
	_save_scene(_new_pickup(), "res://scenes/props/pickup.tscn")
	_save_scene(_new_hide(), "res://scenes/props/hide_spot.tscn")
	_save_scene(_new_door(), "res://scenes/props/doorway.tscn")
	_save_scene(_new_goal(), "res://scenes/props/goal_zone.tscn")
	_save_scene(_new_ball(), "res://scenes/props/ball.tscn")
	_save_scene(_new_ladder_zone(), "res://scenes/props/ladder_zone.tscn")
	_save_scene(_new_classroom_zone(), "res://scenes/props/classroom_zone.tscn")

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

	var player := _new_player()
	player.position = _tile_pos(d["spawn"])
	root.add_child(player)

	# The room you are meant to be skipping: walking back in loses the stage.
	var cr: Array = d.get("classroom", [])
	if cr.size() == 4:
		var zone := _new_classroom_zone(Vector2(cr[2] * TILE, cr[3] * TILE))
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
		for w in d.get("windows", []):
			for y in range(w[1], w[1] + w[3]):
				for x in range(w[0], w[0] + w[2]):
					bg.set_cell(Vector2i(x, y), 0, Vector2i(T_BG_WINDOW, 0))

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
func _build_ladders(d: Dictionary) -> Node2D:
	var holder := Node2D.new()
	holder.name = "Ladders"
	var i := 1
	for l in d.get("ladders", []):
		var is_fence: bool = l.size() > 3 and l[3] == "fence"
		var zone := _new_ladder_zone(l[2])
		zone.name = "%s%d" % ["Fence" if is_fence else "Ladder", i]
		zone.position = Vector2(l[0] * TILE + TILE / 2.0, (l[1] + l[2] / 2.0) * TILE)
		holder.add_child(zone)
		i += 1
	return holder

# --------------------------------------------------------------- entities --
## Names are spelled out — HideBush2, ItemKey1 — because the Scene dock is
## how you find things once a stage is open in the editor.
func _build_entities(d: Dictionary) -> Node2D:
	var ents := Node2D.new()
	ents.name = "Entities"
	var seen := {}

	for cfg in d.get("npcs", []):
		var n := _new_npc(cfg["type"],
			cfg["patrol"][0] * TILE + 8.0, cfg["patrol"][1] * TILE + 8.0)
		n.position = _tile_pos([cfg["x"], cfg["y"]])
		n.name = _uniq(seen, cfg["type"].capitalize())
		ents.add_child(n)

	for cfg in d.get("cameras", []):
		var c := _new_cctv(cfg.get("angle", 90.0), cfg.get("sweep", 45.0),
			cfg.get("range", 92.0), cfg.get("period", 4.5), cfg.get("phase", 0.0))
		c.position = _center_pos([cfg["x"], cfg["y"]])
		c.name = _uniq(seen, "Cctv")
		ents.add_child(c)

	for cfg in d.get("items", []):
		var p := _new_pickup(cfg["id"])
		p.position = _center_pos([cfg["x"], cfg["y"]])
		p.name = _uniq(seen, "Item" + cfg["id"].capitalize())
		ents.add_child(p)

	for cfg in d.get("hides", []):
		var h := _new_hide(cfg["type"])
		h.position = _tile_pos([cfg["x"], cfg["y"]])
		h.name = _uniq(seen, "Hide" + cfg["type"].capitalize())
		ents.add_child(h)

	for cfg in d.get("doors", []):
		var dr := _new_door(cfg.get("locked", true))
		dr.position = _tile_pos([cfg["x"], cfg["y"]])
		dr.name = _uniq(seen, "Door")
		ents.add_child(dr)

	for cfg in d.get("balls", []):
		var b := _new_ball(cfg["range"][0] * TILE, cfg["range"][1] * TILE, cfg["speed"])
		b.position = _tile_pos([cfg["x"], cfg["y"]])
		b.name = _uniq(seen, "Ball")
		ents.add_child(b)

	for cfg in d.get("props", []):
		var tex: Texture2D = load(SPR % cfg["name"])
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height())
		s.position = _tile_pos([cfg["x"], cfg["y"]])
		s.z_index = -3
		s.name = _uniq(seen, cfg["name"].replace("prop_", "").capitalize())
		ents.add_child(s)

	var goal := _new_goal()
	goal.position = _tile_pos(d["goal"])
	ents.add_child(goal)
	return ents

func _uniq(seen: Dictionary, stem: String) -> String:
	var n: int = seen.get(stem, 0) + 1
	seen[stem] = n
	return "%s%d" % [stem, n]
