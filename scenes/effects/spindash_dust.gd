extends AnimatedSprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	autoplay = "Charge"
	animation_finished.connect(disipate)
	pass # Replace with function body.

func spindash_released() -> void:
	play("Release")

func disipate() -> void:
	if animation == "Release":
		queue_free()
