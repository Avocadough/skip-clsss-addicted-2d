extends CanvasLayer
## Full-screen wipe used for every scene change, plus a small "toast" line for
## in-level feedback ("เก็บบัตรห้องพยาบาลแล้ว!").

var _veil: ColorRect
var _toast: Label
var _busy := false

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
	_toast.offset_top = -70
	_toast.offset_bottom = -46
	_toast.modulate.a = 0.0
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	_toast.text = text
	_toast.add_theme_color_override("font_color", color)
	_toast.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_toast, "modulate:a", 1.0, 0.12)
	tw.tween_interval(1.35)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.35)
