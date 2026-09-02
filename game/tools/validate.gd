extends SceneTree
## Checks every stage for the placement mistakes that are easy to make when
## you are dragging things about in the 2D editor: entities standing inside
## walls, spawns with no floor, items nothing can reach, patrol beats cut in
## two by a step an NPC cannot climb.
##   Godot.exe --headless --path game --script res://tools/validate.gd
##
## It reads the level scenes, not level_data.gd, so what it checks is what the
## game actually loads — move a teacher in the editor and this sees the move.

## Tile columns in the atlas that actually stop you.
const SOLID_TILES := [0, 1, 2, 3, 9, 10]    # floor top/fill, wall, wall top, grass, dirt
const PLATFORM_TILE := 4                    # the one-way ledge

const S_NPC := "res://scripts/npc.gd"
const S_CCTV := "res://scripts/cctv.gd"
const S_PLAYER := "res://scripts/player.gd"
const S_PICKUP := "res://scripts/entities/pickup.gd"
const S_HIDE := "res://scripts/entities/hide_spot.gd"
const S_DOOR := "res://scripts/entities/doorway.gd"
const S_BALL := "res://scripts/entities/ball.gd"
const S_GOAL := "res://scripts/entities/goal_zone.gd"
const S_LADDER := "res://scripts/entities/ladder_zone.gd"
const S_CLASSROOM := "res://scripts/entities/classroom_zone.gd"

var _problems := 0

## Deferred so the autoloads exist first: the level scenes pull in scripts
## that refer to them, and loading a scene before they are up fails.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for i in range(1, LevelData.count() + 1):
		_check(_read_scene(i))
	if _problems == 0:
		print("\nall %d levels validated clean" % LevelData.count())
	else:
		print("\n%d problem(s) found" % _problems)
	quit(1 if _problems > 0 else 0)

func _bad(level: Dictionary, msg: String) -> void:
	_problems += 1
	print("  [ด่าน %d] %s" % [level["num"], msg])

# ===========================================================================
#  Reading a stage back out of its scene
# ===========================================================================
## Nodes are identified by the script they carry rather than by class name.
## Naming the classes here would drag them — and the autoloads they refer to —
## into the compile pass of this tool, which runs too early for that to work.
func _script_path(n: Node) -> String:
	var s: Script = n.get_script()
	return s.resource_path if s != null else ""

## A stage quotes the tile the feet rest on; the node sits at its centre.
func _to_tile_feet(p: Vector2) -> Array:
	return [int(floor(p.x / 16.0)), int(round(p.y / 16.0))]

func _to_tile_centre(p: Vector2) -> Array:
	return [int(floor(p.x / 16.0)), int(floor(p.y / 16.0))]

func _read_scene(num: int) -> Dictionary:
	var meta := LevelData.get_level(num)
	var scene: Node = load(LevelData.scene_path(num)).instantiate()

	var d := {
		"num": num, "name": meta["name"],
		"width": meta["width"], "height": meta["height"], "time": meta["time"],
		"solid": {}, "plat": {}, "lad": {},
		"spawn": [0, 0], "goal": [0, 0], "classroom": [],
		"npcs": [], "cameras": [], "items": [], "hides": [], "doors": [], "balls": [],
	}

	# ------------------------------------------------------------- tiles ---
	var tiles: TileMapLayer = scene.get_node("SolidTiles")
	for cell in tiles.get_used_cells():
		var col := tiles.get_cell_atlas_coords(cell).x
		if col in SOLID_TILES:
			d["solid"][cell] = true
		elif col == PLATFORM_TILE:
			d["plat"][cell] = true

	# ----------------------------------------------------------- ladders ---
	for zone in scene.get_node("Ladders").get_children():
		if _script_path(zone) != S_LADDER:
			continue
		var r: Rect2i = zone.tile_rect()
		for y in range(r.position.y, r.position.y + r.size.y):
			d["lad"][Vector2i(r.position.x, y)] = true

	# ---------------------------------------------------------- entities ---
	for n in scene.get_node("Entities").get_children():
		var feet := _to_tile_feet(n.position)
		match _script_path(n):
			S_NPC:
				d["npcs"].append({
					"type": n.kind, "x": feet[0], "y": feet[1],
					"patrol": [int(floor(n.patrol_min / 16.0)), int(floor(n.patrol_max / 16.0))],
				})
			S_CCTV:
				var c := _to_tile_centre(n.position)
				d["cameras"].append({"x": c[0], "y": c[1]})
			S_PICKUP:
				var c2 := _to_tile_centre(n.position)
				d["items"].append({"id": n.id, "x": c2[0], "y": c2[1]})
			S_HIDE:
				d["hides"].append({"type": n.kind, "x": feet[0], "y": feet[1]})
			S_DOOR:
				d["doors"].append({"x": feet[0], "y": feet[1]})
			S_BALL:
				d["balls"].append({"x": feet[0], "y": feet[1]})
			S_GOAL:
				d["goal"] = feet

	for n in scene.get_children():
		match _script_path(n):
			S_PLAYER:
				d["spawn"] = _to_tile_feet(n.position)
			S_CLASSROOM:
				var box: Vector2 = (n.get_node("Shape").shape as RectangleShape2D).size
				d["classroom"] = [
					int(round((n.position.x - box.x / 2.0) / 16.0)),
					int(round((n.position.y - box.y / 2.0) / 16.0)),
					int(round(box.x / 16.0)), int(round(box.y / 16.0)),
				]

	scene.free()
	return d

