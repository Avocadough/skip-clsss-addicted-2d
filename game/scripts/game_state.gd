extends Node
## Global game state: level progress, run statistics and the shared data
## tables (items, excuses) that the levels and UI both read from.

const SAVE_PATH := "user://skipclass_save.cfg"
const LEVEL_COUNT := 5

signal progress_changed

# --- persistent -------------------------------------------------------------
var unlocked: int = 1                  ## highest level index the player may enter (1-based)
var best_rank: Dictionary = {}         ## level index -> rank string ("S".."C")
var best_time: Dictionary = {}         ## level index -> seconds remaining at clear
var total_coins: int = 0
var music_on: bool = true
var sfx_on: bool = true

# --- current run ------------------------------------------------------------
var current_level: int = 1
var run_times_seen: int = 0
var run_peak_suspicion: float = 0.0
var run_time_left: float = 0.0
var last_rank: String = "C"
var last_fail_reason: String = ""

# ---------------------------------------------------------------------------
#  Items ("ไอเทมตัวอย่าง" from the design document)
# ---------------------------------------------------------------------------
const ITEMS := {
	"nursecard": {
		"name": "บัตรห้องพยาบาล",
		"en": "Nurse Pass",
		"icon": "item_nursecard",
		"desc": "ลดความสงสัย 35% ทันที",
		"hint": "ใช้ตอนโดนจ้อง เพื่อยืนยันว่าไปห้องพยาบาลจริง",
	},
	"coin": {
		"name": "เหรียญ 10 บาท",
		"en": "10-Baht Coin",
		"icon": "item_coin",
		"desc": "โยนไปไกล ๆ เพื่อล่อให้ NPC เดินไปดู",
		"hint": "ใช้ดึงครูออกจากทางที่เราจะผ่าน",
	},
	"notebook": {
		"name": "สมุดการบ้านปลอม",
		"en": "Fake Homework",
		"icon": "item_notebook",
		"desc": "ชนะบทสนทนากับหัวหน้าห้องอัตโนมัติ",
		"hint": "อ้างว่ากำลังเอางานไปส่งครู",
	},
	"key": {
		"name": "กุญแจห้องเก็บของ",
		"en": "Storage Key",
		"icon": "item_key",
		"desc": "ปลดล็อกประตูทางลัด",
		"hint": "เดินไปที่ประตูที่ล็อกแล้วกด E",
	},
	"wetsign": {
		"name": "ป้ายพื้นเปียก",
		"en": "Wet Floor Sign",
		"icon": "item_wetsign",
		"desc": "วางแล้ว NPC จะหันกลับไม่เดินผ่าน 12 วินาที",
		"hint": "วางขวางทางเดินตรวจของครู",
	},
	"hoodie": {
		"name": "ฮู้ดกันหนาว",
		"en": "Hoodie",
		"icon": "item_hoodie",
		"desc": "ปลอมตัว 9 วินาที NPC จะจำไม่ได้",
		"hint": "ใส่ตอนต้องเดินผ่านที่โล่ง",
	},
}

# ---------------------------------------------------------------------------
#  Excuse dialogue ("Excuse Dialogue" system).
#  Each entry: the NPC question plus three answers. `good` is the answer that
#  actually fits the situation; the others raise suspicion.
# ---------------------------------------------------------------------------
const EXCUSES := [
	{
		"q": "จะไปไหนน่ะ? คาบแรกจะเริ่มแล้วนะ",
		"a": ["ไปห้องน้ำแป๊บเดียว", "ก็...เดินเล่นอ่ะ", "ไม่ใช่เรื่องของเธอ"],
		"good": 0,
	},
	{
		"q": "เมื่อกี้เห็นเธอวิ่งนี่ วิ่งทำไม?",
		"a": ["เปล่านะ เดินเฉย ๆ", "ครูเรียกไปห้องพักครู", "หนีเรียนไง ทำไม"],
		"good": 1,
	},
	{
		"q": "ทำไมไม่อยู่ในห้องเรียน?",
		"a": ["ลืมของไว้ที่โรงอาหาร", "เอางานไปส่งครูอยู่", "ห้องมันร้อนอ่ะ"],
		"good": 1,
	},
	{
		"q": "ขอดูบัตรนักเรียนหน่อยสิ",
		"a": ["ลืมไว้ที่บ้านครับ", "อยู่ในกระเป๋าที่ห้อง เดี๋ยวไปเอา", "ไม่ให้ดู"],
		"good": 1,
	},
	{
		"q": "เธอดูไม่ค่อยสบายนะ เป็นอะไรรึเปล่า?",
		"a": ["ปวดหัวครับ จะไปห้องพยาบาล", "สบายดีมาก ๆ เลย!", "ง่วงนอนอ่ะ"],
		"good": 0,
	},
]

# ---------------------------------------------------------------------------
func _ready() -> void:
	load_game()

func rank_for(time_left: float, time_total: float, seen: int, peak_susp: float) -> String:
	## Rating blends how much of the clock was left, how often the player was
	## spotted, and how close suspicion ever got to full — "คะแนนความเนียน".
	var t := clampf(time_left / maxf(time_total, 1.0), 0.0, 1.0)
	var score := t * 55.0
	score += maxf(0.0, 30.0 - seen * 10.0)
	score += (1.0 - clampf(peak_susp / 100.0, 0.0, 1.0)) * 15.0
	if score >= 82.0:
		return "S"
	elif score >= 66.0:
		return "A"
	elif score >= 48.0:
		return "B"
	return "C"

func complete_level(level: int, rank: String, time_left: float) -> void:
	var order := {"C": 0, "B": 1, "A": 2, "S": 3}
	if not best_rank.has(level) or order[rank] > order.get(best_rank[level], 0):
		best_rank[level] = rank
	if not best_time.has(level) or time_left > float(best_time[level]):
		best_time[level] = time_left
	if level + 1 > unlocked and level < LEVEL_COUNT:
		unlocked = level + 1
	save_game()
	progress_changed.emit()

func reset_run() -> void:
	run_times_seen = 0
	run_peak_suspicion = 0.0
	last_fail_reason = ""

func all_cleared() -> bool:
	for i in range(1, LEVEL_COUNT + 1):
		if not best_rank.has(i):
			return false
	return true

# ---------------------------------------------------------------------------
func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked", unlocked)
	cfg.set_value("progress", "best_rank", best_rank)
	cfg.set_value("progress", "best_time", best_time)
	cfg.set_value("progress", "coins", total_coins)
	cfg.set_value("options", "music", music_on)
	cfg.set_value("options", "sfx", sfx_on)
	cfg.save(SAVE_PATH)

func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	unlocked = cfg.get_value("progress", "unlocked", 1)
	best_rank = cfg.get_value("progress", "best_rank", {})
	best_time = cfg.get_value("progress", "best_time", {})
	total_coins = cfg.get_value("progress", "coins", 0)
	music_on = cfg.get_value("options", "music", true)
	sfx_on = cfg.get_value("options", "sfx", true)

func wipe_save() -> void:
	unlocked = 1
	best_rank = {}
	best_time = {}
	total_coins = 0
	save_game()
	progress_changed.emit()
