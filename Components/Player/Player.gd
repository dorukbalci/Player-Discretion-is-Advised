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
@export var bullet_count := 1
@export var bullet_bounces := 0
@export var knockback_force := 0.0
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

#Probably should be a universal variable
@export var gravity := 1000

@export var speed : int = 400
@export var max_hspeed := 300
@export var slowdown_speed := 1000
@export var friction := 1.0
@export var reflect_on_block := false

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
var block_remaining := 0.0
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
var dash_trail_timer := 0.0
const DASH_TRAIL_INTERVAL := 0.03

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
			dash_trail_timer += delta
			if dash_trail_timer >= DASH_TRAIL_INTERVAL:
				dash_trail_timer = 0.0
				spawn_ghost()
		move_and_slide()

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
			velocity.x = move_toward(velocity.x, 0, friction * speed * delta)
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
		var dir_sign = sign(muzzle.position.x)
		var spread_angle := deg_to_rad(10.0)
		for i in bullet_count:
			var b = p_bullet_scene.instantiate() as RigidBody2D
			b.gravity_scale = gravity / 1000
			b.max_bounces = bullet_bounces
			b.knockback_force = knockback_force
			b.add_to_group('Bullet_%s' % playerID)
			b.position = $Muzzle.global_position
			for child in b.get_children():
				child.scale = Vector2.ONE * bullet_size
			var angle_offset := 0.0
			if bullet_count > 1:
				angle_offset = lerp(-spread_angle, spread_angle, float(i) / (bullet_count - 1))
			var base_dir := Vector2(dir_sign, 0)
			b.linear_velocity = base_dir.rotated(angle_offset) * shoot_speed
			get_tree().current_scene.add_child(b)
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
		if is_blocking:
			if reflect_on_block:
				body.linear_velocity = -body.linear_velocity * 1.2
				body.bounce_count = 0
				for g in body.get_groups():
					if g.begins_with('Bullet_'):
						body.remove_from_group(g)
				body.add_to_group('Bullet_%s' % playerID)
			else:
				body.queue_free()
		else:
			if knockback_force > 0.0:
				var dir = (global_position - body.global_position).normalized()
				velocity += dir * knockback_force
			update_health(-20)
			body.queue_free()

func update_health(change : int):
	if damageable:
		current_health += change
		healthbar.value = current_health

func block(delta:float):
	if Input.is_action_just_pressed('block_%s' % playerID) and can_block:
		block_remaining = block_duration
		is_blocking = true
	if is_blocking:
		if Input.is_action_pressed('block_%s' % playerID) and block_remaining > 0:
			block_remaining -= delta
			$Block.visible = true
			$Block.offset = Vector2(randf_range(-3, 3), randf_range(-3, 3))
			$Block.modulate.a = randf_range(0.25, 0.55)
			$Block.scale = Vector2.ONE * 0.2 * randf_range(0.95, 1.05)
		else:
			is_blocking = false
			$Block.visible = false
			$Block.offset = Vector2.ZERO
			can_block = false
			$Timers/BlockCooldown.start(block_cooldown)

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

func handle_dash():
	if Input.is_action_just_pressed("dash_%s" % playerID) and can_dash:
		dash_timer.wait_time = dash_duration
		dash_cooldown_timer.wait_time = dash_cooldown
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
	can_dash = true

func spawn_ghost() -> void:
	var ghost := Sprite2D.new()
	ghost.texture = animated_sprite_2d.sprite_frames.get_frame_texture(animated_sprite_2d.animation, animated_sprite_2d.frame)
	ghost.global_position = animated_sprite_2d.global_position
	ghost.scale = scale
	ghost.flip_h = animated_sprite_2d.flip_h
	ghost.modulate = Color(1, 1, 1, 0.4)
	ghost.z_index = z_index - 1
	get_tree().current_scene.add_child(ghost)
	var tween := get_tree().create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.3)
	tween.tween_callback(ghost.queue_free)
