extends Node2D
class_name SpindashDustScene

const SPINDASH_DUST = preload("res://scenes/effects/spindash_dust.tscn")
@onready var momentum_controller: MomentumController = $"../.."

@export var dust_offset : Vector2 = Vector2(-9,-2)

var spindash_dust

func release_spindash_dust() -> void:
	spindash_dust.play("Release")

func start_spindash_dust(spindash_direction_sign:float) -> void:
	spindash_dust = SPINDASH_DUST.instantiate()

	var final_dust_offset : Vector2 = Vector2(dust_offset.x * spindash_direction_sign, dust_offset.y)

	spindash_dust.global_position = global_position + final_dust_offset
	
	spindash_dust.flip_h = momentum_controller.flipped_image
	momentum_controller.get_parent().add_child(spindash_dust)
