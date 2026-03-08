extends Node2D
class_name Flight

@onready var momentum_controller: MomentumController = $".."

var _on_jump:bool = false
const  special_name : String = "Flight"


func _ready() -> void:
	momentum_controller.state_changed.connect(_controller_state_changed)
	PlayerInput.jump_pressed.connect(_spindash_pressed)
	pass

func _physics_process(delta: float) -> void:
	var flying = momentum_controller.special_state == special_name
	if flying:
		print("Flying")

func _controller_state_changed(old_state: MomentumController.State, new_state: MomentumController.State) -> void:
	_on_jump = (new_state == MomentumController.State.JUMP)
	
func _spindash_pressed() -> void:
	var jump_state = momentum_controller.special_state == special_name
	var not_on_special = momentum_controller.current_state != momentum_controller.State.SPECIAL
	
	if _on_jump and not_on_special:
		momentum_controller.force_state(momentum_controller.State.SPECIAL, special_name)
		_start_flight()
	elif jump_state:
		pass

func _start_flight():
	print("Fly")
