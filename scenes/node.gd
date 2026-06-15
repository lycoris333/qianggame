extends Node

# Called when the node enters the scene tree for the first time.
func _ready() :
	$Label.text="wo bu shi ren lei"
	$Label.modulate=Color.GREEN
func _input(event):
	if event.is_action_pressed("jump"):
		$Label.modulate=Color.GREEN
	if event.is_action_released("jump"):
		$Label.modulate=Color.RED
