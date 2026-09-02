class_name Ball
extends Area2D
## A PE ball rolling along the field. Getting clipped knocks น็อต flat, and
## going down in a heap is the loudest thing that happens in the game.

@export var x_min := 0.0
@export var x_max := 0.0
@export var speed := 60.0

var dir := 1

@onready var _spr: Sprite2D = $Sprite

func _ready() -> void:
	add_to_group("ball")
	body_entered.connect(_on_hit)

func _physics_process(delta: float) -> void:
	position.x += dir * speed * delta
	if position.x > x_max:
		position.x = x_max
		dir = -1
	elif position.x < x_min:
		position.x = x_min
		dir = 1
	_spr.rotation += dir * speed * delta * 0.06

func _on_hit(body: Node2D) -> void:
	if body is Player:
		(body as Player).stun(1.1)
		Fader.toast("โดนลูกบอล! เสียงดังไปทั่วสนาม", Color(1.0, 0.6, 0.5))
