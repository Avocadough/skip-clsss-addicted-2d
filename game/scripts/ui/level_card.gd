class_name LevelCard
extends PanelContainer
## One stage on the picker: its number, name, best rank and best time. The
## badge row holds all three possible states — a rank, a padlock key, a dash —
## and `setup()` shows whichever one applies.

const DIM := Color(0.45, 0.42, 0.52)

@onready var _num: Label = %NumLabel
@onready var _name: Label = %NameLabel
@onready var _en: Label = %EnLabel
@onready var _time: Label = %TimeLabel
@onready var _rank: Label = %RankLabel
@onready var _key: TextureRect = %KeyIcon
@onready var _dash: Label = %DashLabel
@onready var _best: Label = %BestLabel
@onready var _play: Button = %PlayButton

func play_button() -> Button:
	return _play

func setup(index: int) -> void:
	var d := LevelData.get_level(index)
	var locked := index > Game.unlocked
	var rank: String = Game.best_rank.get(index, "")

	add_theme_stylebox_override("panel", UI.panel_style(
		Color(0.10, 0.085, 0.15, 0.95) if not locked else Color(0.08, 0.07, 0.11, 0.9),
		UI.CREAM if not locked else Color(0.30, 0.28, 0.36), 2, 6, 5))

	_num.text = "ด่าน %d" % index
	_num.add_theme_color_override("font_color", UI.PURPLE if not locked else DIM)

	_name.text = d["name"] if not locked else "ยังไม่ปลดล็อก"
	_name.add_theme_color_override("font_color", UI.WHITE if not locked else DIM)

	_en.visible = not locked
	_time.visible = not locked
	if not locked:
		_en.text = d["en"]
		_time.text = "เวลา %d วิ" % int(d["time"])

	# Badge row: the earned rank, a greyed-out key for a stage still locked,
	# or a dash for one that is open but not cleared yet.
	_rank.visible = rank != ""
	_key.visible = rank == "" and locked
	_dash.visible = rank == "" and not locked
	if rank != "":
		_rank.text = rank
		_rank.add_theme_color_override("font_color", UI.rank_color(rank))

	_best.text = "เหลือ %.1f วิ" % float(Game.best_time.get(index, 0.0)) if rank != "" else " "

	_play.text = "เล่น" if not locked else "ล็อก"
	_play.disabled = locked
	if not locked:
		_play.pressed.connect(func():
			Game.current_level = index
			Fader.goto(LevelData.scene_path(index)))

# ===========================================================================
static func build() -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "LevelCard"
	card.set_script(load("res://scripts/ui/level_card.gd"))
	card.add_theme_stylebox_override("panel", UI.panel_style(
		Color(0.10, 0.085, 0.15, 0.95), UI.CREAM, 2, 6, 5))
	card.custom_minimum_size = Vector2(84, 0)

	var v := VBoxContainer.new()
	v.name = "Column"
	v.add_theme_constant_override("separation", 1)
	card.add_child(v)

	var num := UI.label("ด่าน 1", 14, UI.PURPLE, true)
	UI.key(num, "NumLabel")
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(num)

	var name_l := UI.label("", 10, UI.WHITE)
	UI.key(name_l, "NameLabel")
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_l.custom_minimum_size = Vector2(70, 26)
	v.add_child(name_l)

	var en := UI.label("", 8, Color(0.66, 0.63, 0.75))
	UI.key(en, "EnLabel")
	en.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	en.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	en.custom_minimum_size.x = 70
	v.add_child(en)

	var time_l := UI.label("", 9, Color(0.78, 0.75, 0.85))
	UI.key(time_l, "TimeLabel")
	time_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(time_l)

	var badge := CenterContainer.new()
	badge.name = "Badge"
	badge.custom_minimum_size.y = 26
	var rank := UI.label("S", 22, UI.YELLOW, true)
	UI.key(rank, "RankLabel")
	rank.visible = false
	badge.add_child(rank)
	var key := UI.icon("item_key", 18)
	UI.key(key, "KeyIcon")
	key.modulate = Color(0.42, 0.39, 0.50)
	key.visible = false
	badge.add_child(key)
	var dash := UI.label("—", 18, Color(0.42, 0.39, 0.50), true)
	UI.key(dash, "DashLabel")
	badge.add_child(dash)
	v.add_child(badge)

	var best := UI.label(" ", 8, Color(0.72, 0.70, 0.80))
	UI.key(best, "BestLabel")
	best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(best)

	v.add_child(UI.key(UI.button("เล่น", 12), "PlayButton"))
	return card
