class_name LevelData
extends RefCounted
## The five stages from section 8 of the design document.
##
## Levels are described as rectangles rather than ASCII art so the geometry
## stays easy to read and re-tune. Conventions, all in 16px tile units:
##   solids/platforms/ladders/windows -> [x, y, w, (h)]
##   npc / hide / door / goal / spawn -> (x, y) is the tile the feet rest on
##   item / camera                    -> (x, y) is the tile the sprite centres on

const TILE := 16

static func count() -> int:
	return 5

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
		"theme": "indoor",
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
			[30, 12, 2, 1],         # stacked boxes that block the low route
			[30, 11, 1, 1],
		],
		"platforms": [
			[20, 8, 8], [34, 8, 7], [48, 8, 6],
		],
		"ladders": [
			[19, 8, 5], [41, 8, 5], [47, 8, 5],
		],
		"windows": [
			[10, 4, 2, 2], [24, 4, 2, 2], [42, 4, 2, 2], [54, 4, 2, 2],
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
		"theme": "indoor",
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
			[38, 12, 1, 1],
			[39, 11, 1, 2],
		],
		"platforms": [
			[12, 8, 9], [30, 7, 8], [50, 8, 10],
		],
		"ladders": [
			[11, 8, 5], [29, 7, 6], [49, 8, 5],
		],
		"windows": [
			[6, 4, 2, 2], [20, 4, 2, 2], [44, 4, 2, 2], [62, 4, 2, 2],
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
			{"type": "locker", "x": 65, "y": 13},
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
		"theme": "indoor",
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
		"platforms": [
			[10, 8, 10], [32, 8, 9], [48, 7, 8],
		],
		"ladders": [
			[9, 8, 5], [31, 8, 5], [47, 7, 6],
		],
		"windows": [
			[16, 4, 2, 2], [40, 4, 2, 2], [58, 4, 2, 2],
		],
		"npcs": [
			{"type": "librarian", "x": 22, "y": 13, "patrol": [12, 38]},
			{"type": "librarian", "x": 56, "y": 13, "patrol": [52, 63]},
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
			{"type": "locker", "x": 62, "y": 13},
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
		"theme": "outdoor",
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
			[13, 8, 5], [57, 8, 5],
			[52, 6, 7, "fence"],     # the chain-link fence you must climb
		],
		"windows": [],
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
		"theme": "outdoor",
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
			[18, 12, 2, 1],
			[19, 11, 1, 1],
			[40, 12, 2, 1],
		],
		"platforms": [
			[10, 8, 8], [28, 8, 9], [48, 9, 8],
		],
		"ladders": [
			[9, 8, 5], [27, 8, 5], [47, 9, 4],
			[36, 6, 7, "fence"],
		],
		"windows": [],
		"npcs": [
			{"type": "guard", "x": 24, "y": 13, "patrol": [14, 34]},
			{"type": "guard", "x": 58, "y": 13, "patrol": [50, 67]},
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
			{"type": "locker", "x": 53, "y": 13},
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
