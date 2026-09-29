extends Node2D

@onready var colision = $Area2D/CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Global.cuchillo == true:
		show()
		colision.set_deferred("disable", false)
	else:
		hide()
		colision.set_deferred("disabled", true)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player" and Global.cuchillo == true:
		get_tree().change_scene_to_file("res://Nazomek¡3.tscn")
	
