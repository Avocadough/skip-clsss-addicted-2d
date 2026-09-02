extends Control
## Splash gate. Browsers refuse to start audio until the player interacts with
## the page, so the web build needs one click before the music can begin.
##
## Laid out in scenes/boot.tscn; `build()` is what generated it.

@onready var _hint: Label = %Hint

var _t := 0.0
var _went := false

func _process(delta: float) -> void:
	_t += delta
	_hint.modulate.a = 0.55 + sin(_t * 3.4) * 0.45

func _unhandled_input(event: InputEvent) -> void:
	if _went:
		return
	var go: bool = (event is InputEventKey and event.pressed) \
		or (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed)
	if not go:
		return
	_went = true
	Sfx.play("click")
	Sfx.play_music()
	Fader.goto("res://scenes/main_menu.tscn")

# ===========================================================================
static func build() -> Control:
	var boot := Control.new()
	boot.name = "Boot"
	boot.set_script(load("res://scripts/ui/boot.gd"))
	boot.set_anchors_preset(Control.PRESET_FULL_RECT)
	# let clicks fall through to _unhandled_input so tapping anywhere starts it
	boot.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color("14101f")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boot.add_child(bg)

	var v := VBoxContainer.new()
	v.name = "Column"
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 6)
	boot.add_child(v)

	var bell := UI.icon("prop_bell", 48)
	bell.name = "Bell"
	bell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(bell)

	var t := UI.label("เสพติดการโดดเรียน!", 34, UI.CREAM, true)
	t.name = "Title"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)

	var s := UI.label("Skip Class Addicted", 13, UI.PURPLE, true)
	s.name = "Subtitle"
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)
	var gap := UI.spacer(18)
	gap.name = "Gap"
	v.add_child(gap)

	var hint := UI.label("คลิกหรือกดปุ่มใดก็ได้เพื่อเริ่ม", 16, UI.WHITE, true)
	UI.key(hint, "Hint")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)
	return boot
