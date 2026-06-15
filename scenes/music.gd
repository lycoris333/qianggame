extends AudioStreamPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	while get_tree().current_scene.name == "GAME": 
		play()
		break
 	
	print("其他节点不可以播放音乐")
