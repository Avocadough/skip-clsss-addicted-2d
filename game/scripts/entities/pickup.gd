class_name Pickup
extends Area2D
## An item lying in the world, waiting to be walked into.
##
## `id` selects which entry of Game.ITEMS this is; the sprite is re-derived
## from it on load, so changing the id in the Inspector changes the art too.

signal taken(id: String)

@export var id := "coin":
	set(v):
		id = v
		_apply_id()

@onready var _sprite: Sprite2D = $Sprite

var _t := 0.0
var _base_y := 0.0

func _ready() -> void:
	add_to_group("pickup")
	_apply_id()
	_base_y = position.y
	body_entered.connect(_on_body)

func _apply_id() -> void:
	if _sprite == null:
		_sprite = get_node_or_null("Sprite")
	if _sprite != null and Game.ITEMS.has(id):
		_sprite.texture = load("res://assets/sprites/%s.png" % Game.ITEMS[id]["icon"])

func _process(delta: float) -> void:
	_t += delta
	position.y = _base_y + sin(_t * 2.6) * 2.0

func _on_body(body: Node2D) -> void:
	if body is Player:
		(body as Player).add_item(id)
		taken.emit(id)
		Sfx.play("pickup")
		Fader.toast("ได้รับ: %s" % Game.ITEMS[id]["name"], Color(1.0, 0.86, 0.45))
		queue_free()
