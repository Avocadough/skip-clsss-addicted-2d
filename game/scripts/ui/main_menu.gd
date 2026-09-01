extends Control
## Title screen. The play button jumps straight to the first level the player
## has not cleared yet, so returning players are not made to re-pick.

var _panel_holder: Control

func _ready() -> void:
	add_child(MenuBackdrop.new())
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 3)
	add_child(v)

	var title := UI.label("เสพติดการโดดเรียน!", 40, UI.CREAM, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_constant_override("outline_size", 9)
	v.add_child(title)

	var sub := UI.label("S K I P   C L A S S   A D D I C T E D", 13, UI.PURPLE, true)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)

	var tag := UI.label("\"หนีให้เนียน ซ่อนให้ทัน อย่าให้ใครลากกลับเข้าห้องก่อนกริ่งดัง\"",
		12, Color(0.86, 0.83, 0.92))
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tag)
	v.add_child(UI.spacer(14))

	var col := VBoxContainer.new()
	col.custom_minimum_size.x = 220
	col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 5)
	v.add_child(col)

	var next_level: int = clampi(Game.unlocked, 1, LevelData.count())
	var play := UI.button("▶  เริ่มเล่น  (ด่าน %d)" % next_level, 16)
	play.pressed.connect(func():
		Game.current_level = next_level
		Fader.goto("res://scenes/level.tscn"))
	col.add_child(play)

	var sel := UI.button("เลือกด่าน", 15)
	sel.pressed.connect(func(): Fader.goto("res://scenes/level_select.tscn"))
	col.add_child(sel)

	var how := UI.button("วิธีเล่น", 15)
	how.pressed.connect(_show_how_to)
	col.add_child(how)

	var cred := UI.button("เกี่ยวกับเกม", 15)
	cred.pressed.connect(_show_credits)
	col.add_child(cred)

	var music := UI.button("เพลง: %s" % ("เปิด" if Game.music_on else "ปิด"), 14)
	music.pressed.connect(func():
		Sfx.set_music_enabled(not Game.music_on)
		music.text = "เพลง: %s" % ("เปิด" if Game.music_on else "ปิด"))
	col.add_child(music)

	v.add_child(UI.spacer(10))
	var foot := UI.label("CP410844 Computer Game Development · กลุ่มที่ 19", 11,
		Color(0.72, 0.69, 0.80))
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(foot)

	_panel_holder = Control.new()
	_panel_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel_holder)

	play.grab_focus()
	Sfx.play_music()

# ---------------------------------------------------------------------------
func _modal(title_text: String, body: Control, width: float = 400.0) -> void:
	for c in _panel_holder.get_children():
		c.queue_free()

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.04, 0.08, 0.80)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel_holder.add_child(dim)

	var box := UI.panel(Color(0.10, 0.085, 0.15, 0.99), UI.CREAM)
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -width / 2.0
	box.offset_right = width / 2.0
	box.offset_top = -125
	box.offset_bottom = 125
	_panel_holder.add_child(box)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	box.add_child(v)

	var t := UI.label(title_text, 20, UI.CREAM, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	v.add_child(body)
	v.add_child(UI.spacer(4))

	var close := UI.button("ปิด", 14)
	close.pressed.connect(func():
		for c in _panel_holder.get_children():
			c.queue_free())
	v.add_child(close)
	close.grab_focus()

func _show_how_to() -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	var rows := [
		["A / D  หรือ  ← →", "เดินซ้าย-ขวา"],
		["Shift (ค้าง)", "วิ่ง — เร็วขึ้นแต่เสียงดังมาก"],
		["Space / W", "กระโดด"],
		["S / ↓", "ก้มหมอบ — ช้าแต่เงียบและถูกเห็นยากขึ้น"],
		["W / ↑ ที่บันไดหรือรั้ว", "ปีนขึ้น-ลง"],
		["E", "ซ่อนตัว / ออกจากที่ซ่อน / เปิดประตูด้วยกุญแจ"],
		["Q", "ใช้ไอเทมที่เลือกอยู่"],
		["F", "สลับไอเทมในกระเป๋า"],
		["R", "เริ่มด่านใหม่"],
		["Esc", "หยุดชั่วคราว"],
	]
	for r in rows:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		var k := UI.label(r[0], 12, UI.YELLOW, true)
		k.custom_minimum_size.x = 150
		h.add_child(k)
		h.add_child(UI.label(r[1], 12, Color(0.86, 0.84, 0.9)))
		v.add_child(h)
	v.add_child(UI.spacer(4))
	var note := UI.label("เดินไปโดนไอเทมเพื่อเก็บอัตโนมัติ · กรวยสีเหลืองคือระยะสายตา NPC",
		11, UI.PURPLE)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size.x = 380
	v.add_child(note)
	_modal("วิธีเล่น", v, 430.0)

func _show_credits() -> void:
	var v := VBoxContainer.new()
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
		"สร้างด้วย Godot Engine 4.7 · ฟอนต์ Noto Sans Thai (OFL)",
	]:
		var l := UI.label(line, 12, Color(0.88, 0.85, 0.93))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	_modal("เกี่ยวกับเกม", v, 420.0)
