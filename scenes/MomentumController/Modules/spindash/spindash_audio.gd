extends Node2D

@onready var spindash: Node2D = $".."
@onready var spindash_sound: AudioStreamPlayer2D = $SpindashSound
@onready var release_sound: AudioStreamPlayer2D = $ReleaseSound

func release_spindash():
	release_sound.play()

func load_spindash(charge:float) -> void:
	spindash_sound.pitch_scale = 0.75+charge
	spindash_sound.play()
