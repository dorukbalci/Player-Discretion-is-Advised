extends Node2D

@export var player1Prefab: PackedScene
@export var player2Prefab: PackedScene
@onready var ogPlayer1 := $Players/Player1
@onready var ogPlayer2 := $Players/Player2

var bullet_scene = preload('res://Components/Player/Physical Bullet/PhysicalBullet.tscn') 
var target_input_action : String
var waiting_for_key := false

var paused = false
var one_hit_mode := false
var round_timer_enabled := false
var round_time := 30.0
var round_time_remaining := 0.0
var round_active := false

@export var mapArray: Array[PackedScene]
var current_map = 0
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
	update_round_timer(delta)


#START ROUND
func _on_start_round_pressed() -> void:
	paused = false
	round_active = true
	$"Canvas Layer/DeckParent".visible = false
	if round_timer_enabled:
		round_time_remaining = round_time
		$"Canvas Layer/RoundTimerLabel".visible = true
		$"Canvas Layer/RoundTimerLabel".text = str(int(round_time_remaining))
	else:
		$"Canvas Layer/RoundTimerLabel".visible = false
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.damageable = true
		if one_hit_mode:
			player.max_health = 1
			player.current_health = 1
			player.healthbar.max_value = 1
			player.healthbar.value = 1

#END ROUND WHEN THERE'S NO PLAYER LEFT OF A TEAM
func end_round(delta:float):
	#Check the Amount of players

	var p1_amount = get_tree().get_node_count_in_group('Player1')
	var p2_amount = get_tree().get_node_count_in_group('Player2')
	if p1_amount == 0:
		GameState.p2score += 1
		$"Canvas Layer/Scores/Player2".text = ' P2 Score: ' + str(GameState.p2score)
		$"Canvas Layer/Scores/Player1".text = ' P1 Score: ' + str(GameState.p1score)
	if p2_amount == 0:
		GameState.p1score += 1
		$"Canvas Layer/Scores/Player1".text = ' P1 Score: ' + str(GameState.p1score)
		$"Canvas Layer/Scores/Player2".text = ' P2 Score: ' + str(GameState.p2score)
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
		var players = get_tree().get_nodes_in_group('Player')
		for player in players:
			player.queue_free()
		_on_add_self_pressed()
		$"Canvas Layer/DeckParent".visible = true
		for player in players:
			player.damageable = false
		

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
	$"Canvas Layer/DeckParent/Rule Panel/GridContainer/P1 Input/Dash/Label".text = OS.get_keycode_string(InputMap.action_get_events("dash_0")[0].keycode)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/P1 Input/Right/p1text5'.text = OS.get_keycode_string(InputMap.action_get_events("move_right_0")[0].keycode)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/P1 Input/Left/p1text4'.text = OS.get_keycode_string(InputMap.action_get_events("move_left_0")[0].keycode)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/P1 Input/Shoot/Label'.text = OS.get_keycode_string(InputMap.action_get_events("shoot_0")[0].keycode)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/P1 Input/Block/Label'.text = OS.get_keycode_string(InputMap.action_get_events("block_0")[0].keycode)
	
	$"Canvas Layer/DeckParent/Rule Panel/GridContainer/P2 Input/Up/p1text2".text = OS.get_keycode_string(InputMap.action_get_events("jump_1")[0].keycode)
	$"Canvas Layer/DeckParent/Rule Panel/GridContainer/P2 Input/Dash/p1text3".text = OS.get_keycode_string(InputMap.action_get_events("dash_1")[0].keycode)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/P2 Input/Right/p1text5'.text = OS.get_keycode_string(InputMap.action_get_events("move_right_1")[0].keycode)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/P2 Input/Left/p1text4'.text = OS.get_keycode_string(InputMap.action_get_events("move_left_1")[0].keycode)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/P2 Input/Shoot/Label'.text = OS.get_keycode_string(InputMap.action_get_events("shoot_1")[0].keycode)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/P2 Input/Block/Label'.text = OS.get_keycode_string(InputMap.action_get_events("block_1")[0].keycode)

#CHANGE INPUT FOR PLAYER
func _on_p_1_up_pressed() -> void:
	target_input_action = 'jump_0'
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


func _on_p_2_right_pressed() -> void:
	target_input_action = 'move_right_1'
	waiting_for_key = true

func _on_p_2_left_pressed() -> void:
	target_input_action = 'move_left_1'
	waiting_for_key = true

func _on_p_2_shoot_pressed() -> void:
	target_input_action = 'shoot_1'
	waiting_for_key = true

func _on_p_1_block_pressed() -> void:
	target_input_action = 'block_0'
	waiting_for_key = true


func _on_p_2_block_pressed() -> void:
	target_input_action = 'block_0'
	waiting_for_key = true


