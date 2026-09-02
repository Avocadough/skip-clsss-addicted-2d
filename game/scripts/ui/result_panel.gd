class_name ResultPanel
extends CanvasLayer
## The card that closes a stage — cleared, with a grade and a breakdown, or
## caught, with the reason. The level decides what the buttons do.

signal next_pressed
signal retry_pressed
signal menu_pressed

## The design viewport is only 270px tall, and a cleared stage shows a title,
## a grade, three result lines and three buttons. Padding and row spacing are
## trimmed to what makes that fit with the border still on screen.
const PAD_H := 10
const PAD_V := 4
const ROW_GAP := 4

@onready var _box: PanelContainer = %Box
@onready var _title: Label = %Title
@onready var _subtitle: Label = %Subtitle
@onready var _lines: VBoxContainer = %Lines
@onready var _next: Button = %NextButton
@onready var _retry: Button = %RetryButton
@onready var _menu: Button = %MenuButton

func _ready() -> void:
	_next.pressed.connect(func(): next_pressed.emit())
	_retry.pressed.connect(func(): retry_pressed.emit())
	_menu.pressed.connect(func(): menu_pressed.emit())

func show_result(title: String, subtitle: String, lines: Array,
		accent: Color, show_next: bool) -> void:
	_box.add_theme_stylebox_override("panel", UI.panel_style(
		Color(0.10, 0.085, 0.15, 0.98), accent, 2, PAD_H, PAD_V))
	_title.text = title
	_title.add_theme_color_override("font_color", accent)
	_subtitle.text = subtitle

	for c in _lines.get_children():
		c.queue_free()
	for line in lines:
		var l := UI.label(line, 13, Color(0.82, 0.79, 0.88))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_lines.add_child(l)

	_next.visible = show_next
	(_next if show_next else _retry).call_deferred("grab_focus")

# ===========================================================================
static func build() -> ResultPanel:
	var panel := ResultPanel.new()
	panel.name = "ResultPanel"
	panel.layer = 30
	panel.process_mode = Node.PROCESS_MODE_ALWAYS

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.05, 0.04, 0.08, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(dim)

	# A CenterContainer lets the card take its own height. Pinning it instead
	# pushed the last button off the bottom of the screen once a stage had
	# three result lines to show.
	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(center)

	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UI.panel_style(
		Color(0.10, 0.085, 0.15, 0.98), UI.CREAM, 2, PAD_H, PAD_V))
	UI.key(box, "Box")
	box.custom_minimum_size.x = 360
	center.add_child(box)

	var v := VBoxContainer.new()
	v.name = "Column"
	v.add_theme_constant_override("separation", ROW_GAP)
	box.add_child(v)

	var t := UI.label("", 24, UI.CREAM, true)
	UI.key(t, "Title")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)

	var st := UI.label("", 14, UI.WHITE, true)
	UI.key(st, "Subtitle")
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	st.custom_minimum_size.x = 330
	v.add_child(st)
	var gap := UI.spacer(2)
	gap.name = "Gap"
	v.add_child(gap)

	# Filled on show: how much time was left, how often you were spotted.
	var lines := VBoxContainer.new()
	UI.key(lines, "Lines")
	v.add_child(lines)
	var gap2 := UI.spacer(6)
	gap2.name = "Gap2"
	v.add_child(gap2)

	v.add_child(UI.key(UI.button("ไปด่านต่อไป »", 15), "NextButton"))
	v.add_child(UI.key(UI.button("เล่นด่านนี้ใหม่", 14), "RetryButton"))
	v.add_child(UI.key(UI.button("กลับไปเลือกด่าน", 14), "MenuButton"))
	return panel
