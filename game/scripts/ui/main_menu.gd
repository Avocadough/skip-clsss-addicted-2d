extends Control
## Title screen. The play button jumps straight to the first level the player
## has not cleared yet, so returning players are not made to re-pick.
##
## Laid out in scenes/main_menu.tscn; `build()` is what generated it. The two
## pages behind How to play and About are scenes of their own.

const MODAL := "res://scenes/ui/modal.tscn"
const HOW_TO_BODY := "res://scenes/ui/howto_page.tscn"
const CREDITS_BODY := "res://scenes/ui/about_page.tscn"

@onready var _play: Button = %PlayButton
@onready var _select: Button = %SelectButton
@onready var _how: Button = %HowToButton
@onready var _credits: Button = %CreditsButton
@onready var _music: Button = %MusicButton
@onready var _modals: Control = %ModalHolder

func _ready() -> void:
	var next_level: int = clampi(Game.unlocked, 1, LevelData.count())
	_play.text = "เริ่มเล่น  (ด่าน %d)" % next_level
	_play.pressed.connect(func():
		Game.current_level = next_level
		Fader.goto(LevelData.scene_path(next_level)))

	_select.pressed.connect(func(): Fader.goto("res://scenes/level_select.tscn"))
	_how.pressed.connect(_show_how_to)
	_credits.pressed.connect(_show_credits)

	_refresh_music()
	_music.pressed.connect(func():
		Sfx.set_music_enabled(not Game.music_on)
		_refresh_music())

	_play.call_deferred("grab_focus")
	Sfx.play_music()

func _refresh_music() -> void:
	_music.text = "เพลง: %s" % ("เปิด" if Game.music_on else "ปิด")

# ---------------------------------------------------------------------------
func _modal(title_text: String, body_scene: String, width: float) -> void:
	for c in _modals.get_children():
		c.queue_free()
	var m: Modal = load(MODAL).instantiate()
	_modals.add_child(m)
	m.open(title_text, load(body_scene).instantiate(), width)

func _show_how_to() -> void:
	_modal("วิธีเล่น", HOW_TO_BODY, 440.0)

func _show_credits() -> void:
	_modal("เกี่ยวกับเกม", CREDITS_BODY, 420.0)

# ===========================================================================
static func build() -> Control:
	var menu := Control.new()
	menu.name = "MainMenu"
	menu.set_script(load("res://scripts/ui/main_menu.gd"))
	menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.add_child(load("res://scenes/ui/backdrop.tscn").instantiate())

	var v := VBoxContainer.new()
	v.name = "Column"
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_bottom = -24        # leave the footer strip clear
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 1)
	menu.add_child(v)

	var title := UI.label("เสพติดการโดดเรียน!", 28, UI.CREAM, true)
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_constant_override("outline_size", 9)
	v.add_child(title)

	var sub := UI.label("S K I P   C L A S S   A D D I C T E D", 13, UI.PURPLE, true)
	sub.name = "Subtitle"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)

	var tag := UI.label("\"หนีให้เนียน ซ่อนให้ทัน อย่าให้ใครลากกลับเข้าห้องก่อนกริ่งดัง\"",
		12, Color(0.86, 0.83, 0.92))
	tag.name = "Tagline"
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tag)
	var gap := UI.spacer(5)
	gap.name = "Gap"
	v.add_child(gap)

	var col := VBoxContainer.new()
	col.name = "Buttons"
	col.custom_minimum_size.x = 220
	col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 4)
	v.add_child(col)

	col.add_child(UI.key(UI.button("เริ่มเล่น", 16), "PlayButton"))
	col.add_child(UI.key(UI.button("เลือกด่าน", 15), "SelectButton"))
	col.add_child(UI.key(UI.button("วิธีเล่น", 15), "HowToButton"))
	col.add_child(UI.key(UI.button("เกี่ยวกับเกม", 15), "CreditsButton"))
	col.add_child(UI.key(UI.button("เพลง: เปิด", 14), "MusicButton"))

	# Pinned to the bottom edge rather than sitting in the centred stack, so
	# the title and buttons get the full height to themselves.
	var foot := UI.label("CP410844 Computer Game Development · กลุ่มที่ 19", 11,
		Color(0.72, 0.69, 0.80))
	foot.name = "Footer"
	foot.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	foot.offset_left = -220
	foot.offset_right = 220
	foot.offset_top = -20
	foot.offset_bottom = -4
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(foot)

	var holder := Control.new()
	UI.key(holder, "ModalHolder")
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(holder)
	return menu

## The How to play table — its own scene so the key list can be edited without
## going anywhere near the menu code.
static func build_how_to() -> Control:
	var v := VBoxContainer.new()
	v.name = "HowToPage"
	v.add_theme_constant_override("separation", 1)
	for r in [
		["A / D หรือ ลูกศร ซ้าย-ขวา", "เดินซ้าย-ขวา"],
		["Shift (ค้าง)", "วิ่ง — เร็วขึ้นแต่เสียงดังมาก"],
		["Space / W", "กระโดด"],
		["S หรือ ลูกศรลง", "ก้มหมอบ — ช้าแต่เงียบและถูกเห็นยากขึ้น"],
		["W หรือ ลูกศรขึ้น (ที่บันได/รั้ว)", "ปีนขึ้น-ลง"],
		["E", "ซ่อนตัว / ออกจากที่ซ่อน / เปิดประตูด้วยกุญแจ"],
		["Q", "ใช้ไอเทมที่เลือกอยู่"],
		["F", "สลับไอเทมในกระเป๋า"],
		["R", "เริ่มด่านใหม่"],
		["Esc", "หยุดชั่วคราว"],
	]:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		var k := UI.label(r[0], 10, UI.YELLOW, true)
		k.custom_minimum_size.x = 158
		h.add_child(k)
		h.add_child(UI.label(r[1], 10, Color(0.86, 0.84, 0.9)))
		v.add_child(h)
	v.add_child(UI.spacer(4))
	var note := UI.label("เดินไปโดนไอเทมเพื่อเก็บอัตโนมัติ  กรวยสีเหลืองคือระยะสายตา NPC",
		10, UI.PURPLE)
	note.name = "Note"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size.x = 380
	v.add_child(note)
	return v

static func build_credits() -> Control:
	var v := VBoxContainer.new()
	v.name = "CreditsPage"
	v.add_theme_constant_override("separation", 3)
	for line in [
		"รายวิชา CP410844 Computer Game Development",
		"ภาคการศึกษาต้น ปีการศึกษา 2569 — กลุ่มที่ 19",
		"",
		"1. กษิเดช สุขศีล        663380252-6",
		"2. ภูริณัฐ ศรีไตรรัตน์    663380531-2",
		"3. ณภัตร ช้อยกิ่ง        663380262-3",
		"",
		"แนว: 2D Pixel Art Stealth-Puzzle Platformer",
	]:
		var l := UI.label(line, 11, Color(0.88, 0.85, 0.93))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	return v
