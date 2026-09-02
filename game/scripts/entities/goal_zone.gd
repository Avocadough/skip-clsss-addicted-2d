class_name GoalZone
extends Area2D
## The skip point — what the whole stage is aimed at. Levels 1-4 finish the
## moment it is entered; level 5 wants you standing in it when the bell goes.

signal player_entered
signal player_exited

var inside := false

@onready var _spr: Sprite2D = $Sprite

var _t := 0.0

func _ready() -> void:
	add_to_group("goal")
	body_entered.connect(func(b): if b is Player: inside = true; player_entered.emit())
	body_exited.connect(func(b): if b is Player: inside = false; player_exited.emit())

func _process(delta: float) -> void:
	_t += delta
	var pulse := 0.85 + sin(_t * 3.2) * 0.15
	_spr.scale = Vector2.ONE * pulse
	_spr.modulate.a = 0.55 + sin(_t * 3.2) * 0.25
