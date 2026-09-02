class_name ClassroomZone
extends Area2D
## The room you are supposed to be skipping. Walking back in loses the stage
## outright, so it is fenced off with a trigger rather than left to trust.

signal player_entered

## The size of the room in tiles. Resizes the trigger when changed, so the
## no-go area can be redrawn from the Inspector.
@export var tiles := Vector2i(4, 4):
	set(v):
		tiles = Vector2i(maxi(v.x, 1), maxi(v.y, 1))
		_apply_size()

func _ready() -> void:
	add_to_group("classroom")
	_apply_size()
	body_entered.connect(func(b): if b is Player: player_entered.emit())

func _apply_size() -> void:
	var cs := get_node_or_null("Shape") as CollisionShape2D
	if cs == null:
		return
	var r := RectangleShape2D.new()
	r.size = Vector2(tiles.x * 16, tiles.y * 16)
	cs.shape = r
