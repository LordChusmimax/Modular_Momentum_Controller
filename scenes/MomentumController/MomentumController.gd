extends CharacterBody2D
class_name MomentumController

# ============================================
# SIGNALS
# ============================================
signal state_changed(old_state: State, new_state: State)
signal jumped()

# ============================================
# EXPORTS
# ============================================
@export_group("Ground Movement")
##Max speed on the ground
@export var max_ground_speed: float = 1250.0
##Acceleration on the ground
@export var ground_acceleration: float = 100.0
##Resistance of the ground to movement
@export var ground_friction: float = 100.0
##Breaking strength
@export var ground_deceleration: float = 1000.0

@export_subgroup("Advanced")
##How long coyote time lasts
@export var coyote_max_time: float = 0.05
##Min wall snaping speed, only for collision purposes
@export var min_wall_speed: float = 500.0

@export_group("Spin Movement")
## Resistance of ground to movement while spinning.
## Note: Acceleration during spin not yet implemented.
@export var spin_friction: float = 200.0
##Breaking strength
@export var spin_deceleration: float = 1200.0


@export_group("Air Movement")
##Max speed on the air
@export var max_air_speed: float = 1500.0
##Acceleration on the air (gravity excluded)
@export var air_acceleration: float = 250.0
##Gravity force
@export var gravity:float = 600

@export_group("Jump")
##Strength of the jump
@export var jump_force: float = 350.0

@export_subgroup("Advanced")
##Time the jump is buffered
@export var jump_buffer_time: float = 0.1

@export_group("Slope")
##Extra force down when slipping
@export var slip_force: float = 250.0
##Min speed to stay on walls/roof
@export var min_slip_speed: float = 250.0
##Gravity force during slopes
@export var gravity_slope:float = 600

@export_group("Sensors")
## [Advanced] Sensor configuration.
## Recommended: Do not modify until better organized.ed
@export_subgroup("Advanced")
@export var sensor_floor_offset: float = 22
@export var sensor_floor_length: float = 32
@export var sensor_wall_offset: float = 10
@export var sensor_wall_length: float = 30
@export var sensor_ceil_offset: float = 12
@export var sensor_ceil_length: float = 20



# ============================================
# ONREADY
# ===========================================

# ============================================
# Raycasts
# ============================================
@onready var sensor_floor_left: RayCast2D = $"RayCasts/RayCast2D (sensor_floor_left)"
@onready var sensor_floor_right: RayCast2D = $"RayCasts/RayCast2D (sensor_floor_right)"
@onready var sensor_wall_left: RayCast2D = $"RayCasts/RayCast2D (sensor_wall_left)"
@onready var sensor_wall_right: RayCast2D = $"RayCasts/RayCast2D (sensor_wall_right)"
@onready var sensor_ceil_left: RayCast2D = $"RayCasts/RayCast2D (sensor_ceil_left)"
@onready var sensor_ceil_right: RayCast2D = $"RayCasts/RayCast2D (sensor_ceil_right)"

# ============================================
# Timers
# ============================================
@onready var jump_timer: Timer = $Timers/JumpTimer
@onready var slip_timer: Timer = $Timers/SlipTimer
@onready var coyote_timer: Timer = $Timers/CoyoteTimer
@onready var jump_buffer_timer: Timer = $Timers/JumpBufferTimer

# ============================================
# Others
# ============================================
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D


# ============================================
# PUBLIC VARIABLES
# ============================================
var just_jumped:bool = false
var is_slipping:bool = false
var jump_buffered:bool = false
var coyote_time:bool = false
var jump_cancelable:bool = false
var force_animation:bool = false
var skid_dust_ready:bool = true
var flipped_image:bool = false
var down_is_held:bool = false

enum State {GROUND, AIR, JUMP, SPIN, COYOTE, COYOTE_SPIN, SPECIAL}

var ground_speed: float = 0.0
var x_speed: float = 0.0
var y_speed: float = 0.0 
var direction: float = 0.0
var current_state: int = State.AIR
var last_state: int = State.AIR
var last_normal: Vector2 = Vector2.UP
var last_direction_sign : float = 1

