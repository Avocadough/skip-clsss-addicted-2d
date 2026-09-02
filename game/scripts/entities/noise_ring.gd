class_name NoiseRing
extends Node2D
## The expanding circle drawn wherever a sound is made. Spawned on the fly by
## the level and gone again in half a second, so it has no scene of its own.

var radius := 40.0

var _t := 0.0

func _process(delta: float) -> void:
	_t += delta
	if _t > 0.45:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var k := _t / 0.45
	draw_arc(Vector2.ZERO, radius * k, 0.0, TAU, 28,
		Color(1.0, 0.95, 0.7, 0.5 * (1.0 - k)), 1.5)
