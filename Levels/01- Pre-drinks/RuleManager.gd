extends Node2D

@export var player1Prefab: PackedScene
@export var player2Prefab: PackedScene
@onready var ogPlayer1 := $Players/Player1
@onready var ogPlayer2 := $Players/Player2

var bullet_scene = preload('res://Components/Player/Physical Bullet/PhysicalBullet.tscn')
var target_input_action : String
var waiting_for_key := false

var paused = false
var round_time_remaining := 0.0
var round_active := false

@export var mapArray: Array[PackedScene]

func _ready() -> void:
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.damageable = false
	GameState.apply_ruleset_to_all(get_tree())
	sync_ui_to_ruleset()

func _process(delta: float) -> void:
	toggle_pause(delta)
	end_round(delta)
	update_round_timer(delta)

func sync_ui_to_ruleset() -> void:
	var r = GameState.ruleset
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/PlayerRules/SpeedSlider'.value = r.speed
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/LevelPhysics/Gravity Slider'.value = r.gravity
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/LevelPhysics/JumpAmount/Label'.text = 'Jump Amount: %s' % str(r.jump_amount)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/BulletRules/BulletForceSlider'.value = r.shoot_speed
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/BulletRules/BulletTimerSlider'.value = r.shoot_cooldown * 100
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/BulletRules/BulletCount/BulletCountLabel'.text = 'Bullets: %s' % str(r.bullet_count)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/BulletRules/BulletBounce/BulletBounceLabel'.text = 'Bounces: %s' % str(r.bullet_bounces)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/BulletRules/KnockbackSlider'.value = r.knockback_force
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/LevelPhysics/FrictionLabel'.text = 'Friction: %s' % str(snapped(r.friction, 0.01))
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/LevelPhysics/FrictionSlider'.value = r.friction * 100
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/LevelPhysics/ReflectOnBlock'.button_pressed = r.reflect_on_block
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/LevelPhysics/OneHitMode'.button_pressed = r.one_hit_mode
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/LevelPhysics/BlockDurationLabel'.text = 'Block Duration: %s' % str(r.block_duration)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/LevelPhysics/BlockDurationSlider'.value = r.block_duration * 10.0
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/LevelPhysics/BlockCoolDownLabel'.text = 'Block Cooldown: %s' % str(r.block_cooldown)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/LevelPhysics/BlockCoolDownSlider'.value = r.block_cooldown * 10.0
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/DashVars/DashSpeed'.text = 'Dash Speed: %s' % str(r.dash_speed / 1000)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/DashVars/DSpeedSlider'.value = r.dash_speed / 1000
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/DashVars/DashDuration'.text = 'Dash Duration: %s' % str(r.dash_duration)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/DashVars/DDurationSlider'.value = r.dash_duration * 50.0
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/DashVars/DashCooldown'.text = 'Dash Cooldown: %s' % str(r.dash_cooldown)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/DashVars/DCooldownSlider'.value = r.dash_cooldown * 50.0
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/BasicRules/RoundTimer'.button_pressed = r.round_timer_enabled
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/BasicRules/RoundTimeLabel'.text = 'Round Time: %ss' % str(int(r.round_time))
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/BasicRules/RoundTimeSlider'.value = r.round_time

func _update_rule(key: String, value) -> void:
	GameState.ruleset[key] = value
	GameState.apply_ruleset_to_all(get_tree())

#START ROUND
func _on_start_round_pressed() -> void:
	paused = false
	round_active = true
	$"Canvas Layer/DeckParent".visible = false
	var r = GameState.ruleset
	if r.round_timer_enabled:
		round_time_remaining = r.round_time
		$"Canvas Layer/RoundTimerLabel".visible = true
		$"Canvas Layer/RoundTimerLabel".text = str(int(round_time_remaining))
	else:
		$"Canvas Layer/RoundTimerLabel".visible = false
	var players = get_tree().get_nodes_in_group('Player')
	for player in players:
		player.damageable = true
		if r.one_hit_mode:
			player.max_health = 1
			player.current_health = 1
			player.healthbar.max_value = 1
			player.healthbar.value = 1

#END ROUND WHEN THERE'S NO PLAYER LEFT OF A TEAM
func end_round(delta:float):
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
	if p1_amount == 0 or p2_amount == 0:
		var players = get_tree().get_nodes_in_group('Player')
		for player in players:
			player.queue_free()
		_on_add_self_pressed()
		$"Canvas Layer/DeckParent".visible = true
		for player in get_tree().get_nodes_in_group('Player'):
			player.damageable = false

