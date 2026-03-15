extends Node2D
class_name DropdashDustScene

const DROPDASH_DUST = preload("res://scenes/effects/spindash_dust.tscn")
var dropdash_dust:AnimatedSprite2D
@onready var momentum_controller: MomentumController = $"../.."
		
func create_dropdash_dust() -> void:
	dropdash_dust = DROPDASH_DUST.instantiate()
	var dust_offset = position
	
	if momentum_controller.flipped_image:
		dust_offset.x = -dust_offset.x
	dropdash_dust.global_position = global_position + dust_offset
	
	dropdash_dust.flip_h = momentum_controller.flipped_image
	momentum_controller.get_parent().add_child(dropdash_dust)
	dropdash_dust.play("Release")
