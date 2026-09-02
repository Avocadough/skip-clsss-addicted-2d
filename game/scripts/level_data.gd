class_name LevelData
extends RefCounted
## The five stages from section 8 of the design document.
##
## This file holds two different things, and the split matters:
##
##   * Stage settings the game reads every time you play — the clock, the
##     name, the objective text, the hint, the ranking rules. Live data.
##   * The original layout each stage was laid out from — solids, platforms,
##     NPCs, items. That is the input to tools/bake.gd, which writes it out as
##     scenes/levels/level_NN.tscn. Once baked, the scene is what the game
##     loads and what you edit; re-running the bake throws hand edits away.
##
## Layout conventions, all in 16px tile units:
##   solids / platforms / ladders     -> [x, y, w, (h)]
##   npc / hide / door / goal / spawn -> (x, y) is the tile the feet rest on
##   item / camera                    -> (x, y) is the tile the sprite centres on

const TILE := 16

## How each setting looks. `layers` are the parallax strips behind the world,
## slowest first; `factor` is how much of the camera motion each one takes.
## Indoor stages leave their upper wall unpainted so the strip shows through.
const THEMES := {
	"hallway": {
		"outdoor": false, "base": "2b2440",
		"layers": [{"tex": "bg_hallway_deco", "y": 14.0, "factor": 0.30, "h": 160.0}],
	},
	"cafeteria": {
		"outdoor": false, "base": "35291f",
		"layers": [{"tex": "bg_cafeteria_deco", "y": 8.0, "factor": 0.30, "h": 160.0}],
	},
	"library": {
		"outdoor": false, "base": "241f18",
		"layers": [{"tex": "bg_library_deco", "y": 6.0, "factor": 0.30, "h": 160.0}],
	},
	"field": {
		"outdoor": true, "base": "8cc4e0",
		"layers": [
			{"tex": "bg_field_sky", "y": 0.0, "factor": 0.04, "h": 270.0},
			{"tex": "bg_field_far", "y": 56.0, "factor": 0.24, "h": 140.0},
			{"tex": "bg_field_trees", "y": 146.0, "factor": 0.52, "h": 70.0},
		],
	},
	"gate": {
		"outdoor": true, "base": "6b4a7a",
		"layers": [
			{"tex": "bg_gate_sky", "y": 0.0, "factor": 0.04, "h": 270.0},
			{"tex": "bg_gate_far", "y": 56.0, "factor": 0.24, "h": 140.0},
			{"tex": "bg_gate_trees", "y": 146.0, "factor": 0.52, "h": 70.0},
		],
	},
}

static func count() -> int:
	return 5

## Where a stage lives now that each one is its own scene.
static func scene_path(index: int) -> String:
	return "res://scenes/levels/level_%02d.tscn" % clampi(index, 1, count())

static func get_level(index: int) -> Dictionary:
	match index:
		1: return _level1()
		2: return _level2()
		3: return _level3()
		4: return _level4()
		_: return _level5()

# ---------------------------------------------------------------------------
#  ด่าน 1 — ทางเดินหน้าห้อง
#  "ออกจากโซนห้องเรียนโดยไม่ให้ครูเห็น"
# ---------------------------------------------------------------------------
static func _level1() -> Dictionary:
	var W := 62
	return {
		"num": 1,
		"name": "ทางเดินหน้าห้อง",
		"en": "The Hallway",
		"goal_text": "ออกจากโซนห้องเรียนไปให้ถึงบันไดฝั่งขวา โดยไม่ให้ครูเห็น",
		"hint": "ครูเดินตรวจเป็นรอบ — หลบในตู้ล็อกเกอร์ (กด E) แล้วรอจังหวะ",
		"theme": "hallway",
		"width": W, "height": 17,
		"time": 62.0,
		"noise_mult": 1.0,
		"must_survive": false,
		"spawn": [9, 13],
		"goal": [58, 13],
		"classroom": [1, 8, 6, 5],
		"solids": [
			[0, 13, W, 4],          # floor slab
			[0, 0, W, 2],           # ceiling
			[0, 2, 1, 11],          # left wall
			[W - 1, 2, 1, 11],      # right wall
			# Boxes shaped as a step from either side. NPCs only hop one tile,
			# so a 2-tall face would wall their patrol off completely.
			[29, 12, 3, 1],
			[30, 11, 1, 1],
		],
		"platforms": [
			[20, 8, 8], [34, 8, 7], [48, 8, 6],
		],
		"ladders": [
			[19, 8, 5], [41, 8, 5], [47, 8, 5],
		],
		"npcs": [
			{"type": "teacher", "x": 36, "y": 13, "patrol": [22, 46]},
			{"type": "monitor", "x": 52, "y": 13, "patrol": [48, 59]},
		],
		"cameras": [
			{"x": 36, "y": 3, "angle": 90.0, "sweep": 40.0, "range": 88.0, "period": 4.6},
		],
		"hides": [
			{"type": "locker", "x": 13, "y": 13},
			{"type": "locker", "x": 27, "y": 13},
			{"type": "locker", "x": 44, "y": 13},
			{"type": "desk", "x": 23, "y": 13},
			{"type": "desk", "x": 39, "y": 13},
			{"type": "locker", "x": 56, "y": 13},
		],
		"items": [
			{"id": "nursecard", "x": 17, "y": 12},
			{"id": "coin", "x": 37, "y": 7},
			{"id": "wetsign", "x": 52, "y": 12},
		],
		"doors": [],
		"props": [
			{"name": "prop_door", "x": 4, "y": 13},
			{"name": "prop_whiteboard", "x": 3, "y": 9},
			{"name": "prop_clock", "x": 33, "y": 5},
			{"name": "prop_trashcan", "x": 21, "y": 13},
			{"name": "prop_exit_sign", "x": 57, "y": 6},
		],
	}

