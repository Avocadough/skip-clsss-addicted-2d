class_name Modal
extends Control
## The dim-and-panel frame the menu screens put their How to play and About
## pages in. The page itself is a separate scene dropped into Body, so the
## frame knows nothing about what it is showing.

@onready var _title: Label = %ModalTitle
@onready var _body: VBoxContainer = %Body
@onready var _box: PanelContainer = %Box
@onready var _close: Button = %CloseButton

func _ready() -> void:
	_close.pressed.connect(queue_free)
	_close.call_deferred("grab_focus")

func open(title_text: String, body: Control, width: float = 400.0) -> void:
	_title.text = title_text
	_box.custom_minimum_size.x = width
	_body.add_child(body)

# ===========================================================================
static func build() -> Control:
	var m := Control.new()
	m.name = "Modal"
	m.set_script(load("res://scripts/ui/modal.gd"))
	m.set_anchors_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.05, 0.04, 0.08, 0.80)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	m.add_child(dim)

	# A CenterContainer lets the panel take its own minimum height. Pinning the
	# height instead made tall content spill past the close button.
	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(center)

	var box := PanelContainer.new()
	UI.key(box, "Box")
	box.add_theme_stylebox_override("panel", UI.panel_style(
		Color(0.10, 0.085, 0.15, 0.99), UI.CREAM, 2, 12, 6))
	box.custom_minimum_size.x = 400.0
	center.add_child(box)

	var v := VBoxContainer.new()
	v.name = "Column"
	v.add_theme_constant_override("separation", 2)
	box.add_child(v)

	var t := UI.label("", 18, UI.CREAM, true)
	UI.key(t, "ModalTitle")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)

	var body := VBoxContainer.new()
	UI.key(body, "Body")
	v.add_child(body)

	var gap := UI.spacer(4)
	gap.name = "Gap"
	v.add_child(gap)

	var close := UI.button("ปิด", 14)
	UI.key(close, "CloseButton")
	v.add_child(close)
	return m
