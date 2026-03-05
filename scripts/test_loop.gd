extends Area2D

@onready var right:CollisionPolygon2D=$"../StaticBody2D/Right"
@onready var left:CollisionPolygon2D=$"../StaticBody2D/Left"
@export var forward: bool

func _ready() -> void:
	area_entered.connect(_on_area_entered)  # Detecta Area2D

func _on_area_entered(area: Area2D) -> void:
	# Verifica si el área pertenece al personaje
	if area.name == "Character_Hitbox":
		right.set_deferred("disabled",not forward)
		left.set_deferred("disabled",forward)