# ============================================
# PRIVATE VARIABLES
# ============================================
var _gravity_vector : Vector2
var _gravity_vector_slope : Vector2

# ============================================
# MAIN PROCESS
# ============================================
func _ready() -> void:
	jump_timer.timeout.connect(jump_timer_timeout)
	slip_timer.timeout.connect(slipping_timer_timeout)
	jump_buffer_timer.timeout.connect(jump_buffer_timer_timeout)
	coyote_timer.timeout.connect(coyote_timer_timeout)
	
	_gravity_vector = Vector2(0,gravity)
	_gravity_vector_slope = Vector2(0,gravity_slope)

	PlayerInput.jump_pressed.connect(_jump_pressed, CONNECT_DEFERRED)
	PlayerInput.jump_released.connect(_jump_released, CONNECT_DEFERRED)
	PlayerInput.down_pressed.connect(_down_pressed, CONNECT_DEFERRED)
	PlayerInput.down_released.connect(_down_released, CONNECT_DEFERRED)
	PlayerInput.changed_direction.connect(_changed_direction, CONNECT_DEFERRED)

func _physics_process(delta: float) -> void:
	
	var hit_floor_left: bool = sensor_floor_left.is_colliding()
	var hit_floor_right: bool = sensor_floor_right.is_colliding()
	
	if sign(direction)!=0:
		last_direction_sign = sign(direction)
	
	_check_state(direction)

	
	match current_state:
		State.GROUND:
			_handle_ground_state(delta, direction, hit_floor_left)
			
		State.SPIN:
			_handle_spin_state(delta, direction, hit_floor_left)
			
		State.COYOTE:
			_handle_coyote_state(delta, direction)
						
		State.COYOTE_SPIN:
			_handle_coyote_spin_state(delta, direction)
		
		State.JUMP:
			_handle_jump_state(delta, direction)
			
		State.AIR:
			_handle_air_state(delta, direction)
		
	_update_sensor_lengths(delta)
	

# ============================================
# States
# ============================================
func _handle_ground_state(delta:float, direction:float, hit_floor_left:bool) -> void :
	rotation = _get_floor_angle()
	var sensor: RayCast2D
	if ground_speed >=0 :
		sensor	= sensor_floor_left if hit_floor_left else sensor_floor_right
	else:
		sensor	= sensor_floor_left if hit_floor_left else sensor_floor_right
	var hit_point: Vector2 = sensor.get_collision_point()
	var hit_normal: Vector2 = sensor.get_collision_normal()
	var tangent: Vector2 = Vector2(-hit_normal.y, hit_normal.x)
			
	if last_state == State.AIR or last_state == State.JUMP:
		var projected : Vector2 = Vector2(x_speed, y_speed).project(tangent)
		ground_speed = projected.length() * sign(projected.dot(tangent))
			
			
	_ground_speed_ground_calculation(delta,direction,tangent)
	_slope_gravity(delta,tangent)
	_ground_snap(delta, hit_point,sensor,tangent)
			
	if jump_buffered:
		_jump(tangent,hit_normal)
		_directionals_air_calculation(delta,direction)
		move_and_collide(Vector2(x_speed, y_speed) * delta)
		return
	
	_side_collision()
	var fallen = _slope_slip(delta,tangent)
	if fallen:
		_side_collision_air()
		_directionals_air_calculation(delta,direction)
		move_and_collide(Vector2(x_speed, y_speed) * delta)
		return
	_ground_move(delta,tangent)
	_ground_speed_to_directionals(tangent)
					
	last_normal = hit_normal
	
