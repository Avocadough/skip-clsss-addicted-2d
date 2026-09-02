extends Control
## Stage picker: one card per stage from section 8 of the design document,
## showing its best rank and best remaining time once cleared.

func _ready() -> void:
	add_child(MenuBackdrop.new())
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_top = 8
	root.offset_bottom = -8
	root.offset_left = 16
	root.offset_right = -16
	root.add_theme_constant_override("separation", 4)
	add_child(root)

	var title := UI.label("เลือกด่าน", 22, UI.CREAM, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(row)

	var first_playable: Button = null
	for i in range(1, LevelData.count() + 1):
		var card := _make_card(i)
		row.add_child(card)
		if first_playable == null and i <= Game.unlocked:
			first_playable = card.get_meta("button")

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 8)
	root.add_child(bottom)

	var back := UI.button("« กลับหน้าแรก", 14)
	back.custom_minimum_size.x = 170
	back.pressed.connect(func(): Fader.goto("res://scenes/main_menu.tscn"))
	bottom.add_child(back)

	if Game.unlocked > 1 or not Game.best_rank.is_empty():
		var reset := UI.button("ล้างความคืบหน้า", 14)
		reset.custom_minimum_size.x = 170
		reset.pressed.connect(func():
			Game.wipe_save()
			Fader.goto("res://scenes/level_select.tscn"))
		bottom.add_child(reset)

	if Game.all_cleared():
		var done := UI.label("• เคลียร์ครบทุกด่านแล้ว — โดดเรียนระดับตำนาน •", 13, UI.YELLOW, true)
		done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		root.add_child(done)

	if first_playable != null:
		first_playable.call_deferred("grab_focus")
	Sfx.play_music()

func _make_card(index: int) -> Control:
	var d := LevelData.get_level(index)
	var locked := index > Game.unlocked
	var rank: String = Game.best_rank.get(index, "")
	var dim := Color(0.45, 0.42, 0.52)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UI.panel_style(
		Color(0.10, 0.085, 0.15, 0.95) if not locked else Color(0.08, 0.07, 0.11, 0.9),
		UI.CREAM if not locked else Color(0.30, 0.28, 0.36), 2, 6, 5))
	card.custom_minimum_size = Vector2(84, 0)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	card.add_child(v)

	var num := UI.label("ด่าน %d" % index, 14, UI.PURPLE if not locked else dim, true)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(num)

	var name_l := UI.label(d["name"] if not locked else "ยังไม่ปลดล็อก", 10,
		UI.WHITE if not locked else dim)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_l.custom_minimum_size = Vector2(70, 26)
	v.add_child(name_l)

	if not locked:
		var en := UI.label(d["en"], 8, Color(0.66, 0.63, 0.75))
		en.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		en.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		en.custom_minimum_size.x = 70
		v.add_child(en)
		var time_l := UI.label("เวลา %d วิ" % int(d["time"]), 9, Color(0.78, 0.75, 0.85))
		time_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(time_l)

	# Badge row: the earned rank, a greyed-out key for a stage still locked,
	# or a dash for one that is open but not cleared yet.
	var badge := CenterContainer.new()
	badge.custom_minimum_size.y = 26
	if rank != "":
		badge.add_child(UI.label(rank, 22, UI.rank_color(rank), true))
	elif locked:
		var key := UI.icon("item_key", 18)
		key.modulate = Color(0.42, 0.39, 0.50)
		badge.add_child(key)
	else:
		badge.add_child(UI.label("—", 18, Color(0.42, 0.39, 0.50), true))
	v.add_child(badge)

	var best := UI.label(
		"เหลือ %.1f วิ" % float(Game.best_time.get(index, 0.0)) if rank != "" else " ",
		8, Color(0.72, 0.70, 0.80))
	best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(best)

	var b := UI.button("เล่น" if not locked else "ล็อก", 12)
	b.disabled = locked
	if not locked:
		b.pressed.connect(func():
			Game.current_level = index
			Fader.goto(LevelData.scene_path(index)))
	v.add_child(b)
	card.set_meta("button", b)
	return card