func _on_p_1_dash_pressed() -> void:
	target_input_action = 'dash_0'
	waiting_for_key = true

func _on_p_2_dash_pressed() -> void:
	target_input_action = 'dash_1'
	waiting_for_key = true

func _on_bullet_timer_slider_value_changed(value: float) -> void:
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.shoot_cooldown = value /100


func _on_map_minus_pressed() -> void:
	current_map -= 1
	for child in $Maps.get_children():
		child.queue_free()
	var new_map_id = current_map % mapArray.size()
	var new_map = mapArray[new_map_id].instantiate()
	$Maps.add_child(new_map)


func _on_map_plus_pressed() -> void:
	current_map += 1
	for child in $Maps.get_children():
		child.queue_free()
	var new_map_id = current_map % mapArray.size()
	var new_map = mapArray[new_map_id].instantiate()
	$Maps.add_child(new_map)


func _on_minus_p_1_pressed() -> void:
	GameState.p1score -= 1
	$"Canvas Layer/Scores/Player1".text = ' P1 Score: ' + str(GameState.p1score)


func _on_positive_p_1_pressed() -> void:
	GameState.p1score += 1
	$"Canvas Layer/Scores/Player1".text = ' P1 Score: ' + str(GameState.p1score)


func _on_minus_p_2_pressed() -> void:
	GameState.p2score -= 1
	$"Canvas Layer/Scores/Player2".text = ' P2 Score: ' + str(GameState.p2score)


func _on_positive_p_2_pressed() -> void:
	GameState.p2score += 1
	$"Canvas Layer/Scores/Player2".text = ' P2 Score: ' + str(GameState.p2score)


func _on_jump_q_minus_pressed() -> void:
	var players = get_tree().get_nodes_in_group('Player')
	var jump_am 
	for player in players:
		if player.jump_amount > 0:
			player.jump_amount += -1
			jump_am = player.jump_amount
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/LevelPhysics/JumpAmount/Label'.text = 'Jump Amount:' + str(jump_am)


func _on_jump_q_plus_pressed() -> void:
	var players = get_tree().get_nodes_in_group('Player')
	var jump_am 
	for player in players:
		player.jump_amount += 1
		jump_am = player.jump_amount
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/LevelPhysics/JumpAmount/Label'.text = 'Jump Amount:' + str(jump_am)


func _on_block_duration_slider_value_changed(value: float) -> void:
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.block_duration = value / 10.0
	$"Canvas Layer/DeckParent/Rule Panel/GridContainer/LevelPhysics/BlockDurationLabel".text = 'Block Duration: %s' % str(value/10.0)


func _on_block_cool_down_slider_value_changed(value: float) -> void:
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.block_cooldown = value / 10.0
	$"Canvas Layer/DeckParent/Rule Panel/GridContainer/LevelPhysics/BlockCoolDownLabel".text = 'Block Duration: %s' % str(value/10.0)


#Dash Variables

func _on_d_speed_slider_value_changed(value: float) -> void:
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.dash_speed = value * 1000
	$"Canvas Layer/DeckParent/Rule Panel/GridContainer/DashVars/DashSpeed".text = 'Dash Speed: %s' % str(value)


func _on_d_duration_slider_value_changed(value: float) -> void:
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.dash_duration = value / 50.0
	$"Canvas Layer/DeckParent/Rule Panel/GridContainer/DashVars/DashDuration".text = 'Dash Duration: %s' % str(value/50.0)


func _on_bullet_bounce_minus_pressed() -> void:
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		if player.bullet_bounces > 0:
			player.bullet_bounces -= 1
	if players.size() > 0:
		$'Canvas Layer/DeckParent/Rule Panel/GridContainer/BulletRules/BulletBounce/BulletBounceLabel'.text = 'Bounces: %s' % str(players[0].bullet_bounces)

func _on_bullet_bounce_plus_pressed() -> void:
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.bullet_bounces += 1
	if players.size() > 0:
		$'Canvas Layer/DeckParent/Rule Panel/GridContainer/BulletRules/BulletBounce/BulletBounceLabel'.text = 'Bounces: %s' % str(players[0].bullet_bounces)

func _on_knockback_slider_value_changed(value: float) -> void:
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.knockback_force = value
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/BulletRules/KnockbackLabel'.text = 'Knockback: %s' % str(int(value))

func _on_one_hit_toggled(toggled_on: bool) -> void:
	one_hit_mode = toggled_on

func _on_bullet_count_minus_pressed() -> void:
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		if player.bullet_count > 1:
			player.bullet_count -= 1
	if players.size() > 0:
		$'Canvas Layer/DeckParent/Rule Panel/GridContainer/BulletRules/BulletCount/BulletCountLabel'.text = 'Bullets: %s' % str(players[0].bullet_count)

