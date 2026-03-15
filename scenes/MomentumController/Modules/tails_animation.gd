extends AnimatedSprite2D
class_name TailsAnimation

@onready var momentum_controller: MomentumController = $".."
@onready var skid_sound: AudioStreamPlayer2D = $SkidSound
@onready var spindash: Node2D = $"../Spindash"
@onready var flight: Flight = $"../Flight"

var force_animation : bool = false
var skid_dust_ready : bool = true
var ground_speed : float

var down_is_held : bool = false
var direction : float = 0

var spindash_present : bool = false
var flight_present : bool = false

@onready var skid_dust_scene: Node2D = $SkidDustScene
@onready var skid_dust_timer: Timer = $SkidDustTimer

const SKID_DUST = preload("res://scenes/effects/skid_dust_animated_sprite_2d.tscn")


func _ready() -> void:
	skid_dust_timer.timeout.connect(skid_dust_timer_timeout)
	PlayerInput.down_pressed.connect(_down_pressed)
	PlayerInput.down_released.connect(_down_released)
	PlayerInput.changed_direction.connect(_changed_direction)
	
	if spindash != null:
		spindash_present = true
		
	if flight != null:
		flight_present = true

func _process(delta: float) -> void:
	
	ground_speed = momentum_controller.ground_speed
	match momentum_controller.current_state:
		MomentumController.State.GROUND:
			_set_ground_animation(direction,down_is_held)
			
		MomentumController.State.SPIN:
			_set_spin_animation(direction)
			
		MomentumController.State.COYOTE:
			_set_ground_animation(direction,down_is_held)
						
		MomentumController.State.COYOTE_SPIN:
			_set_spin_animation(direction)
		
		MomentumController.State.JUMP:
			_set_jump_animation(direction)
			
		MomentumController.State.AIR:
			_set_air_animation(direction,down_is_held)
		
		MomentumController.State.SPECIAL:
			_set_special_animation(direction)
		
	pass

func _set_ground_animation(direction:float, down_is_held:bool) -> void:
	
	if force_animation and is_playing():
		return
	force_animation = false
	
	if abs(direction):
		if ground_speed!=0:
			momentum_controller.flipped_image = ground_speed<0
			flip_h = momentum_controller.flipped_image
		speed_scale=1+abs(ground_speed/momentum_controller.max_ground_speed)*6
	else:
		momentum_controller.flipped_image = momentum_controller.last_direction_sign == -1
		flip_h = momentum_controller.flipped_image
	var input_active : bool = abs(direction) > 0
	var changing_direction : bool = sign(direction) != sign(ground_speed)
	var moving_slow : bool = abs(ground_speed) < abs(momentum_controller.max_ground_speed) / 3 and abs(ground_speed)>20
	var facing_wrong_way : bool = momentum_controller.flipped_image != (sign(direction) == -1)
	
	if input_active and changing_direction and moving_slow and facing_wrong_way:
		play("Turn")
		force_animation = true
	
	elif abs(ground_speed)>abs(momentum_controller.max_ground_speed)/3 and sign(direction)!=sign(ground_speed) and direction!= 0:
		play("Skid")
		if skid_dust_ready:
			skid_sound.play()
			skid_dust_ready = false
			skid_dust_timer.start(0.02)
			var skid_dust := SKID_DUST.instantiate()
			skid_dust.global_position = skid_dust_scene.global_position
			momentum_controller.get_parent().add_child(skid_dust)
	elif abs(ground_speed)>abs(momentum_controller.max_ground_speed)/3:
		play("Run_Fast")
	elif abs(ground_speed) > 10:
		play("Run")
	elif down_is_held:
		if animation != "Curl":
			play("Curl")
	else:
		play("Idle")
		
func _set_air_animation(direction:float, down_is_held:bool) -> void:
	
	if force_animation and is_playing():
		return
	force_animation = false
	
	if abs(direction)>0:
		if momentum_controller.x_speed!=0:
			momentum_controller.flipped_image = momentum_controller.x_speed<0
			flip_h = momentum_controller.flipped_image
		speed_scale=1+abs(momentum_controller.x_speed/momentum_controller.max_ground_speed)*6
	else:
		momentum_controller.flipped_image = momentum_controller.last_direction_sign == -1
		flip_h = momentum_controller.flipped_image

	if abs(momentum_controller.x_speed)>abs(momentum_controller.max_ground_speed)/3:
		play("Run_Fast")
	else:
		play("Run")
		
func _set_spin_animation(direction:float) -> void:
	if force_animation and is_playing():
		return
	force_animation = false
	if ground_speed!=0:
		momentum_controller.flipped_image = ground_speed<0
		flip_h = momentum_controller.flipped_image
	speed_scale=1+abs(ground_speed/momentum_controller.max_ground_speed)*6
	play("Spin")
	
func _set_spindash_animation(direction:float) -> void:
	if force_animation and is_playing():
		return
	force_animation = false
	if ground_speed!=0:
		momentum_controller.flipped_image = ground_speed<0
		flip_h = momentum_controller.flipped_image
	speed_scale=1
	play("Spindash")
		
func _set_jump_animation(direction:float) -> void:
	if force_animation and is_playing():
		return
	force_animation = false
	
	if abs(direction)>0 and direction:
		momentum_controller.flipped_image = direction<0
		flip_h = momentum_controller.flipped_image
	speed_scale=1
	play("Jump")
	
func _set_special_animation(direction:float) -> void:
	if spindash_present:
		var spindash_state = momentum_controller.special_state == spindash.special_name
		if spindash_state:
			play("Spindash")
			
	if flight_present:
		var flight_state = momentum_controller.special_state == flight.special_name
		if flight_state:
			flip_h = sign(direction) == -1 if sign(direction)!=0 else flip_h
			play("Fly")
		
func _down_pressed() -> void:
	down_is_held = true

func _down_is_held() -> void:
	down_is_held = true

func _down_released() -> void:
	down_is_held = false
	
func _changed_direction(new_direction: float) -> void:
	direction = new_direction
	
func skid_dust_timer_timeout() -> void:
	skid_dust_ready = true
