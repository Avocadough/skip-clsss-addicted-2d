class_name LadderZone
extends Area2D
## The climbable column in front of a ladder or a fence. Purely a trigger —
## the rungs themselves are painted into the background tile layer.

## How tall the column is, in tiles. Changing it resizes the trigger, so a
## ladder can be made longer straight from the Inspector.
@export var tiles_high := 3:
	set(v):
		tiles_high = maxi(v, 1)
		_apply_height()

@onready var _shape: CollisionShape2D = $Shape

func _ready() -> void:
	add_to_group("ladder")
	_apply_height()
	body_entered.connect(func(b): if b is Player: (b as Player).ladders_touching += 1)
	body_exited.connect(func(b):
		if b is Player:
			var p := b as Player
			p.ladders_touching = maxi(0, p.ladders_touching - 1))

func _apply_height() -> void:
	var cs := get_node_or_null("Shape") as CollisionShape2D
	if cs == null:
		return
	var r := RectangleShape2D.new()
	r.size = Vector2(14, tiles_high * 16)
	cs.shape = r

## The column expressed in tiles, so the level tools can read a hand-moved
## ladder back out of the scene.
func tile_rect() -> Rect2i:
	var top := position.y - tiles_high * 16 / 2.0
	return Rect2i(int(floor(position.x / 16.0)), int(round(top / 16.0)), 1, tiles_high)
