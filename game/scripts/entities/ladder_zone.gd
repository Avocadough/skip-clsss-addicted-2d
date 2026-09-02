class_name LadderZone
extends Area2D
## The climbable column in front of a ladder or a fence. Purely a trigger —
## the rungs themselves are painted into the background tile layer.

@onready var _shape: CollisionShape2D = $Shape

func _ready() -> void:
	add_to_group("ladder")
	body_entered.connect(func(b): if b is Player: (b as Player).ladders_touching += 1)
	body_exited.connect(func(b):
		if b is Player:
			var p := b as Player
			p.ladders_touching = maxi(0, p.ladders_touching - 1))

## The column expressed in tiles, so the level tools can read a hand-moved
## ladder back out of the scene.
func tile_rect() -> Rect2i:
	var r := get_node_or_null("Shape") as CollisionShape2D
	if r == null or r.shape == null:
		return Rect2i()
	var box := (r.shape as RectangleShape2D).size
	var top := position.y - box.y / 2.0
	return Rect2i(int(floor(position.x / 16.0)), int(round(top / 16.0)),
		1, int(round(box.y / 16.0)))
