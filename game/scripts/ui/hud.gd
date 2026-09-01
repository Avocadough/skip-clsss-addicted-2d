class_name Hud
extends CanvasLayer
## In-level heads-up display: the countdown to the bell, the suspicion meter,
## the school-bag inventory and the contextual action prompt.

var _time_label: Label
var _time_icon: TextureRect
var _name_label: Label
var _susp_fill: ColorRect
var _susp_label: Label
var _susp_panel: PanelContainer
var _slots: HBoxContainer
var _prompt: Label
var _prompt_box: PanelContainer
var _objective: Label
var _objective_box: PanelContainer
var _item_name: Label
var _flash: ColorRect

var _susp_max_w := 96.0

func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# ---------------------------------------------------------- top: clock --
	var top_left := UI.panel(Color(0.09, 0.075, 0.13, 0.85))
	top_left.position = Vector2(8, 6)
	top_left.add_theme_stylebox_override("panel", UI.panel_style(Color(0.09, 0.075, 0.13, 0.85), UI.CREAM))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	_time_icon = UI.icon("prop_clock", 16)
	hb.add_child(_time_icon)
	_time_label = UI.label("01:00", 18, UI.CREAM, true)
	hb.add_child(_time_label)
	# The stage name rides along in the same bar, which keeps it clear of the
	# suspicion meter on the right at the game's 480px design width.
	var divider := UI.label("│", 15, Color(0.45, 0.41, 0.55))
	hb.add_child(divider)
	_name_label = UI.label("", 13, UI.WHITE, true)
	hb.add_child(_name_label)
	top_left.add_child(hb)
	root.add_child(top_left)

	# --------------------------------------------- top right: suspicion bar --
	_susp_panel = UI.panel(Color(0.09, 0.075, 0.13, 0.85))
	_susp_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_susp_panel.offset_left = -178
	_susp_panel.offset_right = -8
	_susp_panel.offset_top = 6
	var sv := HBoxContainer.new()
	sv.add_theme_constant_override("separation", 6)
	sv.add_child(UI.icon("icon_eye", 16))

	var bar_holder := Control.new()
	bar_holder.custom_minimum_size = Vector2(_susp_max_w, 12)
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.18, 0.15, 0.24)
	bar_bg.size = Vector2(_susp_max_w, 12)
	bar_holder.add_child(bar_bg)
	_susp_fill = ColorRect.new()
	_susp_fill.color = UI.GREEN
	_susp_fill.size = Vector2(0, 12)
	bar_holder.add_child(_susp_fill)
	sv.add_child(bar_holder)

	_susp_label = UI.label("0%", 13, UI.WHITE, true)
	_susp_label.custom_minimum_size.x = 34
	_susp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sv.add_child(_susp_label)
	_susp_panel.add_child(sv)
	root.add_child(_susp_panel)

	# ------------------------------------------------ bottom left: the bag --
	var bag := HBoxContainer.new()
	bag.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bag.offset_left = 8
	bag.offset_top = -46
	bag.offset_bottom = -8
	bag.add_theme_constant_override("separation", 4)
	var bag_icon := UI.icon("icon_bag", 18)
	bag.add_child(bag_icon)
	_slots = HBoxContainer.new()
	_slots.add_theme_constant_override("separation", 4)
	bag.add_child(_slots)
	root.add_child(bag)

	_item_name = UI.label("", 12, UI.CREAM)
	_item_name.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_item_name.offset_left = 10
	_item_name.offset_top = -66
	_item_name.offset_bottom = -46
	_item_name.offset_right = 320
	root.add_child(_item_name)

	# ------------------------------------------- bottom centre: the prompt --
	_prompt_box = UI.panel(Color(0.09, 0.075, 0.13, 0.9), UI.PURPLE)
	_prompt_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_box.offset_left = -150
	_prompt_box.offset_right = 150
	_prompt_box.offset_top = -44
	_prompt_box.offset_bottom = -12
	_prompt_box.visible = false
	_prompt = UI.label("", 14, UI.CREAM, true)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_box.add_child(_prompt)
	root.add_child(_prompt_box)

	# --------------------------------------- objective card shown on start --
	_objective_box = UI.panel(Color(0.09, 0.075, 0.13, 0.94), UI.CREAM)
	_objective_box.set_anchors_preset(Control.PRESET_CENTER)
	_objective_box.offset_left = -190
	_objective_box.offset_right = 190
	_objective_box.offset_top = -50
	_objective_box.offset_bottom = 50
	var ov := VBoxContainer.new()
	ov.add_theme_constant_override("separation", 6)
	_objective = UI.label("", 15, UI.WHITE, true)
	_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective.custom_minimum_size.x = 350
	ov.add_child(_objective)
	_objective_box.add_child(ov)
	root.add_child(_objective_box)
	_objective_box.modulate.a = 0.0

	# -------------------------------------------- red flash when spotted ----
	_flash = ColorRect.new()
	_flash.color = Color(1.0, 0.25, 0.25, 0.0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_flash)

