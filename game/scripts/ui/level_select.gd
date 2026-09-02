extends Control
## Stage picker: one card per stage from section 8 of the design document,
## showing its best rank and best remaining time once cleared.
##
## Laid out in scenes/level_select.tscn; the cards are instances of
## scenes/ui/level_card.tscn, one per stage, filled in on load.

const CARD := "res://scenes/ui/level_card.tscn"

@onready var _cards: HBoxContainer = %Cards
@onready var _back: Button = %BackButton
@onready var _reset: Button = %ResetButton
@onready var _all_clear: Label = %AllClearLabel

func _ready() -> void:
	var card_scene: PackedScene = load(CARD)
	var first_playable: Button = null
	for i in range(1, LevelData.count() + 1):
		var card: LevelCard = card_scene.instantiate()
		_cards.add_child(card)
		card.setup(i)
		if first_playable == null and i <= Game.unlocked:
			first_playable = card.play_button()

	_back.pressed.connect(func(): Fader.goto("res://scenes/main_menu.tscn"))

	_reset.visible = Game.unlocked > 1 or not Game.best_rank.is_empty()
	_reset.pressed.connect(func():
		Game.wipe_save()
		Fader.goto("res://scenes/level_select.tscn"))

	_all_clear.visible = Game.all_cleared()

	if first_playable != null:
		first_playable.call_deferred("grab_focus")
	Sfx.play_music()

# ===========================================================================
static func build() -> Control:
	var sel := Control.new()
	sel.name = "LevelSelect"
	sel.set_script(load("res://scripts/ui/level_select.gd"))
	sel.set_anchors_preset(Control.PRESET_FULL_RECT)
	sel.add_child(load("res://scenes/ui/backdrop.tscn").instantiate())

	var root := VBoxContainer.new()
	root.name = "Column"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_top = 8
	root.offset_bottom = -8
	root.offset_left = 16
	root.offset_right = -16
	root.add_theme_constant_override("separation", 4)
	sel.add_child(root)

	var title := UI.label("เลือกด่าน", 22, UI.CREAM, true)
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	# Cards are added on load, one per stage, so the row starts out empty.
	var row := HBoxContainer.new()
	UI.key(row, "Cards")
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(row)

	var bottom := HBoxContainer.new()
	bottom.name = "Bottom"
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 8)
	root.add_child(bottom)

	var back := UI.button("« กลับหน้าแรก", 14)
	UI.key(back, "BackButton")
	back.custom_minimum_size.x = 170
	bottom.add_child(back)

	var reset := UI.button("ล้างความคืบหน้า", 14)
	UI.key(reset, "ResetButton")
	reset.custom_minimum_size.x = 170
	bottom.add_child(reset)

	var done := UI.label("• เคลียร์ครบทุกด่านแล้ว — โดดเรียนระดับตำนาน •", 13, UI.YELLOW, true)
	UI.key(done, "AllClearLabel")
	done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	done.visible = false
	root.add_child(done)
	return sel
