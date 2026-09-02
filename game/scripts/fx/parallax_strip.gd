class_name ParallaxStrip
extends TextureRect
## A backdrop strip that slides against the camera. `scroll_factor` is how
## much of the camera motion it takes: 0 sits painted on the sky, 1 is locked
## to the world.

@export var scroll_factor := 0.30

var base_y := 0.0

func _ready() -> void:
	base_y = position.y