#PAUSE GAME
func toggle_pause(delta : float):
	if Input.is_action_just_pressed('pause'):
		var players = get_tree().get_nodes_in_group('Player')
		for player in players:
			player.queue_free()
		_on_add_self_pressed()
		$"Canvas Layer/DeckParent".visible = true
		for player in get_tree().get_nodes_in_group('Player'):
			player.damageable = false

#ADD PLAYER
func _on_add_self_pressed() -> void:
	var newPlayer1 = player1Prefab.instantiate()
	newPlayer1.position = $SpawnPoints/P1spawn.position
	add_child(newPlayer1)
	GameState.apply_ruleset_to_player(newPlayer1)

	var newPlayer2 = player2Prefab.instantiate()
	newPlayer2.position = $SpawnPoints/P2spawn.position
	add_child(newPlayer2)
	GameState.apply_ruleset_to_player(newPlayer2)

#CHANGE SPEED
func _on_h_slider_value_changed(value: float) -> void:
	_update_rule("speed", int(value))

#REMOVE PLAYER
func _on_remove_player_pressed() -> void:
	var player1s = get_tree().get_nodes_in_group('Player1')
	var player2s = get_tree().get_nodes_in_group('Player2')
	if len(player1s) > 1:
		player1s[-1].queue_free()
		player2s[-1].queue_free()

#RESET RULES
func _on_reset_rules_pressed() -> void:
	GameState.reset_ruleset()
	var current_scene_path = get_tree().current_scene.scene_file_path
	get_tree().change_scene_to_file(current_scene_path)

#INCREASE BULLET SIZE
func _on_increase_bullet_size_pressed() -> void:
	_update_rule("bullet_size", GameState.ruleset.bullet_size + 0.2)

#DECREASE BULLET SIZE
func _on_decrease_bullet_size_pressed() -> void:
	_update_rule("bullet_size", GameState.ruleset.bullet_size - 0.2)

#CHANGE BULLET FORCE
func _on_bullet_force_slider_value_changed(value: float) -> void:
	_update_rule("shoot_speed", value)

#DECREASE JUMP FORCE
func _on_decrease_jump_force_pressed() -> void:
	_update_rule("jump_force", GameState.ruleset.jump_force - 50)

#INCREASE JUMP FORCE
func _on_increase_jump_force_2_pressed() -> void:
	_update_rule("jump_force", GameState.ruleset.jump_force + 50)

#Change Gravity
func _on_gravity_slider_value_changed(value: float) -> void:
	_update_rule("gravity", value)

#DECREASE HORIZONTAL SIZE
func _on_decrease_horizontal_size_pressed() -> void:
	_update_rule("scale_x", GameState.ruleset.scale_x - 0.1)

#INCREASE HORIZONTAL SIZE
func _on_increase_horizontal_size_pressed() -> void:
	_update_rule("scale_x", GameState.ruleset.scale_x + 0.1)

#DECREASE VERTICAL
func _on_decrease_vertical_size_pressed() -> void:
	_update_rule("scale_y", GameState.ruleset.scale_y - 0.1)

#INCREASE VERTICAL
func _on_increase_vertical_size_pressed() -> void:
	_update_rule("scale_y", GameState.ruleset.scale_y + 0.1)

#Listen for Input
func _input(event: InputEvent):
	if waiting_for_key and event is InputEventKey and event.pressed:
		bind_key_to_action(event.keycode)

#Bind the next pressed key to an input map action
func bind_key_to_action(keycode: int):
	waiting_for_key = false
	var events = InputMap.action_get_events(target_input_action)
	for event in events:
		InputMap.action_erase_event(target_input_action, event)
	var key_event = InputEventKey.new()
	key_event.keycode = keycode
	InputMap.action_add_event(target_input_action, key_event)
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
	target_input_action = 'block_1'
	waiting_for_key = true

func _on_p_1_dash_pressed() -> void:
	target_input_action = 'dash_0'
	waiting_for_key = true

func _on_p_2_dash_pressed() -> void:
	target_input_action = 'dash_1'
	waiting_for_key = true

func _on_bullet_timer_slider_value_changed(value: float) -> void:
	_update_rule("shoot_cooldown", value / 100.0)

