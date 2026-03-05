extends Node

signal jump_pressed
signal jump_released
signal down_pressed
signal down_released
signal changed_direction(direction:float)

var direction: float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var new_direction := Input.get_axis("character_left", "character_right")
	if new_direction != direction:
		direction = new_direction
		changed_direction.emit(new_direction)
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("character_jump"):
		jump_pressed.emit()
	if event.is_action_released("character_jump"):
		jump_released.emit()
	if event.is_action_pressed("character_down"):
		down_pressed.emit()
	if event.is_action_released("character_down"):
		down_released.emit()
