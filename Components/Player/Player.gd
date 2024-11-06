extends CharacterBody2D
#Set Player
@export var playerID = 0;

@export var bullet = preload("res://Components/Player/Bullet/bullet.tscn")
@onready var muzzle : Marker2D = $Muzzle
var muzzle_position

#Physical Bullet
@export var p_bullet_scene: PackedScene  
@export var shoot_speed: float = 500.0

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

#Probably should be a universal variable
@export var gravity := 1000

@export var speed : int = 400
@export var max_hspeed := 300
@export var slowdown_speed := 1000

@export var jumpForce : int = 300
@export var jump_hspeed := 1000

@export var max_health:=100
@export var min_health:=0
var current_health = 100
@onready var healthbar = $HealthBar

enum playerState {Idle, Run, Jump, Shoot}
var current_state : playerState

var character_sprite : Sprite2D

func _ready() -> void:
	current_state = playerState.Idle
	muzzle_position = muzzle.position
	
func _physics_process(delta: float) -> void:
	player_falling(delta)
	player_idle(delta)
	player_run(delta)
	player_jump(delta)
	swap_muzzle_position()
	#player_shoot(delta)
	p_shoot(delta)
	move_and_slide()
	player_animations()
	die(delta)

func player_falling(delta: float):
	if not is_on_floor():
		velocity.y += gravity * delta

func player_idle(delta: float):
	if is_on_floor():
		current_state = playerState.Idle

func player_run(delta: float):
	var direction = input_movement()
	if direction:
		velocity.x += direction * speed * delta
		velocity.x = clamp(velocity.x, -max_hspeed,max_hspeed)
	else:
		#velocity.x = move_toward(velocity.x, 0, slowdown_speed * delta)
		velocity.x = 0
	if direction != 0:
		current_state = playerState.Run
		animated_sprite_2d.flip_h = false if direction > 0 else true
		
func player_jump(delta: float):
	if Input.is_action_just_pressed('jump_%s' % playerID) and is_on_floor():
		velocity.y = -jumpForce
		current_state = playerState.Jump
	if !is_on_floor() and current_state== playerState.Jump:
		var direction = input_movement()
		#velocity.x += direction * jump_hspeed * delta
		#velocity.x = clamp(velocity.x, -max_hspeed,max_hspeed)
		velocity.x += direction * speed * delta
		velocity.x = clamp(velocity.x, -max_hspeed,max_hspeed)

func player_shoot(delta: float):
	
	var direction = input_movement()
	
	if direction != 0 and Input.is_action_just_pressed('shoot_%s' % playerID):
		
		var bullet_instance = bullet.instantiate() as Node2D
		bullet_instance.direction = direction
		
		bullet_instance.global_position = muzzle.global_position
		get_parent().add_child(bullet_instance)
		current_state = playerState.Shoot

func p_shoot(delta: float):
	if Input.is_action_just_pressed('shoot_%s' % playerID):
		var direction = input_movement()
		var bullet = p_bullet_scene.instantiate() as RigidBody2D
		bullet.add_to_group('Bullet_%s' % playerID)
		bullet.position = $Muzzle.global_position
		bullet.linear_velocity = Vector2(1,0)* sign(muzzle.position.x) * 400 
		get_tree().current_scene.add_child(bullet)

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
		update_health(-20)
		print('Bullet Entered')

func update_health(change : int):
	
	current_health += change
	healthbar.value = current_health
	pass

func die(delta:float):
	if current_health <= 0:
		queue_free()
