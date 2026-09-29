extends Node2D

@export_multiline var texto_npc: String = "¡Hola, viajero!"

func _ready() -> void:
	%Label.text = texto_npc
	$LabelContainer.hide()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		$LabelContainer.show()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		$LabelContainer.hide()