# ---------------------------------------------------------------------------
#  ด่าน 2 — โรงอาหาร
#  "หาเหรียญและขนมเพื่อล่อเพื่อนที่ชอบฟ้อง"
# ---------------------------------------------------------------------------
static func _level2() -> Dictionary:
	var W := 72
	return {
		"num": 2,
		"name": "โรงอาหาร",
		"en": "The Cafeteria",
		"goal_text": "ผ่านโรงอาหารที่คนแน่นไปให้ถึงทางออกฝั่งขวา",
		"hint": "คนเยอะ = เสียงดัง ลองโยนเหรียญ (กด Q) ล่อให้ NPC เดินไปอีกทาง",
		"theme": "cafeteria",
		"width": W, "height": 17,
		"time": 74.0,
		"noise_mult": 1.15,
		"must_survive": false,
		"spawn": [3, 13],
		"goal": [68, 13],
		"classroom": [],
		"solids": [
			[0, 13, W, 4],
			[0, 0, W, 2],
			[0, 2, 1, 11],
			[W - 1, 2, 1, 11],
			# stepped both sides so patrols can cross (see level 1)
			[38, 12, 1, 1],
			[39, 11, 1, 2],
			[40, 12, 1, 1],
		],
		"platforms": [
			[12, 8, 9], [30, 7, 8], [50, 8, 10],
		],
		"ladders": [
			[11, 8, 5], [29, 7, 6], [49, 8, 5],
		],
		"npcs": [
			{"type": "teacher", "x": 26, "y": 13, "patrol": [18, 40]},
			{"type": "monitor", "x": 60, "y": 13, "patrol": [54, 67]},
			{"type": "student", "x": 16, "y": 13, "patrol": [8, 22]},
			{"type": "student2", "x": 46, "y": 13, "patrol": [42, 52]},
		],
		"cameras": [
			{"x": 34, "y": 3, "angle": 90.0, "sweep": 55.0, "range": 96.0, "period": 5.2},
		],
		"hides": [
			{"type": "table", "x": 8, "y": 13},
			{"type": "table", "x": 20, "y": 13},
			{"type": "table", "x": 30, "y": 13},
			{"type": "table", "x": 44, "y": 13},
			{"type": "table", "x": 57, "y": 13},
			{"type": "vending", "x": 65, "y": 13},
		],
		"items": [
			{"id": "coin", "x": 6, "y": 12},
			{"id": "coin", "x": 33, "y": 6},
			{"id": "notebook", "x": 54, "y": 7},
			{"id": "nursecard", "x": 24, "y": 12},
		],
		"doors": [],
		"props": [
			{"name": "prop_vending", "x": 4, "y": 13},
			{"name": "prop_vending", "x": 70, "y": 13},
			{"name": "prop_trashcan", "x": 36, "y": 13},
			{"name": "prop_trashcan", "x": 52, "y": 13},
			{"name": "prop_clock", "x": 40, "y": 5},
			{"name": "prop_exit_sign", "x": 67, "y": 6},
		],
	}

