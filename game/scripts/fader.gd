extends CanvasLayer
## Full-screen wipe used for every scene change, plus a small "toast" line for
## in-level feedback ("เก็บบัตรห้องพยาบาลแล้ว!").
##
## Autoloaded from scenes/ui/fader.tscn; `build()` is what generated it.

@onready var _veil: ColorRect = %Veil
@onready var _toast: Label = %Toast

var _busy := false
var _toast_tween: Tween

func _ready() -> void:
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

# ===========================================================================
static func build() -> CanvasLayer:
	var f := CanvasLayer.new()
	f.name = "Fader"
	f.set_script(load("res://scripts/fader.gd"))
	f.layer = 128
	f.process_mode = Node.PROCESS_MODE_ALWAYS

	var veil := ColorRect.new()
	UI.key(veil, "Veil")
	veil.color = Color(0.06, 0.05, 0.09, 1.0)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.add_child(veil)

	var toast := Label.new()
	UI.key(toast, "Toast")
	toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.offset_left = -220
	toast.offset_right = 220
	# Sits above the bag row so it never lands on the selected-item caption.
	toast.offset_top = -92
	toast.offset_bottom = -68
	toast.modulate.a = 0.0
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Without this the toast falls back to the built-in font of Godot, which
	# has no Thai glyphs, so every message came out as boxes.
	toast.add_theme_font_override("font", UI.font_bold())
	toast.add_theme_font_size_override("font_size", 15)
	toast.add_theme_color_override("font_outline_color", Color(0.06, 0.05, 0.09))
	toast.add_theme_constant_override("outline_size", 5)
	f.add_child(toast)
	return f
