class_name Doorway
extends Area2D
## A shortcut door. While locked it carries a solid blocker so the player has
## to go and find the key; unlocking clears the blocker and swaps the art.

signal opened

const SPR_LOCKED := "res://assets/sprites/prop_door_locked.png"
const SPR_OPEN := "res://assets/sprites/prop_door.png"

@export var locked := true:
	set(v):
		locked = v
		_apply_locked()

@onready var _spr: Sprite2D = $Sprite
@onready var _blocker: StaticBody2D = $Blocker

func _ready() -> void:
	add_to_group("doorway")
	_apply_locked()

## Keeps the art, the hit box and the blocker in step with `locked`, whichever
## way it was changed — by the key at run time, or by hand in the Inspector.
func _apply_locked() -> void:
	if _spr == null:
		_spr = get_node_or_null("Sprite")
		_blocker = get_node_or_null("Blocker")
	if _spr == null:
		return
	var tex: Texture2D = load(SPR_LOCKED if locked else SPR_OPEN)
	_spr.texture = tex
	_spr.centered = false
	_spr.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height())
	_size_shape(get_node_or_null("Shape"), 28.0, tex.get_height())

	if is_instance_valid(_blocker):
		var bs := _blocker.get_node_or_null("Shape") as CollisionShape2D
		_size_shape(bs, 10.0, tex.get_height())
		if bs != null:
			# An open door is scenery — nothing left to walk into.
			if is_inside_tree():
				bs.set_deferred("disabled", not locked)
			else:
				bs.disabled = not locked

func _size_shape(node: Node, w: float, h: float) -> void:
	var cs := node as CollisionShape2D
	if cs == null:
		return
	var r := RectangleShape2D.new()
	r.size = Vector2(w, h)
	cs.shape = r
	cs.position = Vector2(0, -h / 2.0)

func unlock() -> void:
	if not locked:
		return
	locked = false
	Sfx.play("unlock")
	opened.emit()