func _on_map_minus_pressed() -> void:
	var r = GameState.ruleset
	r.map -= 1
	for child in $Maps.get_children():
		child.queue_free()
	var new_map_id = r.map % mapArray.size()
	var new_map = mapArray[new_map_id].instantiate()
	$Maps.add_child(new_map)

func _on_map_plus_pressed() -> void:
	var r = GameState.ruleset
	r.map += 1
	for child in $Maps.get_children():
		child.queue_free()
	var new_map_id = r.map % mapArray.size()
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
	var new_val = max(0, GameState.ruleset.jump_amount - 1)
	_update_rule("jump_amount", new_val)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/LevelPhysics/JumpAmount/Label'.text = 'Jump Amount: %s' % str(new_val)

func _on_jump_q_plus_pressed() -> void:
	var new_val = GameState.ruleset.jump_amount + 1
	_update_rule("jump_amount", new_val)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/LevelPhysics/JumpAmount/Label'.text = 'Jump Amount: %s' % str(new_val)

func _on_block_duration_slider_value_changed(value: float) -> void:
	_update_rule("block_duration", value / 10.0)
	$"Canvas Layer/DeckParent/Rule Panel/GridContainer/LevelPhysics/BlockDurationLabel".text = 'Block Duration: %s' % str(value / 10.0)

func _on_block_cool_down_slider_value_changed(value: float) -> void:
	_update_rule("block_cooldown", value / 10.0)
	$"Canvas Layer/DeckParent/Rule Panel/GridContainer/LevelPhysics/BlockCoolDownLabel".text = 'Block Cooldown: %s' % str(value / 10.0)

#Dash Variables
func _on_d_speed_slider_value_changed(value: float) -> void:
	_update_rule("dash_speed", int(value * 1000))
	$"Canvas Layer/DeckParent/Rule Panel/GridContainer/DashVars/DashSpeed".text = 'Dash Speed: %s' % str(value)

func _on_d_duration_slider_value_changed(value: float) -> void:
	_update_rule("dash_duration", value / 50.0)
	$"Canvas Layer/DeckParent/Rule Panel/GridContainer/DashVars/DashDuration".text = 'Dash Duration: %s' % str(value / 50.0)

func _on_d_cooldown_slider_value_changed(value: float) -> void:
	_update_rule("dash_cooldown", value / 50.0)
	$"Canvas Layer/DeckParent/Rule Panel/GridContainer/DashVars/DashCooldown".text = 'Dash Cooldown: %s' % str(value / 50.0)

func _on_bullet_bounce_minus_pressed() -> void:
	var new_val = max(0, GameState.ruleset.bullet_bounces - 1)
	_update_rule("bullet_bounces", new_val)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/BulletRules/BulletBounce/BulletBounceLabel'.text = 'Bounces: %s' % str(new_val)

func _on_bullet_bounce_plus_pressed() -> void:
	var new_val = GameState.ruleset.bullet_bounces + 1
	_update_rule("bullet_bounces", new_val)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/BulletRules/BulletBounce/BulletBounceLabel'.text = 'Bounces: %s' % str(new_val)

func _on_knockback_slider_value_changed(value: float) -> void:
	_update_rule("knockback_force", value)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/BulletRules/KnockbackLabel'.text = 'Knockback: %s' % str(int(value))

func _on_one_hit_toggled(toggled_on: bool) -> void:
	_update_rule("one_hit_mode", toggled_on)

func _on_bullet_count_minus_pressed() -> void:
	var new_val = max(1, GameState.ruleset.bullet_count - 1)
	_update_rule("bullet_count", new_val)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/BulletRules/BulletCount/BulletCountLabel'.text = 'Bullets: %s' % str(new_val)

func _on_bullet_count_plus_pressed() -> void:
	var new_val = GameState.ruleset.bullet_count + 1
	_update_rule("bullet_count", new_val)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/BulletRules/BulletCount/BulletCountLabel'.text = 'Bullets: %s' % str(new_val)

func _on_friction_slider_value_changed(value: float) -> void:
	var fric = value / 100.0
	_update_rule("friction", fric)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/LevelPhysics/FrictionLabel'.text = 'Friction: %s' % str(snapped(fric, 0.01))

func _on_reflect_on_block_toggled(toggled_on: bool) -> void:
	_update_rule("reflect_on_block", toggled_on)

func _on_round_timer_toggled(toggled_on: bool) -> void:
	_update_rule("round_timer_enabled", toggled_on)

