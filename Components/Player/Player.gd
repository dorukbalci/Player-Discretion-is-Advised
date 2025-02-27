extends CharacterBody2D
#Set Player
@export var playerID = 0;
var paused := false

@export var bullet = preload("res://Components/Player/Bullet/bullet.tscn")
@export var bullet_size = 1.0
@onready var muzzle : Marker2D = $Muzzle
var muzzle_position



#Physical Bullet
@export var p_bullet_scene: PackedScene  
@export var shoot_speed: float = 500.0
@onready var bulletTimer := $BulletTimer
@export var shoot_cooldown := 0.5
var can_shoot := true

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

#Probably should be a universal variable
@export var gravity := 1000

@export var speed : int = 400
@export var max_hspeed := 300
@export var slowdown_speed := 1000

@export var jumpForce : int = 300
@export var jump_hspeed := 1000

var damageable = false
@export var max_health:=100
@export var min_health:=0
var current_health = 100
@onready var healthbar = $HealthBar

enum playerState {Idle, Run, Jump, Shoot}
var current_state : playerState
var character_sprite : Sprite2D

signal dying

#blocking variables
@export var block_duration := 1.0
@export var block_cooldown := 1.0
var is_blocking = false
var can_block = true

#double jump vars
@export var jump_amount := 1
var current_jump := 0

#dash variables
# Dash variables
@export var dash_speed: int = 50000  # Speed boost during dash
@export var dash_duration: float = 0.2  # Dash duration (seconds)
@export var dash_cooldown: float = 0.5  # Cooldown before dashing again

var is_dashing := false
var can_dash := true
var dash_direction := 0

@onready var dash_timer := $Timers/DashTimer
@onready var dash_cooldown_timer := $Timers/DashCooldown



func _ready() -> void:
	current_state = playerState.Idle
	muzzle_position = muzzle.position
	bulletTimer.wait_time = shoot_cooldown
	dash_timer.wait_time = dash_duration
	dash_cooldown_timer.wait_time = dash_cooldown
	
	
func _physics_process(delta: float) -> void:
	if not paused:
		handle_dash()
		player_falling(delta)
		player_idle(delta)
		player_run(delta)
		player_jump(delta)
		block(delta)
		swap_muzzle_position()
		#player_shoot(delta)
		p_shoot(delta)
		player_animations()
		die(delta)
		if is_dashing:
			velocity.x = dash_direction * dash_speed * delta
			print(dash_direction)
		move_and_slide()

func handle_dash():
	if Input.is_action_just_pressed("dash_%s" % playerID) and can_dash:
		is_dashing = true
		can_dash = false
		dash_direction = input_movement()

		# If no movement input, dash in the direction player is facing
		if dash_direction == 0:
			dash_direction = -1 if animated_sprite_2d.flip_h else 1

		dash_timer.start()

func _on_dash_timer_timeout() -> void:
	is_dashing = false  # End dash effect
	dash_cooldown_timer.start()  # Start cooldown

func _on_dash_cooldown_timeout() -> void:
	can_dash = true  # Allow dashing again

func player_falling(delta: float):
	if not is_on_floor():
		velocity.y += gravity * delta

func player_idle(delta: float):
	if is_on_floor():
		current_state = playerState.Idle

func player_run(delta: float):
	if !is_blocking:
		var direction = input_movement()
		if direction:
			velocity.x = direction * speed * delta
		else:
			velocity.x = 0
		if direction != 0:
			current_state = playerState.Run
			animated_sprite_2d.flip_h = false if direction > 0 else true
		
func player_jump(delta: float):
	if is_on_floor():
		current_jump = 0
	if !is_blocking :
		if Input.is_action_just_pressed('jump_%s' % playerID):
			if is_on_floor():
				velocity.y = -jumpForce
				current_state = playerState.Jump
				current_jump += 1
			elif current_jump > 0 && current_jump < jump_amount:
				velocity.y = -jumpForce
				current_state = playerState.Jump
				current_jump += 1
		if !is_on_floor() and current_state== playerState.Jump:
			var direction = input_movement()
			#velocity.x += direction * jump_hspeed * delta
			#velocity.x = clamp(velocity.x, -max_hspeed,max_hspeed)
			velocity.x += direction * speed * delta
			#velocity.x = clamp(velocity.x, -max_hspeed,max_hspeed)
		

#func player_shoot(delta: float):
	#
	#var direction = input_movement()
	#
	#if direction != 0 and Input.is_action_just_pressed('shoot_%s' % playerID):
		#
		#var bullet_instance = bullet.instantiate() as Node2D
		#bullet_instance.direction = direction
		#
		#bullet_instance.scale = bullet_size
		#
		#bullet_instance.global_position = muzzle.global_position
		#get_parent().add_child(bullet_instance)
		#current_state = playerState.Shoot

func p_shoot(delta: float):
	if Input.is_action_just_pressed('shoot_%s' % playerID) and can_shoot:
		bulletTimer.wait_time = shoot_cooldown
		var direction = input_movement()
		var bullet = p_bullet_scene.instantiate() as RigidBody2D
		bullet.gravity_scale = gravity / 1000
		bullet.add_to_group('Bullet_%s' % playerID)
		bullet.position = $Muzzle.global_position
		for child in bullet.get_children():
			child.scale = Vector2.ONE * bullet_size
		bullet.linear_velocity = Vector2(1,0)* sign(muzzle.position.x) * shoot_speed
		get_tree().current_scene.add_child(bullet)
		can_shoot = false
		bulletTimer.start()

func swap_muzzle_position():
	var direction = input_movement()
	if direction > 0:
		muzzle.position.x = muzzle_position.x
	elif direction < 0:
		muzzle.position.x = -muzzle_position.x

func player_animations():
	if current_state == playerState.Idle and is_on_floor():
		animated_sprite_2d.play('idle')
	elif current_state == playerState.Run and animated_sprite_2d.animation != 'run_shoot' and is_on_floor():
		animated_sprite_2d.play('run')
	elif current_state == playerState.Jump or !is_on_floor():
		animated_sprite_2d.play('jump')
	elif current_state == playerState.Shoot :
		animated_sprite_2d.play('run_shoot')

func input_movement():
	var direction : float = Input.get_axis('move_left_%s'% playerID,'move_right_%s' % playerID)
	return direction

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.is_in_group('Bullet') && !body.is_in_group('Bullet_%s'%playerID):
		body.queue_free()
		if !is_blocking:
			update_health(-20)
			print('Bullet Entered')

func update_health(change : int):
	if damageable:
		current_health += change
		healthbar.value = current_health

func block(delta:float):
	if Input.is_action_just_pressed('block_%s' % playerID):
		$Timers/BlockTimer.start(block_duration)
	if Input.is_action_just_released('block_%s' % playerID):
		$Timers/BlockTimer.stop()
	if Input.is_action_pressed('block_%s' % playerID) and can_block:
		block_duration -= delta
		is_blocking = true
		$Block.visible = true
	else:
		is_blocking = false
		$Block.visible = false

func die(delta:float):
	dying.emit()
	if current_health <= 0:
		queue_free()

func _on_bullet_timer_timeout() -> void:
	can_shoot = true


func _on_block_timer_timeout() -> void:
	can_block = false
	$Timers/BlockCooldown.start(block_duration)


func _on_block_cooldown_timeout() -> void:
	can_block=true
