extends Node2D

@export var player1Prefab: PackedScene
@export var player2Prefab: PackedScene
@onready var ogPlayer1 := $Players/Player1
@onready var ogPlayer2 := $Players/Player2

var bullet_scene = preload('res://Components/Player/Physical Bullet/PhysicalBullet.tscn') 

var paused = false
func _ready() -> void:
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.damageable = false

func _process(delta: float) -> void:
	toggle_pause(delta)
	end_round(delta)

#START ROUND
func _on_start_round_pressed() -> void:
	paused = false
	$"Canvas Layer/DeckParent".visible = false
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.damageable = true

func end_round(delta:float):
	#Check the Amount of players
	var p1_amount = get_tree().get_node_count_in_group('Player1')
	var p2_amount = get_tree().get_node_count_in_group('Player2')
	if p1_amount == 0:
		GameState.p2score += 1
		$"Canvas Layer/Scores/Player2".text = ' P2 Score: ' + str(GameState.p2score)
	if p2_amount == 0:
		GameState.p1score += 1
		$"Canvas Layer/Scores/Player1".text = ' P1 Score: ' + str(GameState.p1score)
	#Remove All Players
	if p1_amount == 0 or p2_amount == 0:
		var players = get_tree().get_nodes_in_group('Player')
		for player in players:
			player.queue_free()
		_on_add_self_pressed()
		$"Canvas Layer/DeckParent".visible = true
		for player in players:
			player.damageable = false

#PAUSE GAME
func toggle_pause(delta : float):
	if Input.is_action_just_pressed('pause'):
		paused = !paused
		$"Canvas Layer/Rule Panel".visible = !$"Canvas Layer/Rule Panel".visible
		$"Canvas Layer/Rule BG".visible = !$"Canvas Layer/Rule BG".visible
		$"Canvas Layer/Pause Text".visible =  !$"Canvas Layer/Pause Text".visible
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.paused = paused

#ADD PLAYER
func _on_add_self_pressed() -> void:
	var newPlayer1 = player1Prefab.instantiate()
	newPlayer1.position = $SpawnPoints/P1spawn.position
	add_child(newPlayer1)
	
	var newPlayer2 = player2Prefab.instantiate()
	newPlayer2.position = $SpawnPoints/P2spawn.position
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
		player.speed = int(value)
		player.max_hspeed = int(value)

#REMOVE PLAYER
func _on_remove_player_pressed() -> void:
	var player1s = get_tree().get_nodes_in_group('Player1')
	var player2s = get_tree().get_nodes_in_group('Player2')
	if len(player1s) >1:
		player1s[-1].queue_free()
		player2s[-1].queue_free()

#RESET RULES
func _on_reset_rules_pressed() -> void:
	# Get the path of the current scene
	var current_scene_path = get_tree().current_scene.scene_file_path
	
	# Reload the scene using change_scene_to_file
	get_tree().change_scene_to_file(current_scene_path)

#INCREASE BULLET SIZE
func _on_increase_bullet_size_pressed() -> void:
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.bullet_size += .2

#DECREASE BULLET SIZE
func _on_decrease_bullet_size_pressed() -> void:
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.bullet_size -= .2

#CHANGE BULLET FORCE
func _on_bullet_force_slider_value_changed(value: float) -> void:
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.shoot_speed = value

#DECREASE JUMP FORCE
func _on_decrease_jump_force_pressed() -> void:
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.jumpForce -= 50

#INCREASE JUMP FORCE
func _on_increase_jump_force_2_pressed() -> void:
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.jumpForce += 50

#Change Gravity
func _on_gravity_slider_value_changed(value: float) -> void:
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.gravity = value
	