func _handle_spin_state(delta:float, direction:float, hit_floor_left:bool)->void:
	rotation = _get_floor_angle()
	var sensor: RayCast2D
	if ground_speed >=0 :
		sensor	= sensor_floor_left if hit_floor_left else sensor_floor_right
	else:
		sensor	= sensor_floor_left if hit_floor_left else sensor_floor_right
	var hit_point: Vector2 = sensor.get_collision_point()
	var hit_normal: Vector2 = sensor.get_collision_normal()
	var tangent: Vector2 = Vector2(-hit_normal.y, hit_normal.x)
		
	_ground_speed_spin_calculation(delta,direction,tangent)
	_slope_spin_gravity(delta,tangent)
	_ground_snap(delta, hit_point,sensor,tangent)
	if jump_buffered:
		_jump(tangent,hit_normal)
		_directionals_air_calculation(delta,direction)
		move_and_collide(Vector2(x_speed, y_speed) * delta)
		return
	_side_collision()
	var fallen = _slope_slip(delta,tangent)
	if fallen:
		_side_collision_air()
		_directionals_air_calculation(delta,direction)
		move_and_collide(Vector2(x_speed, y_speed) * delta)
		return
	_ground_move(delta,tangent)
	_ground_speed_to_directionals(tangent)
	
	
	
	last_normal = hit_normal
	
func _handle_air_state(delta:float, direction:float)->void:
	rotation = 0
	if y_speed<0:
		_ceiling_collision()
	_side_collision_air()
	_directionals_air_calculation(delta,direction)
	move_and_collide(Vector2(x_speed, y_speed) * delta)
	
func _handle_jump_state(delta:float, direction:float)->void:
	
	rotation = 0
	if y_speed<0:
		_ceiling_collision()
	_side_collision_air()
	_directionals_air_calculation(delta,direction)
	move_and_collide(Vector2(x_speed, y_speed) * delta)
			
func _handle_coyote_state(delta:float, direction:float)->void:
	var hit_normal: Vector2 = last_normal
	var tangent: Vector2 = Vector2(-hit_normal.y, hit_normal.x)
	
	if last_state == State.AIR or last_state == State.JUMP:
		var projected : Vector2 = Vector2(x_speed, y_speed).project(tangent)
		ground_speed = projected.length() * sign(projected.dot(tangent))
	
	
	_ground_speed_ground_calculation(delta,direction,tangent)
	_slope_gravity(delta,tangent)
	
	if jump_buffered:
		_jump(tangent,hit_normal)
		_directionals_air_calculation(delta,direction)
		move_and_collide(Vector2(x_speed, y_speed) * delta)
		return
	
	_side_collision()
	_ground_move(delta,tangent)
	_ground_speed_to_directionals(tangent)
	
func _handle_coyote_spin_state(delta:float, direction:float)->void:
	var hit_normal: Vector2 = last_normal
	var tangent: Vector2 = Vector2(-hit_normal.y, hit_normal.x)
	
	if last_state == State.AIR or last_state == State.JUMP:
		var projected : Vector2 = Vector2(x_speed, y_speed).project(tangent)
		ground_speed = projected.length() * sign(projected.dot(tangent))
	
	
	_ground_speed_spin_calculation(delta,direction,tangent)
	_slope_spin_gravity(delta,tangent)
	
	if jump_buffered:
		_jump(tangent,hit_normal)
		_directionals_air_calculation(delta,direction)
		move_and_collide(Vector2(x_speed, y_speed) * delta)
		return
	
	_side_collision()
	_ground_move(delta,tangent)
	_ground_speed_to_directionals(tangent)
	
func _check_state(direction: float) -> void:
	last_state = current_state
	
	if current_state == State.SPECIAL:
		return
	
	if current_state == State.JUMP:
		pass
	
	var angle_difference:float = 0
	var floor_angle:float = 0
	var angle_left: float = 0.0
	var angle_right: float = 0.0
	var diff_left: float = 180.0  # Valor máximo como default
	var diff_right: float = 180.0
	
	var hit_floor: bool = sensor_floor_left.is_colliding() or sensor_floor_right.is_colliding()

	if sensor_floor_left.is_colliding():
		var normal_left = sensor_floor_left.get_collision_normal()
		angle_left = abs(rad_to_deg(normal_left.angle_to(Vector2.UP)))
		diff_left = abs(rad_to_deg(last_normal.angle_to(normal_left)))

	if sensor_floor_right.is_colliding():
		var normal_right = sensor_floor_right.get_collision_normal()
		angle_right = abs(rad_to_deg(normal_right.angle_to(Vector2.UP)))
		diff_right = abs(rad_to_deg(last_normal.angle_to(normal_right)))