## Contiguous runs of one-way ledge, so a stranded one can be reported by
## where it starts instead of tile by tile.
func _platform_runs(plat: Dictionary) -> Array:
	var runs: Array = []
	var cells: Array = plat.keys()
	cells.sort_custom(func(a, b): return a.y < b.y if a.y != b.y else a.x < b.x)
	for c in cells:
		if runs.size() > 0:
			var last: Array = runs[-1]
			if last[1] == c.y and last[0] + last[2] == c.x:
				last[2] += 1
				continue
		runs.append([c.x, c.y, 1])
	return runs

# ===========================================================================
#  Checks
# ===========================================================================
func _check(d: Dictionary) -> void:
	print("\n--- ด่าน %d: %s (%dx%d, %.0fs) ---" % [d["num"], d["name"], d["width"], d["height"], d["time"]])
	var W: int = d["width"]
	var H: int = d["height"]
	var solid: Dictionary = d["solid"]
	var platform: Dictionary = d["plat"]
	var ladder: Dictionary = d["lad"]

	for cell in solid:
		if cell.x < 0 or cell.y < 0 or cell.x >= W or cell.y >= H:
			_bad(d, "solid tile at %s is painted outside the %dx%d map" % [cell, W, H])
			break
	for cell in platform:
		if cell.x < 0 or cell.y < 0 or cell.x >= W or cell.y >= H:
			_bad(d, "ledge tile at %s is painted outside the map" % [cell])
			break

	# --- standing things need clear head room and something under their feet --
	var standing: Array = []
	standing.append({"what": "spawn", "x": d["spawn"][0], "y": d["spawn"][1]})
	standing.append({"what": "goal", "x": d["goal"][0], "y": d["goal"][1]})
	for n in d["npcs"]:
		standing.append({"what": "npc %s" % n["type"], "x": n["x"], "y": n["y"]})
	for h in d["hides"]:
		standing.append({"what": "hide %s" % h["type"], "x": h["x"], "y": h["y"]})
	for dr in d["doors"]:
		standing.append({"what": "door", "x": dr["x"], "y": dr["y"]})
	for b in d["balls"]:
		standing.append({"what": "ball", "x": b["x"], "y": b["y"]})

	for s in standing:
		var c := Vector2i(s["x"], s["y"])
		if not (solid.has(c) or platform.has(c)):
			_bad(d, "%s at (%d,%d) has no floor under it" % [s["what"], c.x, c.y])
		for dy in [1, 2]:
			var head := Vector2i(c.x, c.y - dy)
			if solid.has(head):
				_bad(d, "%s at (%d,%d) is buried in a solid tile" % [s["what"], c.x, c.y])
				break

	# ------------------------------------------------------- floating items --
	for it in d["items"]:
		var c := Vector2i(it["x"], it["y"])
		if solid.has(c):
			_bad(d, "item %s at (%d,%d) is inside a wall" % [it["id"], c.x, c.y])
		# an item wants either ground below or a ladder/platform to reach it
		var below := Vector2i(c.x, c.y + 1)
		if not (solid.has(below) or platform.has(below) or ladder.has(c) or ladder.has(below)):
			_bad(d, "item %s at (%d,%d) floats with nothing to stand on" % [it["id"], c.x, c.y])

	for cam in d["cameras"]:
		var c := Vector2i(cam["x"], cam["y"])
		if solid.has(c):
			_bad(d, "camera at (%d,%d) is inside a solid tile" % [c.x, c.y])

	# ------------------------------------------------------- patrol ranges ---
	for n in d["npcs"]:
		var lo: int = n["patrol"][0]
		var hi: int = n["patrol"][1]
		if lo >= hi:
			_bad(d, "npc %s has an empty patrol range %s" % [n["type"], n["patrol"]])
		if lo < 1 or hi > W - 2:
			_bad(d, "npc %s patrol %s runs into the map edge" % [n["type"], n["patrol"]])
		if n["x"] < lo or n["x"] > hi:
			_bad(d, "npc %s starts at x=%d, outside its patrol %s" % [n["type"], n["x"], n["patrol"]])

	# ------------------------------------------------------ goal / classroom --
	var g := Vector2i(d["goal"][0], d["goal"][1])
	if g.x < 1 or g.x > W - 2:
		_bad(d, "goal x=%d is outside the playable columns" % g.x)
	var cr: Array = d["classroom"]
	if cr.size() == 4:
		var sx: int = d["spawn"][0]
		if sx >= cr[0] and sx < cr[0] + cr[2]:
			_bad(d, "spawn x=%d sits inside the instant-lose classroom zone" % sx)

	# ------------------------------------------- can you walk the whole way? --
	var gaps: Array = []
	for x in range(1, W - 1):
		var has_ground := false
		for y in range(2, H):
			if solid.has(Vector2i(x, y)) or platform.has(Vector2i(x, y)):
				has_ground = true
				break
		if not has_ground:
			gaps.append(x)
	if gaps.size() > 0:
		_bad(d, "columns with no ground at all: %s" % [gaps])
	_check_reachable(d)
	print("    npcs=%d cameras=%d items=%d hides=%d" % [
		d["npcs"].size(), d["cameras"].size(), d["items"].size(), d["hides"].size()])


