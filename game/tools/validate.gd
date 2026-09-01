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
	print("    npcs=%d cameras=%d items=%d hides=%d" % [
		d.get("npcs", []).size(), d.get("cameras", []).size(),
		d.get("items", []).size(), d.get("hides", []).size()])
