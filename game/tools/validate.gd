extends SceneTree
## Checks every stage for placement mistakes that are easy to make by hand:
## entities standing inside walls, spawns with no floor, items buried in
## geometry, patrol ranges running off the map, unreachable goals.
##   Godot.exe --headless --path game --script res://tools/validate.gd

var _problems := 0

func _initialize() -> void:
	for i in range(1, LevelData.count() + 1):
		_check(LevelData.get_level(i))
	if _problems == 0:
		print("\nall %d levels validated clean" % LevelData.count())
	else:
		print("\n%d problem(s) found" % _problems)
	quit(1 if _problems > 0 else 0)

func _bad(level: Dictionary, msg: String) -> void:
	_problems += 1
	print("  [ด่าน %d] %s" % [level["num"], msg])

func _check(d: Dictionary) -> void:
	print("\n--- ด่าน %d: %s (%dx%d, %.0fs) ---" % [d["num"], d["name"], d["width"], d["height"], d["time"]])
	var W: int = d["width"]
	var H: int = d["height"]

	var solid := {}
	for r in d["solids"]:
		if r[0] < 0 or r[1] < 0 or r[0] + r[2] > W or r[1] + r[3] > H:
			_bad(d, "solid rect %s falls outside the %dx%d map" % [r, W, H])
		for y in range(r[1], r[1] + r[3]):
			for x in range(r[0], r[0] + r[2]):
				solid[Vector2i(x, y)] = true

	var platform := {}
	for p in d.get("platforms", []):
		if p[1] < 0 or p[1] >= H or p[0] < 0 or p[0] + p[2] > W:
			_bad(d, "platform %s falls outside the map" % [p])
		for x in range(p[0], p[0] + p[2]):
			platform[Vector2i(x, p[1])] = true

	var ladder := {}
	for l in d.get("ladders", []):
		for y in range(l[1], l[1] + l[2]):
			ladder[Vector2i(l[0], y)] = true

	# --- standing things need clear head room and something under their feet --
	var standing: Array = []
	standing.append({"what": "spawn", "x": d["spawn"][0], "y": d["spawn"][1]})
	standing.append({"what": "goal", "x": d["goal"][0], "y": d["goal"][1]})
	for n in d.get("npcs", []):
		standing.append({"what": "npc %s" % n["type"], "x": n["x"], "y": n["y"]})
	for h in d.get("hides", []):
		standing.append({"what": "hide %s" % h["type"], "x": h["x"], "y": h["y"]})
	for dr in d.get("doors", []):
		standing.append({"what": "door", "x": dr["x"], "y": dr["y"]})
	for b in d.get("balls", []):
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
	for it in d.get("items", []):
		var c := Vector2i(it["x"], it["y"])
		if solid.has(c):
			_bad(d, "item %s at (%d,%d) is inside a wall" % [it["id"], c.x, c.y])
		# an item wants either ground below or a ladder/platform to reach it
		var below := Vector2i(c.x, c.y + 1)
		if not (solid.has(below) or platform.has(below) or ladder.has(c) or ladder.has(below)):
			_bad(d, "item %s at (%d,%d) floats with nothing to stand on" % [it["id"], c.x, c.y])

	for cam in d.get("cameras", []):
		var c := Vector2i(cam["x"], cam["y"])
		if solid.has(c):
			_bad(d, "camera at (%d,%d) is inside a solid tile" % [c.x, c.y])

	# ------------------------------------------------------- patrol ranges ---
	for n in d.get("npcs", []):
		var lo: int = n["patrol"][0]
		var hi: int = n["patrol"][1]
		if lo >= hi:
			_bad(d, "npc %s has an empty patrol range %s" % [n["type"], n["patrol"]])
		if lo < 1 or hi > W - 2:
			_bad(d, "npc %s patrol %s runs into the map edge" % [n["type"], n["patrol"]])
		if n["x"] < lo or n["x"] > hi:
			_bad(d, "npc %s starts at x=%d, outside its patrol %s" % [n["type"], n["x"], n["patrol"]])

	# ------------------------------------------------------- goal / classroom --
	var g := Vector2i(d["goal"][0], d["goal"][1])
	if g.x < 1 or g.x > W - 2:
		_bad(d, "goal x=%d is outside the playable columns" % g.x)
	var cr: Array = d.get("classroom", [])
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
		d.get("npcs", []).size(), d.get("cameras", []).size(),
		d.get("items", []).size(), d.get("hides", []).size()])

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
	var W: int = d["width"]
	var H: int = d["height"]
	var solid := {}
	for r in d["solids"]:
		for y in range(r[1], r[1] + r[3]):
			for x in range(r[0], r[0] + r[2]):
				solid[Vector2i(x, y)] = true
	var plat := {}
	for p in d.get("platforms", []):
		for x in range(p[0], p[0] + p[2]):
			plat[Vector2i(x, p[1])] = true
	var lad := {}
	for l in d.get("ladders", []):
		for y in range(l[1], l[1] + l[2]):
			lad[Vector2i(l[0], y)] = true

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

	# --- platforms nobody can climb onto -----------------------------------
	for p in d.get("platforms", []):
		var any := false
		for x in range(p[0], p[0] + p[2]):
			if seen.has(Vector2i(x, p[1])):
				any = true
				break
		if not any:
			_bad(d, "platform [%d,%d,%d] is stranded - no way up to it" % [p[0], p[1], p[2]])

	print("    reachable standing tiles: %d" % seen.size())
