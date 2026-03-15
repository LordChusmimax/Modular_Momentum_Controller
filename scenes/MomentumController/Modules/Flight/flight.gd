extends Node2D
class_name Flight

signal set_flight(flying:bool)

const  special_name : String = "Flight"

@export var flight_propulsion:float = 100
@export var flight_gravity:float = 100
@export var max_flight_speed:float = 200
@export var flight_speed:float = 200
@export var max_fall_speed:float = 400

@onready var momentum_controller: MomentumController = $".."
@onready var tired_timer: Timer = $TiredTimer

var _on_jump:bool = false
var flying:bool = false
var ceil_hit: bool = false
var direction: float
var tired: bool = false

func _ready() -> void:
	momentum_controller.state_changed.connect(_controller_state_changed)
	momentum_controller.ground_signal.connect(_land)
	momentum_controller.ceil_signal.connect(_ceiling_collision)
	tired_timer.timeout.connect(_tired_timer_timeout)
	PlayerInput.jump_pressed.connect(_spindash_pressed)
	PlayerInput.changed_direction.connect(_changed_direction)
	pass

func _physics_process(delta: float) -> void:
	if flying:
		momentum_controller.side_collision_air()
		_move(delta)
		_fly(delta)
		
func _controller_state_changed(old_state: MomentumController.State, new_state: MomentumController.State) -> void:
	_on_jump = (new_state == MomentumController.State.JUMP)
	
func _spindash_pressed() -> void:
	var jump_state = momentum_controller.special_state == special_name
	var not_on_special = momentum_controller.current_state != momentum_controller.State.SPECIAL
	
	if _on_jump and not_on_special:
		momentum_controller.force_state(momentum_controller.State.SPECIAL, special_name)
		_start_flight()
		set_flight.emit(true)
	elif flying:
		_propell()

func _start_flight() -> void:
	momentum_controller.change_air_velocity(momentum_controller.x_speed,-flight_propulsion)
	flying = true
	tired_timer.start(8)
	
func _propell() -> void:
	if ceil_hit or tired:
		return
	momentum_controller.change_air_velocity(momentum_controller.x_speed,-flight_propulsion)
	
func _fly(delta:float) -> void:
	momentum_controller.add_air_velocity(0,flight_gravity*delta)
	momentum_controller.cap_air_velocity(0,max_fall_speed)
	momentum_controller.move_air(delta)
	
func _move(delta:float) -> void:
	momentum_controller.add_air_velocity(direction*flight_speed*delta,0)
	momentum_controller.cap_air_velocity(max_flight_speed,0)
func _land(landed: bool) -> void:
	if not flying or not landed:
		return
		
	set_flight.emit(false)
	tired_timer.stop()
	momentum_controller.force_state(momentum_controller.State.GROUND)
	momentum_controller.directional_to_ground_speed()
	flying = false
	tired = false

func _ceiling_collision(hit: bool) -> void:
	if !flying:
		return
	
	ceil_hit = hit
	if hit:
		momentum_controller.change_air_velocity(momentum_controller.x_speed,max(0,momentum_controller.y_speed))
		
func _changed_direction(new_direction: float) -> void:
	direction = new_direction

func _tired_timer_timeout() -> void:
	tired = true
	
