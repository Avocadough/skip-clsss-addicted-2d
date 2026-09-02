class_name ExcuseDialogue
extends CanvasLayer
## "Excuse Dialogue" — when the class monitor corners you, buy time by picking
## the right excuse. Carrying the fake homework or a nurse pass gives you a
## guaranteed way out, at the cost of the item.
##
## Laid out in scenes/ui/dialogue.tscn. The answers vary from one encounter to
## the next, so those buttons are added to Column when the dialogue opens.

const ANSWER := "res://scenes/ui/answer_button.tscn"

signal resolved(good: bool, used_item: String)

@onready var _vbox: VBoxContainer = %Column
@onready var _question: Label = %QuestionLabel
@onready var _npc_label: Label = %NpcLabel

var _answered := false

func _exit_tree() -> void:
	# The dialogue pauses the tree while it is open. If it ever goes away
	# without being answered — a restart, a scene change — make sure the game
	# does not stay frozen behind it.
	if not _answered and is_inside_tree():
		get_tree().paused = false

func open(npc_name: String, entry: Dictionary, inventory: Array[String]) -> void:
	_npc_label.text = npc_name
	_question.text = "\"%s\"" % entry["q"]

	var answer_scene: PackedScene = load(ANSWER)
	var answers: Array = entry["a"]
	var good_index: int = entry["good"]
	for i in answers.size():
		var b: Button = answer_scene.instantiate()
		b.text = "%d.  %s" % [i + 1, answers[i]]
		var idx := i
		b.pressed.connect(func(): _answer(idx == good_index, ""))
		_vbox.add_child(b)

	# item shortcuts
	for shortcut in [
		{"id": "notebook", "text": "•  ยื่นสมุดการบ้านปลอม \"เอางานไปส่งครับ\""},
		{"id": "nursecard", "text": "•  ยื่นบัตรห้องพยาบาล \"ครูให้ไปห้องพยาบาล\""},
	]:
		if not inventory.has(shortcut["id"]):
			continue
		var b2: Button = answer_scene.instantiate()
		b2.text = shortcut["text"]
		b2.add_theme_color_override("font_color", UI.YELLOW)
		var id: String = shortcut["id"]
		b2.pressed.connect(func(): _answer(true, id))
		_vbox.add_child(b2)

	for c in _vbox.get_children():
		if c is Button:
			(c as Button).call_deferred("grab_focus")
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

# ===========================================================================
static func build() -> ExcuseDialogue:
	var dlg := ExcuseDialogue.new()
	dlg.name = "ExcuseDialogue"
	dlg.layer = 40
	dlg.process_mode = Node.PROCESS_MODE_ALWAYS

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.05, 0.04, 0.08, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dlg.add_child(dim)

	var box := UI.panel(Color(0.10, 0.085, 0.15, 0.98), UI.PINK)
	box.name = "Box"
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -200
	box.offset_right = 200
	box.offset_top = -104
	box.offset_bottom = 104
	dlg.add_child(box)

	var v := VBoxContainer.new()
	UI.key(v, "Column")
	v.add_theme_constant_override("separation", 7)
	box.add_child(v)

	v.add_child(UI.key(UI.label("", 13, UI.PINK, true), "NpcLabel"))

	var q := UI.label("", 16, UI.WHITE, true)
	UI.key(q, "QuestionLabel")
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	q.custom_minimum_size.x = 370
	v.add_child(q)

	var gap := UI.spacer(4)
	gap.name = "Gap"
	v.add_child(gap)
	return dlg

## One answer. Its own scene because how many there are depends on which
## excuse came up.
static func build_answer() -> Button:
	var b := UI.button("", 14)
	b.name = "AnswerButton"
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return b