# Usa el sensor con menor diferencia angular
	if diff_left < diff_right:
		floor_angle = angle_left
		angle_difference = diff_left
	else:
		floor_angle = angle_right
		angle_difference = diff_right
	
	match last_state:
		State.GROUND:
			if just_jumped:
				current_state = State.AIR
			elif down_is_held and hit_floor and abs(ground_speed) > 100 and abs(direction)<0:
				current_state = State.SPIN
			elif hit_floor and angle_difference<45:
				current_state = State.GROUND
			else:
				current_state = State.AIR
				
			#Coyote Check
			if current_state == State.AIR and floor_angle>45:
				_coyote_starter(State.COYOTE)
		
		State.SPIN:
			if just_jumped:
				current_state = State.AIR
			elif abs(ground_speed) > 100 and angle_difference<45:
				current_state = State.SPIN
			elif angle_difference<45:
				current_state = State.GROUND
			else:
				current_state = State.AIR
				
			#Coyote Check
			if current_state == State.AIR and floor_angle>45:
				_coyote_starter(State.COYOTE_SPIN)
				
		State.AIR:
			if hit_floor and y_speed>=0:
				current_state = State.GROUND
				
		State.JUMP:
			if hit_floor and not just_jumped and y_speed>=0:
				current_state = State.GROUND
			else:
				current_state = State.JUMP
		
		State.COYOTE:
			if hit_floor and not just_jumped:
				current_state = State.GROUND
			elif coyote_time:
				current_state = State.COYOTE
			else:
				current_state = State.AIR
				
		State.COYOTE_SPIN:
			if hit_floor and not just_jumped:
				current_state = State.SPIN
			elif coyote_time:
				current_state = State.COYOTE_SPIN
			else:
				current_state = State.JUMP
				
	if last_state != current_state:
		state_changed.emit(last_state,current_state)
		


# ============================================
# INPUTS
# ============================================
func _jump_pressed() -> void:
	if current_state == State.SPECIAL:
		return
	jump_buffered = true
	jump_buffer_timer.start(jump_buffer_time)

func _jump_released() -> void:
	if jump_cancelable:
		_jump_cancel()	

func _down_pressed() -> void:
	down_is_held = true

func _down_released() -> void:
	down_is_held = false
	
func _changed_direction(new_direction: float) -> void:
	direction = new_direction
# ============================================
# JUMP
# ============================================
		
func _jump(tangent: Vector2, hit_normal: Vector2) -> void:
	jump_cancelable=true
	coyote_time=false
	_ground_speed_to_directionals(tangent)
	x_speed += hit_normal.x * jump_force
	y_speed += hit_normal.y * jump_force
	just_jumped = true
	jump_buffered = false
	jump_timer.start(0.05)
	force_state(State.JUMP)
	jumped.emit()

func _jump_cancel() -> void :
	jump_cancelable=false
	if y_speed<0:
		y_speed *= 0.5


# ============================================
# HELPERS
# ============================================
func _get_floor_angle() -> float:
	var hit_floor_left: bool = sensor_floor_left.is_colliding()
	var hit_floor_right: bool = sensor_floor_right.is_colliding()
	
	if hit_floor_left and hit_floor_right:
		var point_left: Vector2 = sensor_floor_left.get_collision_point()
		var point_right: Vector2 = sensor_floor_right.get_collision_point()
		
		var surface_vector: Vector2 = point_right - point_left
		return surface_vector.angle()
	
	elif hit_floor_left or hit_floor_right:
		var sensor: RayCast2D = sensor_floor_left if hit_floor_left else sensor_floor_right
		return sensor.get_collision_normal().angle() + PI * 0.5
	return 0.0
	