# ---------------------------------------------------------------------------
#  ด่าน 3 — ห้องสมุด
#  "หากุญแจห้องเก็บของโดยห้ามวิ่ง"
# ---------------------------------------------------------------------------
static func _level3() -> Dictionary:
	var W := 68
	return {
		"num": 3,
		"name": "ห้องสมุด",
		"en": "The Library",
		"goal_text": "หากุญแจห้องเก็บของ เปิดประตูทางลัด แล้วออกไปให้ได้",
		"hint": "พื้นไม้ดังมาก — ห้ามวิ่ง! ชั้นหนังสือบังสายตาได้",
		"theme": "library",
		"width": W, "height": 17,
		"time": 80.0,
		"noise_mult": 2.1,
		"must_survive": false,
		"spawn": [3, 13],
		"goal": [65, 13],
		"classroom": [],
		"solids": [
			[0, 13, W, 4],
			[0, 0, W, 2],
			[0, 2, 1, 11],
			[W - 1, 2, 1, 11],
			[26, 12, 2, 1],
		],
		# The locked door sits in a full-height partition. Without this the door
		# is only two tiles tall and the player simply jumps over it.
		"wallblocks": [
			[58, 2, 1, 9],
		],
		"platforms": [
			[10, 8, 10], [32, 8, 9], [48, 7, 8],
		],
		"ladders": [
			[9, 8, 5], [31, 8, 5], [47, 7, 6],
		],
		"npcs": [
			{"type": "librarian", "x": 22, "y": 13, "patrol": [12, 38]},
			{"type": "librarian", "x": 54, "y": 13, "patrol": [50, 56]},
			{"type": "monitor", "x": 42, "y": 13, "patrol": [40, 50]},
		],
		"cameras": [
			{"x": 20, "y": 3, "angle": 90.0, "sweep": 48.0, "range": 92.0, "period": 4.0},
			{"x": 52, "y": 3, "angle": 90.0, "sweep": 48.0, "range": 92.0, "period": 4.0, "phase": 2.0},
		],
		"hides": [
			{"type": "desk", "x": 7, "y": 13},
			{"type": "desk", "x": 18, "y": 13},
			{"type": "desk", "x": 36, "y": 13},
			{"type": "desk", "x": 50, "y": 13},
			{"type": "shelf", "x": 62, "y": 13},
		],
		"items": [
			{"id": "key", "x": 13, "y": 7},
			{"id": "wetsign", "x": 35, "y": 7},
			{"id": "nursecard", "x": 44, "y": 12},
			{"id": "hoodie", "x": 51, "y": 6},
		],
		"doors": [
			{"x": 58, "y": 13, "locked": true},
		],
		"props": [
			{"name": "prop_bookshelf", "x": 14, "y": 13},
			{"name": "prop_bookshelf", "x": 24, "y": 13},
			{"name": "prop_bookshelf", "x": 44, "y": 13},
			{"name": "prop_bookshelf", "x": 54, "y": 13},
			{"name": "prop_clock", "x": 30, "y": 5},
			{"name": "prop_exit_sign", "x": 64, "y": 6},
		],
	}

# ---------------------------------------------------------------------------
#  ด่าน 4 — สนามกีฬาและหลังอาคาร
#  "ผ่านโค้ชและหาเส้นทางไปประตูหลัง"
# ---------------------------------------------------------------------------
static func _level4() -> Dictionary:
	var W := 76
	return {
		"num": 4,
		"name": "สนามกีฬาและหลังอาคาร",
		"en": "The Sports Field",
		"goal_text": "ข้ามสนามกีฬา ปีนรั้ว แล้วไปให้ถึงหลังอาคาร",
		"hint": "ลูกบอลที่กลิ้งมาจะทำให้ล้มและเสียงดัง — กระโดดข้าม แล้วปีนรั้วด้วยปุ่มขึ้น",
		"theme": "field",
		"width": W, "height": 17,
		"time": 78.0,
		"noise_mult": 0.85,
		"must_survive": false,
		"spawn": [3, 13],
		"goal": [72, 13],
		"classroom": [],
		"solids": [
			[0, 13, W, 4],
			[0, 2, 1, 11],
			[W - 1, 2, 1, 11],
			[24, 12, 3, 1],         # low bleacher step
			[25, 11, 1, 1],
			[44, 12, 2, 1],
		],
		"platforms": [
			[14, 8, 8], [36, 9, 8], [58, 8, 9],
		],
		"ladders": [
			[13, 8, 5], [35, 9, 4], [57, 8, 5],
			[52, 6, 7, "fence"],     # the chain-link fence you must climb
		],
		"npcs": [
			{"type": "coach", "x": 20, "y": 13, "patrol": [8, 34]},
			{"type": "coach", "x": 48, "y": 13, "patrol": [42, 56]},
			{"type": "monitor", "x": 66, "y": 13, "patrol": [62, 73]},
		],
		"cameras": [
			{"x": 62, "y": 4, "angle": 100.0, "sweep": 45.0, "range": 96.0, "period": 4.4},
		],
		"balls": [
			{"x": 30, "y": 13, "range": [28, 42], "speed": 62.0},
			{"x": 60, "y": 13, "range": [58, 70], "speed": 74.0},
		],
		"hides": [
			{"type": "bush", "x": 9, "y": 13},
			{"type": "bush", "x": 22, "y": 13},
			{"type": "bush", "x": 40, "y": 13},
			{"type": "bush", "x": 55, "y": 13},
			{"type": "bush", "x": 68, "y": 13},
		],
		"items": [
			{"id": "hoodie", "x": 17, "y": 7},
			{"id": "coin", "x": 39, "y": 8},
			{"id": "key", "x": 61, "y": 7},
			{"id": "nursecard", "x": 33, "y": 12},
		],
		"doors": [],
		"props": [
			{"name": "prop_crate", "x": 11, "y": 13},
			{"name": "prop_crate", "x": 46, "y": 13},
			{"name": "prop_trashcan", "x": 65, "y": 13},
			{"name": "prop_exit_sign", "x": 71, "y": 6},
		],
	}

