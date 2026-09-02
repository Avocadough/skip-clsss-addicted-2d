class_name ClassroomZone
extends Area2D
## The room you are supposed to be skipping. Walking back in loses the stage
## outright, so it is fenced off with a trigger rather than left to trust.

signal player_entered

func _ready() -> void:
	add_to_group("classroom")
	body_entered.connect(func(b): if b is Player: player_entered.emit())