func _on_bullet_count_plus_pressed() -> void:
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.bullet_count += 1
	if players.size() > 0:
		$'Canvas Layer/DeckParent/Rule Panel/GridContainer/BulletRules/BulletCount/BulletCountLabel'.text = 'Bullets: %s' % str(players[0].bullet_count)

func _on_d_cooldown_slider_value_changed(value: float) -> void:
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.dash_cooldown = value / 50.0
	$"Canvas Layer/DeckParent/Rule Panel/GridContainer/DashVars/DashCooldown".text = 'Dash Cooldown: %s' % str(value/50.0)

func _on_friction_slider_value_changed(value: float) -> void:
	var players = get_tree().get_nodes_in_group('Player')
	var fric = value / 100.0
	for player in players:
		player.friction = fric
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/LevelPhysics/FrictionLabel'.text = 'Friction: %s' % str(snapped(fric, 0.01))

func _on_reflect_on_block_toggled(toggled_on: bool) -> void:
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.reflect_on_block = toggled_on

func _on_round_timer_toggled(toggled_on: bool) -> void:
	round_timer_enabled = toggled_on

func _on_round_time_slider_value_changed(value: float) -> void:
	round_time = value
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/BasicRules/RoundTimeLabel'.text = 'Round Time: %ss' % str(int(value))

func update_round_timer(delta: float) -> void:
	if not round_active or not round_timer_enabled:
		return
	round_time_remaining -= delta
	$"Canvas Layer/RoundTimerLabel".text = str(int(round_time_remaining) + 1)
	if round_time_remaining <= 0.0:
		round_active = false
		$"Canvas Layer/RoundTimerLabel".visible = false
		var p1s = get_tree().get_nodes_in_group('Player1')
		var p2s = get_tree().get_nodes_in_group('Player2')
		var p1_health := 0
		var p2_health := 0
		for p in p1s:
			p1_health += p.current_health
		for p in p2s:
			p2_health += p.current_health
		if p1_health > p2_health:
			for p in p2s:
				p.current_health = 0
		elif p2_health > p1_health:
			for p in p1s:
				p.current_health = 0
		else:
			for p in p1s + p2s:
				p.current_health = 0

func _on_random_roulette_pressed() -> void:
	var players = get_tree().get_nodes_in_group('Player')
	var speed_val = randi_range(5000, 50000)
	var gravity_val = randi_range(200, 5000)
	var jump_force_val = randi_range(100, 800)
	var jump_amount_val = randi_range(1, 5)
	var bullet_force_val = randi_range(100, 8000)
	var bullet_size_val = randf_range(0.2, 3.0)
	var bullet_count_val = randi_range(1, 7)
	var bullet_bounces_val = randi_range(0, 5)
	var knockback_val = randf_range(0, 2000)
	var friction_val = randf_range(0.0, 1.0)
	var dash_speed_val = randi_range(10000, 200000)
	var dash_dur_val = randf_range(0.05, 0.5)
	var shoot_cd_val = randf_range(0.0, 2.0)
	var reflect_val = randi_range(0, 1) == 1
	var one_hit_val = randi_range(0, 4) == 0

	for player in players:
		player.speed = speed_val
		player.max_hspeed = speed_val
		player.gravity = gravity_val
		player.jumpForce = jump_force_val
		player.jump_amount = jump_amount_val
		player.shoot_speed = bullet_force_val
		player.bullet_size = bullet_size_val
		player.bullet_count = bullet_count_val
		player.bullet_bounces = bullet_bounces_val
		player.knockback_force = knockback_val
		player.friction = friction_val
		player.dash_speed = dash_speed_val
		player.dash_duration = dash_dur_val
		player.shoot_cooldown = shoot_cd_val
		player.reflect_on_block = reflect_val

	one_hit_mode = one_hit_val

	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/PlayerRules/SpeedSlider'.value = speed_val
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/LevelPhysics/Gravity Slider'.value = gravity_val
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/LevelPhysics/JumpAmount/Label'.text = 'Jump Amount: %s' % str(jump_amount_val)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/BulletRules/BulletForceSlider'.value = bullet_force_val
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/BulletRules/BulletCount/BulletCountLabel'.text = 'Bullets: %s' % str(bullet_count_val)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/BulletRules/BulletBounce/BulletBounceLabel'.text = 'Bounces: %s' % str(bullet_bounces_val)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/BulletRules/KnockbackSlider'.value = knockback_val
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/LevelPhysics/FrictionLabel'.text = 'Friction: %s' % str(snapped(friction_val, 0.01))
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/LevelPhysics/FrictionSlider'.value = friction_val * 100
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/LevelPhysics/ReflectOnBlock'.button_pressed = reflect_val
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/LevelPhysics/OneHitMode'.button_pressed = one_hit_val