# ---------------------------------------------------------------------------
#  ด่าน 5 — ประตูหลังโรงเรียน
#  "หลบ รปภ. และอยู่ใน Safe Zone จนกริ่งดัง"
# ---------------------------------------------------------------------------
static func _level5() -> Dictionary:
	var W := 70
	return {
		"num": 5,
		"name": "ประตูหลังโรงเรียน",
		"en": "The Back Gate",
		"goal_text": "เปิดประตูหลัง เข้า Safe Zone แล้วอยู่ให้รอดจนกริ่งดัง!",
		"hint": "ด่านนี้ไม่ใช่แค่ไปให้ถึง — ต้องอยู่ใน Safe Zone ตอนเวลาเหลือ 0",
		"theme": "gate",
		"width": W, "height": 17,
		"time": 72.0,
		"noise_mult": 1.0,
		"must_survive": true,
		"spawn": [3, 13],
		"goal": [66, 13],
		"classroom": [],
		"solids": [
			[0, 13, W, 4],
			[0, 2, 1, 11],
			[W - 1, 2, 1, 11],
			# stepped both sides so patrols can cross (see level 1)
			[18, 12, 3, 1],
			[19, 11, 1, 1],
			[40, 12, 2, 1],
		],
		# The gate is set into a full-height wall, so the key is the only way
		# through rather than something you can simply hop over.
		"wallblocks": [
			[56, 2, 1, 9],
		],
		"platforms": [
			[10, 8, 8], [28, 8, 9], [48, 9, 8],
		],
		"ladders": [
			[9, 8, 5], [27, 8, 5], [47, 9, 4],
			[36, 6, 7, "fence"],
		],
		"npcs": [
			{"type": "guard", "x": 24, "y": 13, "patrol": [14, 34]},
			{"type": "guard", "x": 60, "y": 13, "patrol": [58, 67]},
			{"type": "monitor", "x": 44, "y": 13, "patrol": [40, 48]},
		],
		"cameras": [
			{"x": 22, "y": 3, "angle": 90.0, "sweep": 50.0, "range": 100.0, "period": 3.8},
			{"x": 44, "y": 3, "angle": 90.0, "sweep": 50.0, "range": 100.0, "period": 3.8, "phase": 1.9},
			{"x": 62, "y": 4, "angle": 100.0, "sweep": 42.0, "range": 104.0, "period": 4.2},
		],
		"hides": [
			{"type": "bush", "x": 7, "y": 13},
			{"type": "bush", "x": 21, "y": 13},
			{"type": "bush", "x": 38, "y": 13},
			{"type": "crate", "x": 53, "y": 13},
			{"type": "bush", "x": 64, "y": 13},
		],
		"items": [
			{"id": "key", "x": 13, "y": 7},
			{"id": "hoodie", "x": 31, "y": 7},
			{"id": "wetsign", "x": 43, "y": 12},
			{"id": "nursecard", "x": 51, "y": 8},
			{"id": "coin", "x": 25, "y": 12},
		],
		"doors": [
			{"x": 56, "y": 13, "locked": true},
		],
		"props": [
			{"name": "prop_crate", "x": 5, "y": 13},
			{"name": "prop_trashcan", "x": 33, "y": 13},
			{"name": "prop_crate", "x": 46, "y": 13},
			{"name": "prop_exit_sign", "x": 65, "y": 6},
		],
	}