func _coyote_starter(coyote_type: State)->void:
	force_state(coyote_type)
	coyote_time = true
	coyote_timer.start(coyote_max_time)

# ============================================
# MOVEMENT
# ============================================
func _ground_move(delta: float, tangent: Vector2) -> void:
	global_position += tangent * ground_speed * delta

func _ground_snap(delta: float, hit_point: Vector2, sensor: RayCast2D, tangent: Vector2):
	var rotated_offset = Vector2(0, sensor_floor_offset).rotated(rotation)
	var snap_position = hit_point - sensor.position.rotated(rotation) - rotated_offset
	
	var snap_normal = sensor.get_collision_normal()
	var penetration = snap_position - global_position
	
	global_position += snap_normal * penetration.dot(snap_normal)
	
func _ground_speed_ground_calculation(delta: float, direction: float, tangent: Vector2) -> void:
	if is_slipping:
		return
	if abs(direction) < 0:
		ground_speed = move_toward(ground_speed, 0, ground_friction* delta)
	elif sign(direction) == sign(ground_speed) or ground_speed == 0:
		ground_speed = move_toward(ground_speed, sign(direction) * max_ground_speed, ground_acceleration * delta)
	else:
		ground_speed = move_toward(ground_speed, sign(direction) * max_ground_speed, ground_deceleration * delta)
	
func _ground_speed_spin_calculation(delta: float, direction: float, tangent: Vector2) -> void:
	if is_slipping:
		return
	if sign(direction) != sign(ground_speed) and abs(direction)>0:
		ground_speed = move_toward(ground_speed, sign(direction) * max_ground_speed, spin_deceleration * delta)
	else:
		ground_speed = move_toward(ground_speed, 0, spin_friction* delta)
	
func _slope_gravity(delta: float,tangent: Vector2) -> void:
	var slope_angle: float = abs(rad_to_deg(rotation))
	var upside_down: bool = slope_angle>90
	
	var gravity_along_slope: float = _gravity_vector_slope.dot(tangent)
	
	if slope_angle < 20:
		gravity_along_slope = 0
	
	ground_speed += gravity_along_slope * delta
	
func _slope_spin_gravity(delta: float, tangent: Vector2) -> void:
	var gravity_along_slope: float = _gravity_vector_slope.dot(tangent)
	
	var multiplier := 2.5 if sign(gravity_along_slope) * sign(ground_speed) > 0 else 1.0
	ground_speed += gravity_along_slope * multiplier * delta

func _slope_slip(delta: float,tangent: Vector2) -> bool:
	var slope_angle :float = abs(rad_to_deg(rotation))
	var slip_along_slope: float = Vector2(0,slip_force).dot(tangent)
	if slope_angle > 45.0 and slope_angle < 90.0:
		if abs(ground_speed) < min_slip_speed:
			ground_speed += sin(rotation) * slip_force * delta
			is_slipping=true
			slip_timer.start(0.75)
			
	
	elif slope_angle >= 90.0:
		if abs(ground_speed) < min_slip_speed:
			rotation = 0
			force_state(State.AIR)
			return true
	return false

func _ground_speed_to_directionals(tangent: Vector2) -> void:
	x_speed = tangent.x * ground_speed
	y_speed = tangent.y * ground_speed

func _directionals_air_calculation(delta: float,direction: float) -> void:
	x_speed = move_toward(x_speed, max_air_speed * sign(direction), air_acceleration*delta)
	y_speed += _gravity_vector.y * delta



# ============================================
# COLLISIONS
# ============================================
func _ceiling_collision() -> void:
	var hit_ceiling: bool = sensor_ceil_left.is_colliding() or sensor_ceil_right.is_colliding()
	if hit_ceiling:
		y_speed=0
		
