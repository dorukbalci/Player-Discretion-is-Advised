extends Node2D

@export var player1Prefab: PackedScene
@export var player2Prefab: PackedScene
@onready var ogPlayer1 := $Players/Player1
@onready var ogPlayer2 := $Players/Player2

var paused = false
func _ready() -> void:
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	toggle_pause(delta)


func toggle_pause(delta : float):
	if Input.is_action_just_pressed('pause'):
		paused = !paused
		$"Canvas Layer/Rule Panel".visible = !$"Canvas Layer/Rule Panel".visible
		$"Canvas Layer/Pause Text".visible =  !$"Canvas Layer/Pause Text".visible
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.paused = paused

#ADD PLAYER
func _on_add_self_pressed() -> void:
	var newPlayer1 = player1Prefab.instantiate()
	newPlayer1.position = ogPlayer1.position
	add_child(newPlayer1)
	
	var newPlayer2 = player2Prefab.instantiate()
	newPlayer2.position = ogPlayer2.position
	add_child(newPlayer2)

#INCREASE SIZE
func _on_increase_size_pressed() -> void:
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.scale += Vector2(0.1,0.1)

#DECREASE SIZE
func _on_decrease_size_pressed() -> void:
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.scale -= Vector2(0.1,0.1)

#CHANGE SPEED
func _on_h_slider_value_changed(value: float) -> void:
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.max_hspeed = int(value)

#REMOVE PLAYER
func _on_remove_player_pressed() -> void:
	var player1s = get_tree().get_nodes_in_group('Player1')
	var player2s = get_tree().get_nodes_in_group('Player2')
	if len(player1s) >1:
		player1s[-1].queue_free()
		player2s[-1].queue_free()


func _on_start_pressed() -> void:
	if Input.is_action_just_pressed('pause'):
		$Players.get_tree().paused = false