# ---------------------------------------------------------------------------
#  Reachability
#
#  Walking a rectangle list is not enough: a ledge can be perfectly well formed
#  and still be impossible to stand on. This floods the level from the spawn
#  using the moves the player actually has, then checks the goal and every item
#  against what it found.
#
#  The player jumps 272px/s against 980 gravity => ~37px of rise, a shade over
#  two tiles. The tables below stay a little under that on purpose, so anything
#  this reports as reachable is comfortably reachable in practice.
# ---------------------------------------------------------------------------

const JUMP_REACH := {0: 4, 1: 3, 2: 2}     # rise in tiles -> how far across
const FALL_DRIFT := 3                       # how far you can steer while falling

func _is_solid(m: Dictionary, x: int, y: int) -> bool:
	return m.has(Vector2i(x, y))

## A cell you can stand in: floor underfoot, and two clear cells for the body.
func _standable(solid: Dictionary, plat: Dictionary, W: int, H: int, x: int, y: int) -> bool:
	if x < 0 or x >= W or y < 1 or y >= H:
		return false
	if _is_solid(solid, x, y) or _is_solid(solid, x, y - 1):
		return false
	return _is_solid(solid, x, y + 1) or plat.has(Vector2i(x, y))or plat.has(Vector2i(x, y + 1))

func _reachable_set(d: Dictionary, solid: Dictionary, plat: Dictionary, lad: Dictionary) -> Dictionary:
	var W: int = d["width"]
	var H: int = d["height"]
	# Level data quotes the tile the feet rest ON, so the body actually occupies
	# the cell one row above it. That is the cell this flood works in.
	var start := Vector2i(d["spawn"][0], d["spawn"][1] - 1)

	var seed_cell := start
	if not _standable(solid, plat, W, H, seed_cell.x, seed_cell.y):
		for y in range(start.y, H):
			if _standable(solid, plat, W, H, start.x, y):
				seed_cell = Vector2i(start.x, y)
				break

	var seen := {}
	var queue: Array[Vector2i] = [seed_cell]
	seen[seed_cell] = true

	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		var nexts: Array[Vector2i] = []

		# walk
		for dx in [-1, 1]:
			nexts.append(Vector2i(c.x + dx, c.y))

		# jump, including a flat gap hop
		for rise in JUMP_REACH:
			var span: int = JUMP_REACH[rise]
			for dx in range(-span, span + 1):
				nexts.append(Vector2i(c.x + dx, c.y - rise))

		# step off an edge and fall to whatever is underneath
		for dx in range(-FALL_DRIFT, FALL_DRIFT + 1):
			var nx: int = c.x + dx
			for ny in range(c.y + 1, H):
				if _standable(solid, plat, W, H, nx, ny):
					nexts.append(Vector2i(nx, ny))
					break
				if _is_solid(solid, nx, ny):
					break

		# ladders and climbable fences are vertical corridors
		if lad.has(c) or lad.has(Vector2i(c.x, c.y - 1)):
			for ny in H:
				if lad.has(Vector2i(c.x, ny)):
					for dx in [-1, 0, 1]:
						nexts.append(Vector2i(c.x + dx, ny))
						nexts.append(Vector2i(c.x + dx, ny + 1))
		for dx in [-1, 1]:
			var side := Vector2i(c.x + dx, c.y)
			if lad.has(side):
				for ny in H:
					if lad.has(Vector2i(side.x, ny)):
						nexts.append(Vector2i(side.x, ny))

		for n in nexts:
			if seen.has(n):
				continue
			if not _standable(solid, plat, W, H, n.x, n.y):
				continue
			seen[n] = true
			queue.append(n)
	return seen