# ---------------------------------------------------------------------------
func set_level_info(num: int, name: String) -> void:
	_name_label.text = "ด่าน %d — %s" % [num, name]

func show_objective(goal_text: String, hint: String) -> void:
	_objective.text = "%s\n\n[ %s ]" % [goal_text, hint]
	var tw := create_tween()
	tw.tween_property(_objective_box, "modulate:a", 1.0, 0.3)
	tw.tween_interval(3.6)
	tw.tween_property(_objective_box, "modulate:a", 0.0, 0.6)

func update_timer(t: float) -> void:
	var total := int(ceilf(maxf(t, 0.0)))
	_time_label.text = "%02d:%02d" % [total / 60, total % 60]
	if t <= 10.0:
		_time_label.add_theme_color_override("font_color",
			UI.RED if fmod(t, 0.5) < 0.25 else UI.YELLOW)
	elif t <= 20.0:
		_time_label.add_theme_color_override("font_color", UI.YELLOW)
	else:
		_time_label.add_theme_color_override("font_color", UI.CREAM)

func update_suspicion(v: float) -> void:
	var k := clampf(v / 100.0, 0.0, 1.0)
	_susp_fill.size.x = _susp_max_w * k
	_susp_label.text = "%d%%" % int(round(v))
	if k < 0.4:
		_susp_fill.color = UI.GREEN
	elif k < 0.75:
		_susp_fill.color = UI.YELLOW
	else:
		_susp_fill.color = UI.RED
	if k > 0.75:
		_susp_panel.modulate = Color(1, 1, 1, 0.75 + sin(float(Time.get_ticks_msec()) / 90.0) * 0.25)
	else:
		_susp_panel.modulate = Color.WHITE

func update_inventory(items: Array[String], selected: int) -> void:
	for c in _slots.get_children():
		c.queue_free()
	for i in items.size():
		var slot := PanelContainer.new()
		var is_sel := i == selected
		slot.add_theme_stylebox_override("panel", UI.panel_style(
			Color(0.16, 0.14, 0.23, 0.95) if is_sel else Color(0.09, 0.08, 0.13, 0.8),
			UI.CREAM if is_sel else Color(0.35, 0.32, 0.44), 2))
		var ic := UI.icon(Game.ITEMS[items[i]]["icon"], 18)
		slot.add_child(ic)
		_slots.add_child(slot)
	if items.is_empty():
		_item_name.text = "กระเป๋าว่าง — ไปเก็บไอเทมก่อน"
	else:
		var id := items[clampi(selected, 0, items.size() - 1)]
		_item_name.text = "%s — %s   [Q ใช้ / F สลับ]" % [
			Game.ITEMS[id]["name"], Game.ITEMS[id]["desc"]]

func set_prompt(text: String) -> void:
	_prompt_box.visible = text != ""
	_prompt.text = text

func flash() -> void:
	_flash.color.a = 0.34
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.0, 0.45)
