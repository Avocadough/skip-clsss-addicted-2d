class_name PausePanel
extends CanvasLayer
## Esc menu. Owns the music toggle itself; the level decides what resume,
## restart and back do, since only it knows which stage it is.

signal resume_pressed
signal restart_pressed
signal menu_pressed

@onready var _goal: Label = %GoalLabel
@onready var _resume: Button = %ResumeButton
@onready var _restart: Button = %RestartButton
@onready var _music: Button = %MusicButton
@onready var _back: Button = %BackButton

func _ready() -> void:
	_resume.pressed.connect(func(): resume_pressed.emit())
	_restart.pressed.connect(func(): restart_pressed.emit())
	_back.pressed.connect(func(): menu_pressed.emit())
	_refresh_music()
	_music.pressed.connect(func():
		Sfx.set_music_enabled(not Game.music_on)
		_refresh_music())
	_resume.call_deferred("grab_focus")

func _refresh_music() -> void:
	_music.text = "เพลง: %s" % ("เปิด" if Game.music_on else "ปิด")

func setup(goal_text: String) -> void:
	_goal.text = goal_text

# ===========================================================================
static func build() -> PausePanel:
	var panel := PausePanel.new()
	panel.name = "PausePanel"
	panel.layer = 30
	panel.process_mode = Node.PROCESS_MODE_ALWAYS

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.05, 0.04, 0.08, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(dim)

	var box := UI.panel(Color(0.10, 0.085, 0.15, 0.98), UI.PURPLE)
	box.name = "Box"
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -160
	box.offset_right = 160
	box.offset_top = -120
	box.offset_bottom = 120
	panel.add_child(box)

	var v := VBoxContainer.new()
	v.name = "Column"
	v.add_theme_constant_override("separation", 6)
	box.add_child(v)

	var t := UI.label("หยุดชั่วคราว", 22, UI.PURPLE, true)
	t.name = "Title"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)

	var g := UI.label("", 12, Color(0.82, 0.79, 0.88))
	UI.key(g, "GoalLabel")
	g.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	g.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	g.custom_minimum_size.x = 290
	v.add_child(g)
	var gap := UI.spacer(4)
	gap.name = "Gap"
	v.add_child(gap)

	v.add_child(UI.key(UI.button("เล่นต่อ", 15), "ResumeButton"))
	v.add_child(UI.key(UI.button("เริ่มด่านนี้ใหม่", 14), "RestartButton"))
	v.add_child(UI.key(UI.button("เพลง: เปิด", 14), "MusicButton"))
	v.add_child(UI.key(UI.button("กลับไปเลือกด่าน", 14), "BackButton"))
	return panel
