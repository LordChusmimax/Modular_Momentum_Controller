extends Area2D

@export var node_5: Node2D
@export var node_2: Node2D
@export var back: bool

func _ready() -> void:
	area_entered.connect(_on_area_entered)  # Detecta Area2D

func _on_area_entered(area: Area2D) -> void:
	# Verifica si el área pertenece al personaje
	if area.name == "Character_Hitbox":
		node_5.visible = not back
		node_2.visible = back
