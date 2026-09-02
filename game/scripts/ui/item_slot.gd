class_name ItemSlot
extends PanelContainer
## One square in the school-bag row. The selected one gets a brighter panel
## and a cream border so it reads at a glance which item Q will use.

@onready var _icon: TextureRect = $Icon

func setup(icon_name: String, selected: bool) -> void:
	if _icon == null:
		_icon = get_node_or_null("Icon")
	_icon.texture = load("res://assets/sprites/%s.png" % icon_name)
	add_theme_stylebox_override("panel", UI.panel_style(
		Color(0.16, 0.14, 0.23, 0.95) if selected else Color(0.09, 0.08, 0.13, 0.8),
		UI.CREAM if selected else Color(0.35, 0.32, 0.44), 2))
