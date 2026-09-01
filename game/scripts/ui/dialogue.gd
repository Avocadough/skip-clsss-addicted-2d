class_name ExcuseDialogue
extends CanvasLayer
## "Excuse Dialogue" — when the class monitor corners you, buy time by picking
## the right excuse. Carrying the fake homework or a nurse pass gives you a
## guaranteed way out, at the cost of the item.

signal resolved(good: bool, used_item: String)

var _vbox: VBoxContainer
var _question: Label
var _npc_label: Label
var _answered := false

func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS

func open(npc_name: String, entry: Dictionary, inventory: Array[String]) -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.04, 0.08, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var box := UI.panel(Color(0.10, 0.085, 0.15, 0.98), UI.PINK)
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -200
	box.offset_right = 200
	box.offset_top = -104
	box.offset_bottom = 104
	add_child(box)

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 7)
	box.add_child(_vbox)

	_npc_label = UI.label(npc_name, 13, UI.PINK, true)
	_vbox.add_child(_npc_label)

	_question = UI.label("\"%s\"" % entry["q"], 16, UI.WHITE, true)
	_question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_question.custom_minimum_size.x = 370
	_vbox.add_child(_question)
	_vbox.add_child(UI.spacer(4))

	var answers: Array = entry["a"]
	var good_index: int = entry["good"]
	for i in answers.size():
		var b := UI.button("%d.  %s" % [i + 1, answers[i]], 14)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var idx := i
		b.pressed.connect(func(): _answer(idx == good_index, ""))
		_vbox.add_child(b)

	# item shortcuts
	if inventory.has("notebook"):
		var b2 := UI.button("★  ยื่นสมุดการบ้านปลอม \"เอางานไปส่งครับ\"", 14)
		b2.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b2.add_theme_color_override("font_color", UI.YELLOW)
		b2.pressed.connect(func(): _answer(true, "notebook"))
		_vbox.add_child(b2)
	if inventory.has("nursecard"):
		var b3 := UI.button("★  ยื่นบัตรห้องพยาบาล \"ครูให้ไปห้องพยาบาล\"", 14)
		b3.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b3.add_theme_color_override("font_color", UI.YELLOW)
		b3.pressed.connect(func(): _answer(true, "nursecard"))
		_vbox.add_child(b3)

	for c in _vbox.get_children():
		if c is Button:
			(c as Button).grab_focus()
			break

	get_tree().paused = true
	Sfx.play("blip")

func _unhandled_input(event: InputEvent) -> void:
	if _answered or not (event is InputEventKey and event.pressed):
		return
	var k := (event as InputEventKey).keycode
	if k >= KEY_1 and k <= KEY_5:
		var want := k - KEY_1
		var n := 0
		for c in _vbox.get_children():
			if c is Button:
				if n == want:
					(c as Button).emit_signal("pressed")
					get_viewport().set_input_as_handled()
					return
				n += 1

func _answer(good: bool, used_item: String) -> void:
	if _answered:
		return
	_answered = true
	Sfx.play("pickup" if good else "spotted")
	get_tree().paused = false
	resolved.emit(good, used_item)
	queue_free()
