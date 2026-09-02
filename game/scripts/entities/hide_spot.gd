class_name HideSpot
extends Area2D
## Somewhere to duck out of sight. The art, the hit box and the prompt text
## all follow from `kind`, so a spot can be re-themed from the Inspector.

const ART := {
	"locker":  "prop_locker",
	"desk":    "prop_desk",
	"bush":    "prop_bush",
	"table":   "prop_table",
	"shelf":   "prop_bookshelf",
	"vending": "prop_vending",
	"crate":   "prop_crate",
}

@export_enum("locker", "desk", "bush", "table", "shelf", "vending", "crate")
var kind := "locker":
	set(v):
		kind = v
		_apply_kind()

var occupied := false

@onready var _spr: Sprite2D = $Sprite
@onready var _shape: CollisionShape2D = $Shape

func _ready() -> void:
	add_to_group("hide_spot")
	_apply_kind()

## Re-derives everything the kind decides. Runs on load as well as on an edit,
## so a baked spot and a hand-changed one always agree.
func _apply_kind() -> void:
	if _spr == null:
		_spr = get_node_or_null("Sprite")
		_shape = get_node_or_null("Shape")
	if _spr == null or _shape == null:
		return
	var tex: Texture2D = load("res://assets/sprites/%s.png" % ART.get(kind, "prop_locker"))
	_spr.texture = tex
	_spr.centered = false
	_spr.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height())
	# Lockers and bushes stand in front of the player; a desk or a canteen
	# table has to be drawn over him so crouching under it reads properly.
	_spr.z_index = 1 if kind in ["desk", "table"] else -1

	var r := RectangleShape2D.new()
	r.size = Vector2(maxf(tex.get_width(), 14), tex.get_height())
	_shape.shape = r
	_shape.position = Vector2(0, -tex.get_height() / 2.0)

func set_occupied(v: bool) -> void:
	occupied = v
	_spr.modulate = Color(0.82, 0.86, 1.0) if v else Color.WHITE

func label() -> String:
	match kind:
		"locker":  return "ซ่อนในตู้ล็อกเกอร์"
		"desk":    return "มุดใต้โต๊ะ"
		"bush":    return "ซ่อนในพุ่มไม้"
		"shelf":   return "หลบหลังชั้นหนังสือ"
		"vending": return "หลบหลังตู้กดน้ำ"
		"crate":   return "หลบหลังลัง"
		_:         return "ซ่อนใต้โต๊ะอาหาร"
