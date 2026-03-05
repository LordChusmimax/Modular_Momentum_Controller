extends AnimatedSprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_finished.connect(_disipate)
	pass # Replace with function body.


func _disipate() -> void :
	queue_free()
