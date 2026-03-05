extends Node2D
class_name Dropdash

@onready var momentum_controller: MomentumController = $".."
@onready var dropdash_timer: Timer = $DropdashTimer
@onready var dropdash_audio: DropdashAudio = $DropdashAudio
@onready var dropdash_dust_scene: DropdashDustScene = $DropdashDustScene

var dropdash_charged: bool = false
var _jumping: bool = false

@export var dropdash_speed:float = 700.0
@export var press_time:float = 0.3
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	momentum_controller.state_changed.connect(_controller_state_changed)
	dropdash_timer.timeout.connect(_dropdash_timer_timeout)
	PlayerInput.jump_pressed.connect(_dropdash_pressed)
	PlayerInput.jump_released.connect(_jump_released)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _controller_state_changed(old_state: MomentumController.State, new_state: MomentumController.State) -> void:
	_jumping = (new_state == MomentumController.State.JUMP)
	if old_state== MomentumController.State.JUMP and new_state == MomentumController.State.GROUND:
		if dropdash_charged:
			_dropdash_landing()

func _dropdash_pressed()->void:
	if _jumping:
		dropdash_timer.start(press_time)
		
func _jump_released()->void:
	dropdash_timer.stop()
	
func _dropdash_landing() -> void:
	if dropdash_charged:
		dropdash_audio.land_dropdash()
		momentum_controller.force_state(momentum_controller.State.SPIN)
		momentum_controller.ground_speed = max(dropdash_speed, momentum_controller.ground_speed) * momentum_controller.last_direction_sign
		dropdash_charged = false
		dropdash_dust_scene.create_dropdash_dust()
		

func _dropdash_timer_timeout()->void:
	if not dropdash_charged and momentum_controller.current_state == MomentumController.State.JUMP:
		dropdash_charged = true
		dropdash_audio.charge_dropdash()
