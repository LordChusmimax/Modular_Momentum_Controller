extends Camera2D

const LEAD_STRENGTH = 0.05
const LEAD_SPEED = 10.0
const MAX_LEAD = 200.0 

@export var character_path: NodePath
var character: CharacterBody2D
var _lead_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	character = get_node(character_path)

func _process(delta: float) -> void:
	# Lead camera basado en velocidad
	var target_offset = Vector2(character.x_speed, character.y_speed) * LEAD_STRENGTH
	
	target_offset = target_offset.limit_length(MAX_LEAD)
	
	offset = offset.lerp(target_offset, LEAD_SPEED * delta)
	global_position = character.global_position + Vector2(0, 1)
