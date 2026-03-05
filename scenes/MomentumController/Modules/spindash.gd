extends Node2D

@onready var momentum_controller: MomentumController = $".."
@onready var spindash_audio: Node2D = $SpindashAudio

var _on_ground:bool = false
var _down_is_hold : bool = false
var spindash_state : bool = false

@export var spindash_max_speed : float = 1500.0

var spindash_charge : float = 0
var spindash_max_charge : float = 1.0
var spindash_direction_sign : float = 1

var spindash_dust:AnimatedSprite2D
const SPINDASH_DUST = preload("res://scenes/effects/spindash_dust.tscn")
const SKID_DUST = preload("res://scenes/effects/skid_dust_animated_sprite_2d.tscn")
@onready var spindash_dust_scene: SpindashDustScene = $SpindashDustScene

func _ready() -> void:
	momentum_controller.state_changed.connect(_controller_state_changed)
	PlayerInput.jump_pressed.connect(_spindash_pressed)
	PlayerInput.down_pressed.connect(_down_pressed)
	PlayerInput.down_released.connect(_down_released)
	pass

func _physics_process(delta: float) -> void:
	_handle_spindash_state(delta)
	pass

func _controller_state_changed(old_state: MomentumController.State, new_state: MomentumController.State) -> void:
	_on_ground = (new_state == MomentumController.State.GROUND)
	
func _down_pressed() -> void:
	_down_is_hold = true
	
func _down_released() -> void:
	_down_is_hold = false
	if spindash_state:
		_spindash_release()
	
func _spindash_pressed() -> void:
	if _on_ground and _down_is_hold and not spindash_state:
		momentum_controller.force_state(momentum_controller.State.SPECIAL)
		spindash_state = true
		spindash_direction_sign = momentum_controller.last_direction_sign
		spindash_dust_scene.start_spindash_dust(spindash_direction_sign)
		_load_spindash()
	elif spindash_state and _down_is_hold:
		_load_spindash()
		
func _handle_spindash_state(delta:float)->void:
	var hit_normal: Vector2 = momentum_controller.last_normal
	var tangent: Vector2 = Vector2(-hit_normal.y, hit_normal.x)
	spindash_charge = move_toward(spindash_charge,0,delta/1.5)
	
func _spindash_release() -> void:
	spindash_state=false
	momentum_controller.force_state(momentum_controller.State.SPIN)
	momentum_controller.ground_speed = (spindash_max_speed/3 + spindash_max_speed * spindash_charge * 2/3) * spindash_direction_sign
	spindash_dust_scene.release_spindash_dust()
	spindash_audio.release_spindash()

func _load_spindash() -> void:
	spindash_charge = move_toward(spindash_charge, spindash_max_charge, 0.25)
	spindash_audio.load_spindash(spindash_charge)
