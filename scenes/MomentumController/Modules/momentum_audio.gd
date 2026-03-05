extends Node2D

@onready var momentum_controller: MomentumController = $".."

@onready var jump_sound: AudioStreamPlayer2D = $JumpSound
@onready var roll_sound: AudioStreamPlayer2D = $RollSound

func _ready() -> void:
	momentum_controller.state_changed.connect(_controller_state_changed)
	momentum_controller.jumped.connect(_momentum_jumped)
	
func _momentum_jumped() -> void:
	jump_sound.play()
	
func _controller_state_changed(old_state: MomentumController.State, new_state: MomentumController.State) -> void:
	if new_state == MomentumController.State.SPIN and old_state != MomentumController.State.JUMP:
		roll_sound.play()
	