func _on_round_time_slider_value_changed(value: float) -> void:
	_update_rule("round_time", value)
	$'Canvas Layer/DeckParent/Rule Panel/GridContainer/BasicRules/RoundTimeLabel'.text = 'Round Time: %ss' % str(int(value))

func update_round_timer(delta: float) -> void:
	if not round_active or not GameState.ruleset.round_timer_enabled:
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
	var r = GameState.ruleset
	r.speed = randi_range(5000, 50000)
	r.gravity = randi_range(200, 5000)
	r.jump_force = randi_range(100, 800)
	r.jump_amount = randi_range(1, 5)
	r.shoot_speed = randi_range(100, 8000)
	r.bullet_size = randf_range(0.2, 3.0)
	r.bullet_count = randi_range(1, 7)
	r.bullet_bounces = randi_range(0, 5)
	r.knockback_force = randf_range(0, 2000)
	r.friction = randf_range(0.0, 1.0)
	r.dash_speed = randi_range(10000, 200000)
	r.dash_duration = randf_range(0.05, 0.5)
	r.shoot_cooldown = randf_range(0.0, 2.0)
	r.reflect_on_block = randi_range(0, 1) == 1
	r.one_hit_mode = randi_range(0, 4) == 0

	GameState.apply_ruleset_to_all(get_tree())
	sync_ui_to_ruleset()

func _set_status(msg: String) -> void:
	var label = $'Canvas Layer/DeckParent/Rule Panel/GridContainer/BasicRules/PresetStatus'
	label.text = msg
	get_tree().create_timer(3.0).timeout.connect(func(): label.text = "")

func _on_save_preset_pressed() -> void:
	var house_rules_panel = $"Canvas Layer/DeckParent/PanelContainer/INTERNAL RULES"
	if house_rules_panel.has_method("_sync_to_gamestate"):
		house_rules_panel._sync_to_gamestate()
	DirAccess.make_dir_recursive_absolute("user://presets")
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
	var path = "user://presets/preset_%s.json" % timestamp
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(GameState.ruleset_to_json())
		file.close()
		_set_status("Saved: " + path.get_file())
	else:
		_set_status("Save failed!")

func _on_load_preset_pressed() -> void:
	var dir = DirAccess.open("user://presets")
	if not dir:
		_set_status("No presets found")
		return
	var files: Array[String] = []
	dir.list_dir_begin()
	var fname = dir.get_next()
	while fname != "":
		if fname.ends_with(".json"):
			files.append(fname)
		fname = dir.get_next()
	if files.is_empty():
		_set_status("No presets found")
		return
	files.sort()
	var latest = files[-1]
	var file = FileAccess.open("user://presets/" + latest, FileAccess.READ)
	if file:
		var json_str = file.get_as_text()
		file.close()
		if GameState.ruleset_from_json(json_str):
			GameState.apply_ruleset_to_all(get_tree())
			sync_ui_to_ruleset()
			_reload_house_rules()
			_set_status("Loaded: " + latest)
		else:
			_set_status("Invalid preset file")
	else:
		_set_status("Could not read file")

func _on_copy_code_pressed() -> void:
	var house_rules_panel = $"Canvas Layer/DeckParent/PanelContainer/INTERNAL RULES"
	if house_rules_panel.has_method("_sync_to_gamestate"):
		house_rules_panel._sync_to_gamestate()
	var json_str = GameState.ruleset_to_json()
	var code = Marshalls.utf8_to_base64(json_str)
	DisplayServer.clipboard_set(code)
	_set_status("Code copied to clipboard!")

func _on_paste_code_pressed() -> void:
	var code = DisplayServer.clipboard_get()
	if code.is_empty():
		_set_status("Clipboard is empty")
		return
	var json_str = Marshalls.base64_to_utf8(code)
	if json_str.is_empty():
		_set_status("Invalid code")
		return
	if GameState.ruleset_from_json(json_str):
		GameState.apply_ruleset_to_all(get_tree())
		sync_ui_to_ruleset()
		_reload_house_rules()
		_set_status("Ruleset imported!")
	else:
		_set_status("Invalid code")

func _reload_house_rules() -> void:
	var panel = $"Canvas Layer/DeckParent/PanelContainer/INTERNAL RULES"
	var container = panel.get_node("RuleScroll/RuleList")
	for child in container.get_children():
		child.queue_free()
	for rule_text in GameState.ruleset.house_rules:
		panel._add_rule_block(rule_text)
