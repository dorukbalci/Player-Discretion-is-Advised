extends Node2D

@export var player1Prefab: PackedScene
@export var player2Prefab: PackedScene
@onready var ogPlayer1 := $Player1
@onready var ogPlayer2 := $Player2



func _on_add_self_pressed() -> void:
	var newPlayer1 = player1Prefab.instantiate()
	newPlayer1.position = ogPlayer1.position
	add_child(newPlayer1)
	var newPlayer2 = player2Prefab.instantiate()
	newPlayer2.position = ogPlayer2.position
	add_child(newPlayer2)

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


func _on_remove_player_pressed() -> void:
	var player1s = get_tree().get_nodes_in_group('Player1')
	var player2s = get_tree().get_nodes_in_group('Player2')
	if len(player1s) >2:
		player1s[-1].queue_free()
		player2s[-1].queue_free()
