extends Node2D
class_name DropdashAudio

@onready var spindash: Node2D = $".."
@onready var dropdash_charge_sound: AudioStreamPlayer2D = $DropdashChargeSound
@onready var release_sound: AudioStreamPlayer2D = $ReleaseSound

func charge_dropdash():
	dropdash_charge_sound.play()

func land_dropdash() -> void:
	release_sound.play()
