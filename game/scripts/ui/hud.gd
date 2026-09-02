class_name Hud
extends CanvasLayer
## In-level heads-up display: the countdown to the bell, the suspicion meter,
## the school-bag inventory and the contextual action prompt.
##
## The layout lives in scenes/ui/hud.tscn — `build()` below is what generated
## it and what tools/bake.gd calls to generate it again. Everything the script
## touches at run time is fetched by unique name, so the pieces can be dragged
## around in the editor without breaking anything.

const SLOT_SCENE := "res://scenes/ui/item_slot.tscn"

@onready var _time_label: Label = %TimeLabel
@onready var _name_label: Label = %NameLabel
@onready var _susp_fill: ColorRect = %BarFill
@onready var _susp_label: Label = %SuspicionLabel
@onready var _susp_panel: PanelContainer = %SuspicionPanel
@onready var _slots: HBoxContainer = %Slots
@onready var _prompt: Label = %PromptLabel
@onready var _prompt_box: PanelContainer = %PromptBox
@onready var _objective: Label = %ObjectiveLabel
@onready var _objective_box: PanelContainer = %ObjectiveBox
@onready var _item_name: Label = %ItemName
@onready var _flash: ColorRect = %Flash

var _susp_max_w := 96.0
var _slot_scene: PackedScene

func _ready() -> void:
	_slot_scene = load(SLOT_SCENE)

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
		var slot := _slot_scene.instantiate()
		slot.setup(Game.ITEMS[items[i]]["icon"], i == selected)
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

# ===========================================================================
#  Layout — the source tools/bake.gd writes scenes/ui/hud.tscn from.
#  Not called while the game is running; the scene is loaded instead.
# ===========================================================================
static func build() -> Hud:
	var hud := Hud.new()
	hud.name = "Hud"
	hud.layer = 10

	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(root)

	# ---------------------------------------------------------- top: clock --
	var top_left := UI.panel(Color(0.09, 0.075, 0.13, 0.85))
	top_left.name = "ClockPanel"
	top_left.position = Vector2(8, 6)
	top_left.add_theme_stylebox_override("panel", UI.panel_style(Color(0.09, 0.075, 0.13, 0.85), UI.CREAM))
	var hb := HBoxContainer.new()
	hb.name = "Row"
	hb.add_theme_constant_override("separation", 6)
	hb.add_child(UI.key(UI.icon("prop_clock", 16), "ClockIcon"))
	hb.add_child(UI.key(UI.label("01:00", 18, UI.CREAM, true), "TimeLabel"))
	# The stage name rides along in the same bar, which keeps it clear of the
	# suspicion meter on the right at the 480px design width of the game.
	var divider := UI.label("|", 15, Color(0.45, 0.41, 0.55))
	divider.name = "Divider"
	hb.add_child(divider)
	hb.add_child(UI.key(UI.label("", 13, UI.WHITE, true), "NameLabel"))
	top_left.add_child(hb)
	root.add_child(top_left)

	# --------------------------------------------- top right: suspicion bar --
	var susp_panel := UI.panel(Color(0.09, 0.075, 0.13, 0.85))
	UI.key(susp_panel, "SuspicionPanel")
	susp_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	susp_panel.offset_left = -178
	susp_panel.offset_right = -8
	susp_panel.offset_top = 6
	var sv := HBoxContainer.new()
	sv.name = "Row"
	sv.add_theme_constant_override("separation", 6)
	var eye := UI.icon("icon_eye", 16)
	eye.name = "EyeIcon"
	sv.add_child(eye)

	var bar_holder := Control.new()
	bar_holder.name = "BarHolder"
	bar_holder.custom_minimum_size = Vector2(96.0, 12)
	var bar_bg := ColorRect.new()
	bar_bg.name = "BarBg"
	bar_bg.color = Color(0.18, 0.15, 0.24)
	bar_bg.size = Vector2(96.0, 12)
	bar_holder.add_child(bar_bg)
	var bar_fill := ColorRect.new()
	UI.key(bar_fill, "BarFill")
	bar_fill.color = UI.GREEN
	bar_fill.size = Vector2(0, 12)
	bar_holder.add_child(bar_fill)
	sv.add_child(bar_holder)

	var susp_label := UI.label("0%", 13, UI.WHITE, true)
	UI.key(susp_label, "SuspicionLabel")
	susp_label.custom_minimum_size.x = 34
	susp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sv.add_child(susp_label)
	susp_panel.add_child(sv)
	root.add_child(susp_panel)

	# ------------------------------------------------ bottom left: the bag --
	var bag := HBoxContainer.new()
	bag.name = "Bag"
	bag.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bag.offset_left = 8
	bag.offset_top = -46
	bag.offset_bottom = -8
	bag.add_theme_constant_override("separation", 4)
	var bag_icon := UI.icon("icon_bag", 18)
	bag_icon.name = "BagIcon"
	bag.add_child(bag_icon)
	var slots := HBoxContainer.new()
	UI.key(slots, "Slots")
	slots.add_theme_constant_override("separation", 4)
	bag.add_child(slots)
	root.add_child(bag)

	var item_name := UI.label("", 12, UI.CREAM)
	UI.key(item_name, "ItemName")
	item_name.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	item_name.offset_left = 10
	item_name.offset_top = -66
	item_name.offset_bottom = -46
	item_name.offset_right = 320
	root.add_child(item_name)

	# ------------------------------------------- bottom centre: the prompt --
	var prompt_box := UI.panel(Color(0.09, 0.075, 0.13, 0.9), UI.PURPLE)
	UI.key(prompt_box, "PromptBox")
	prompt_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_box.offset_left = -150
	prompt_box.offset_right = 150
	prompt_box.offset_top = -44
	prompt_box.offset_bottom = -12
	prompt_box.visible = false
	var prompt := UI.label("", 14, UI.CREAM, true)
	UI.key(prompt, "PromptLabel")
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_box.add_child(prompt)
	root.add_child(prompt_box)

	# --------------------------------------- objective card shown on start --
	var objective_box := UI.panel(Color(0.09, 0.075, 0.13, 0.94), UI.CREAM)
	UI.key(objective_box, "ObjectiveBox")
	objective_box.set_anchors_preset(Control.PRESET_CENTER)
	objective_box.offset_left = -190
	objective_box.offset_right = 190
	objective_box.offset_top = -50
	objective_box.offset_bottom = 50
	objective_box.modulate.a = 0.0
	var ov := VBoxContainer.new()
	ov.name = "Column"
	ov.add_theme_constant_override("separation", 6)
	var objective := UI.label("", 15, UI.WHITE, true)
	UI.key(objective, "ObjectiveLabel")
	objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.custom_minimum_size.x = 350
	ov.add_child(objective)
	objective_box.add_child(ov)
	root.add_child(objective_box)

	# -------------------------------------------- red flash when spotted ----
	var flash := ColorRect.new()
	UI.key(flash, "Flash")
	flash.color = Color(1.0, 0.25, 0.25, 0.0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(flash)
	return hud

## One inventory square. Its own scene so the bag can be restyled without
## touching the HUD script.
static func build_slot() -> PanelContainer:
	var slot := PanelContainer.new()
	slot.name = "ItemSlot"
	slot.set_script(load("res://scripts/ui/item_slot.gd"))
	var ic := UI.icon("item_coin", 18)
	ic.name = "Icon"
	slot.add_child(ic)
	return slot
