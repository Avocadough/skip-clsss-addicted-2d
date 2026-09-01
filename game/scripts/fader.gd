extends CanvasLayer
## Full-screen wipe used for every scene change, plus a small "toast" line for
## in-level feedback ("เก็บบัตรห้องพยาบาลแล้ว!").

var _veil: ColorRect
var _toast: Label
var _busy := false
var _toast_tween: Tween

func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS

	_veil = ColorRect.new()
	_veil.color = Color(0.06, 0.05, 0.09, 1.0)
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_veil)

	_toast = Label.new()
	_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.offset_left = -220
	_toast.offset_right = 220
	# Sits above the bag row so it never lands on the selected-item caption.
	_toast.offset_top = -92
	_toast.offset_bottom = -68
	_toast.modulate.a = 0.0
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Without this the toast falls back to Godot's built-in font, which has no
	# Thai glyphs, so every message came out as boxes.
	_toast.add_theme_font_override("font", UI.font_bold())
	_toast.add_theme_font_size_override("font_size", 15)
	_toast.add_theme_color_override("font_outline_color", Color(0.06, 0.05, 0.09))
	_toast.add_theme_constant_override("outline_size", 5)
	add_child(_toast)

	fade_in(0.45)

func fade_in(dur: float = 0.35) -> void:
	_veil.color.a = 1.0
	var tw := create_tween()
	tw.tween_property(_veil, "color:a", 0.0, dur)

func fade_out(dur: float = 0.3) -> void:
	var tw := create_tween()
	tw.tween_property(_veil, "color:a", 1.0, dur)

func goto(scene_path: String) -> void:
	if _busy:
		return
	_busy = true
	get_tree().paused = false
	fade_out(0.28)
	await get_tree().create_timer(0.30).timeout
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	fade_in(0.28)
	_busy = false

func toast(text: String, color: Color = Color(1, 1, 1)) -> void:
	# Kill any message still fading, otherwise two tweens fight over the same
	# label and the text flickers between them.
	clear_toast()
	_toast.text = text
	_toast.add_theme_color_override("font_color", color)
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.12)
	_toast_tween.tween_interval(1.35)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.35)

## Drops any message on screen at once — used when a results or pause panel
## opens, so a lingering toast does not sit on top of its buttons.
func clear_toast() -> void:
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast.modulate.a = 0.0