func _check_reachable(d: Dictionary) -> void:
	var solid: Dictionary = d["solid"]
	var plat: Dictionary = d["plat"]
	var lad: Dictionary = d["lad"]

	var seen := _reachable_set(d, solid, plat, lad)

	# --- goal ---------------------------------------------------------------
	var g := Vector2i(d["goal"][0], d["goal"][1] - 1)
	var goal_ok := false
	for dx in [-1, 0, 1]:
		if seen.has(Vector2i(g.x + dx, g.y)):
			goal_ok = true
	if not goal_ok:
		_bad(d, "the goal at (%d,%d) cannot be walked to from the spawn" % [d["goal"][0], d["goal"][1]])

	# --- items --------------------------------------------------------------
	# You collect an item by touching it, so any standing spot whose body
	# overlaps the item's tile counts.
	for it in d.get("items", []):
		var ix: int = it["x"]
		var iy: int = it["y"]
		var ok := false
		for cell in seen:
			if absi(cell.x - ix) <= 1 and iy >= cell.y - 2 and iy <= cell.y:
				ok = true
				break
		if not ok and (lad.has(Vector2i(ix, iy)) or lad.has(Vector2i(ix, iy + 1))):
			for cell in seen:
				if cell.x == ix:
					ok = true
					break
		if not ok:
			_bad(d, "item '%s' at (%d,%d) can never be reached" % [it["id"], ix, iy])

	# --- ledges nobody can climb onto ---------------------------------------
	for p in _platform_runs(plat):
		var any := false
		for x in range(p[0], p[0] + p[2]):
			if seen.has(Vector2i(x, p[1])):
				any = true
				break
		if not any:
			_bad(d, "the ledge at (%d,%d), %d wide, is stranded - no way up to it" % [p[0], p[1], p[2]])

	print("    reachable standing tiles: %d" % seen.size())
	_check_patrols(d, solid, plat)

## NPCs only walk and hop one tile (velocity -230 against gravity 980 clears
## about 27px). Terrain the player can vault therefore still walls them in, and
## a beat cut in half by such a block leaves an NPC shoving at it forever.
func _check_patrols(d: Dictionary, solid: Dictionary, plat: Dictionary) -> void:
	for n in d.get("npcs", []):
		# A staircase can be climbable one way and a sheer wall the other, so
		# both directions have to be walked.
		for forward in [true, false]:
			var stuck := _walk_beat(d, solid, plat, n, forward)
			if stuck >= 0:
				_bad(d, "npc %s cannot walk %s past x=%d: its beat %s is cut in two"
					% [n["type"], "right" if forward else "left", stuck, n["patrol"]])
				break

## Walks a patrol range one tile at a time, allowing a single-tile hop up and
## a fall of any depth. Returns the x it gets stuck at, or -1 if the beat is
## walkable end to end.
func _walk_beat(d: Dictionary, solid: Dictionary, plat: Dictionary,
		n: Dictionary, forward: bool) -> int:
	var W: int = d["width"]
	var H: int = d["height"]
	var lo: int = n["patrol"][0]
	var hi: int = n["patrol"][1]
	var cur: int = n["y"] - 1
	var xs := range(lo, hi + 1) if forward else range(hi, lo - 1, -1)
	for x in xs:
		var found := -1
		if _standable(solid, plat, W, H, x, cur):
			found = cur
		elif _standable(solid, plat, W, H, x, cur - 1):
			found = cur - 1                      # hop up a single tile
		else:
			for below in range(cur + 1, H):      # or drop to whatever is under
				if _standable(solid, plat, W, H, x, below):
					found = below
					break
		if found < 0:
			return x
		cur = found
	return -1
