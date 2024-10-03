extends Node2D

@export var playerPrefab: PackedScene
@onready var ogPlayer := $Player



func _on_add_self_pressed() -> void:
	var newPlayer = playerPrefab.instantiate()
	newPlayer.position.x = ogPlayer.position.x + 50 
	newPlayer.position.y = ogPlayer.position.y
	add_child(newPlayer)

func _on_increase_size_pressed() -> void:
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.scale += Vector2(0.1,0.1)
		
func _on_decrease_size_pressed() -> void:
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.scale -= Vector2(0.1,0.1)


func _on_h_slider_value_changed(value: float) -> void:
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.max_hspeed = int(value)