func _side_collision() -> void:
	sensor_wall_left.force_raycast_update()
	sensor_wall_right.force_raycast_update()
	var rotated_offset = Vector2(sensor_wall_offset, 0).rotated(rotation)
	var hit_wall_left = sensor_wall_left.is_colliding()
	var hit_wall_right = sensor_wall_right.is_colliding()
	if hit_wall_left and ground_speed<0:
		if ground_speed<-min_wall_speed or (global_position-sensor_wall_left.get_collision_point()).length()<sensor_wall_offset:
			global_position = sensor_wall_left.get_collision_point() + sensor_wall_left.position.rotated(rotation) + rotated_offset
			ground_speed = max(ground_speed,0)
	if hit_wall_right  and ground_speed>0:
		if ground_speed>min_wall_speed or (global_position-sensor_wall_right.get_collision_point()).length()<sensor_wall_offset:
			global_position = sensor_wall_right.get_collision_point() + sensor_wall_right.position.rotated(rotation) - rotated_offset
			ground_speed = min(ground_speed,0)
			
func _side_collision_air() -> void:
	sensor_wall_left.force_raycast_update()
	sensor_wall_right.force_raycast_update()
	var offset_vector = Vector2(sensor_wall_offset, 0)
	var hit_wall_left = sensor_wall_left.is_colliding()
	var hit_wall_right = sensor_wall_right.is_colliding()
	if hit_wall_left and x_speed<0:
		if x_speed<-min_wall_speed or (global_position-sensor_wall_left.get_collision_point()).length()<sensor_wall_offset:
			global_position = sensor_wall_left.get_collision_point() + sensor_wall_left.position.rotated(rotation) + offset_vector
			x_speed = max(x_speed,0)
	if hit_wall_right  and x_speed>0:
		if x_speed>min_wall_speed or (global_position-sensor_wall_right.get_collision_point()).length()<sensor_wall_offset:
			global_position = sensor_wall_right.get_collision_point() + sensor_wall_right.position.rotated(rotation) - offset_vector
			x_speed = min(x_speed,0)

func _update_sensor_lengths(delta: float) -> void:
	var speed : float
	if current_state == State.GROUND:
		speed = abs(ground_speed)
	elif current_state == State.SPIN:
		speed = abs(ground_speed)
	elif current_state == State.COYOTE:
		speed = abs(ground_speed)
	elif current_state == State.COYOTE_SPIN:
		speed = abs(ground_speed)
	elif current_state == State.AIR:
		speed = Vector2(x_speed, y_speed).length()
	elif current_state == State.JUMP:
		speed = Vector2(x_speed, y_speed).length()
	
	var dynamic_length : float = speed * delta/3
	
	var total_length := sensor_floor_length + dynamic_length
	var total_ceil_length := sensor_ceil_offset + dynamic_length
	
	sensor_floor_left.target_position.y = total_length
	sensor_floor_right.target_position.y = total_length
	sensor_wall_left.target_position.x = -total_length
	sensor_wall_right.target_position.x = total_length
	sensor_ceil_left.target_position.y = -total_ceil_length
	sensor_ceil_right.target_position.y = -total_ceil_length


# ============================================
# CALLABLES
# ============================================
##Forces the controller into a specific State.
##Use Special for an undefined one
func force_state(new_state: State) -> void:
	if current_state != new_state:
		last_state = current_state
		current_state = new_state
		state_changed.emit(last_state,current_state)
		
##Changes the speed of the controller
##Direction 0 or no direction means we keep the current direction
func change_velocity(module: float, direction: float = 0) -> void:
	direction = direction if direction!=0 else sign(ground_speed) 
	ground_speed = module * direction

##Adds speed to the controller
##Direction 0 or no direction means we keep the current direction
func add_velocity(module: float, direction: float = 0) -> void:
	direction = direction if direction!=0 else sign(ground_speed) 
	ground_speed += module * direction

# ============================================
# TIMERS
# ============================================
func jump_timer_timeout() -> void:
	just_jumped = false
	
func slipping_timer_timeout() -> void:
	is_slipping = false
	
func jump_buffer_timer_timeout() -> void :
	jump_buffered = false
	
func coyote_timer_timeout() -> void:
	coyote_time = false
