extends Node2D

@export var player1Prefab: PackedScene
@export var player2Prefab: PackedScene
@onready var ogPlayer1 := $Players/Player1
@onready var ogPlayer2 := $Players/Player2

var bullet_scene = preload('res://Components/Player/Physical Bullet/PhysicalBullet.tscn') 
var target_input_action : String
var waiting_for_key := false

var paused = false
func _ready() -> void:
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.damageable = false
	var root = self
	var control_count = count_control_nodes(root)
	print("Number of Control nodes in the scene: ", control_count)
	#update_input_labels()

#Count Amount of Control Nodes
func count_control_nodes(node: Node) -> int:
	var count = 0
	# Check if the current node is a Control
	if node is Control:
		count += 1
	# Recursively check all child nodes
	for child in node.get_children():
		count += count_control_nodes(child)
	return count

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

#END ROUND WHEN THERE'S NO PLAYER LEFT OF A TEAM
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

#DECREASE HORIZONTAL SIZE
func _on_decrease_horizontal_size_pressed() -> void:
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.scale -= Vector2(0.1,0.0)

#INCREASE HORIZONTAL SIZE
func _on_increase_horizontal_size_pressed() -> void:
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.scale += Vector2(0.1,0.0)

#DECREASE VERTICAL
func _on_decrease_vertical_size_pressed() -> void:
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.scale -= Vector2(0.0,0.1)

#INCREASE VERTICAL
func _on_increase_vertical_size_pressed() -> void:
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.scale += Vector2(0.0,0.1)

#Listen for Input
func _input(event: InputEvent):
	if waiting_for_key and event is InputEventKey and event.pressed:
		bind_key_to_action(event.keycode)

#Bind the next pressed key to an input map action
func bind_key_to_action(keycode: int):
	waiting_for_key = false
	# Create a new InputEventKey
	var events = InputMap.action_get_events(target_input_action)
	# Remove each event from the action
	for event in events:
		InputMap.action_erase_event(target_input_action, event)
	print("Cleared all keys from action: ",target_input_action)
	
	
	var key_event = InputEventKey.new()
	key_event.keycode = keycode
	
	# Add the key event to the action
	InputMap.action_add_event(target_input_action, key_event)
	print("Assigned ", keycode, " to action: ", target_input_action)
	update_input_labels()

func update_input_labels():
	$"Canvas Layer/DeckParent/Rule Panel/GridContainer/P1 Input/Up/p1text2".text = OS.get_keycode_string(InputMap.action_get_events("jump_0")[0].keycode)
	$"Canvas Layer/DeckParent/Rule Panel/GridContainer/P1 Input/Down/p1text3".text = OS.get_keycode_string(InputMap.action_get_events("down_0")[0].keycode)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/P1 Input/Right/p1text5'.text = OS.get_keycode_string(InputMap.action_get_events("move_right_0")[0].keycode)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/P1 Input/Left/p1text4'.text = OS.get_keycode_string(InputMap.action_get_events("move_left_0")[0].keycode)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/P1 Input/Shoot/Label'.text = OS.get_keycode_string(InputMap.action_get_events("shoot_0")[0].keycode)
	
	$"Canvas Layer/DeckParent/Rule Panel/GridContainer/P2 Input/Up/p1text2".text = OS.get_keycode_string(InputMap.action_get_events("jump_1")[0].keycode)
	$"Canvas Layer/DeckParent/Rule Panel/GridContainer/P2 Input/Down/p1text3".text = OS.get_keycode_string(InputMap.action_get_events("down_1")[0].keycode)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/P2 Input/Right/p1text5'.text = OS.get_keycode_string(InputMap.action_get_events("move_right_1")[0].keycode)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/P2 Input/Left/p1text4'.text = OS.get_keycode_string(InputMap.action_get_events("move_left_1")[0].keycode)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/P2 Input/Shoot/Label'.text = OS.get_keycode_string(InputMap.action_get_events("shoot_1")[0].keycode)

#CHANGE INPUT FOR PLAYER
func _on_p_1_up_pressed() -> void:
	target_input_action = 'jump_0'
	waiting_for_key = true

func _on_p_1_down_pressed() -> void:
	target_input_action = 'down_0'
	waiting_for_key = true

func _on_p_1_right_pressed() -> void:
	target_input_action = 'move_right_0'
	waiting_for_key = true

func _on_p_1_left_pressed() -> void:
	target_input_action = 'move_left_0'
	waiting_for_key = true

func _on_p_1_shoot_pressed() -> void:
	target_input_action = 'shoot_0'
	waiting_for_key = true

func _on_p_2_up_pressed() -> void:
	target_input_action = 'jump_1'
	waiting_for_key = true

func _on_p_2_down_pressed() -> void:
	target_input_action = 'down_1'
	waiting_for_key = true

func _on_p_2_right_pressed() -> void:
	target_input_action = 'move_right_1'
	waiting_for_key = true

func _on_p_2_left_pressed() -> void:
	target_input_action = 'move_left_1'
	waiting_for_key = true

func _on_p_2_shoot_pressed() -> void:
	target_input_action = 'shoot_1'
	waiting_for_key = true
