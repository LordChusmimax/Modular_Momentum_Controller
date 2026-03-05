extends StaticBody2D

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var basic_platform: StaticBody2D = $"."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	collision_shape_2d.disabled = not is_visible_in_tree()
	basic_platform.visibility_changed.connect(_visibility_changed)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _visibility_changed():
	collision_shape_2d.set_deferred("disabled",not basic_platform.is_visible_in_tree() )
