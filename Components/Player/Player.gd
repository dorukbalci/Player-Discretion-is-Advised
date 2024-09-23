extends CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@export var gravity := 1000

@export var speed : int = 400
@export var max_hspeed := 300
@export var slowdown_speed := 1000

@export var jumpForce : int = 300
@export var jump_hspeed := 1000

enum playerState {Idle, Run, Jump}
var current_state : playerState

var character_sprite : Sprite2D

func _ready() -> void:
	current_state = playerState.Idle
	
func _physics_process(delta: float) -> void:
	player_falling(delta)
	player_idle(delta)
	player_run(delta)
	player_jump(delta)
	
	move_and_slide()
	
	player_animations()

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
		velocity.x = move_toward(velocity.x, 0, slowdown_speed * delta)
	if direction != 0:
		current_state = playerState.Run
		animated_sprite_2d.flip_h = false if direction > 0 else true
		
func player_jump(delta: float):
	if Input.is_action_just_pressed('jump') and is_on_floor():
		velocity.y = -jumpForce
		current_state = playerState.Jump
	if !is_on_floor() and current_state== playerState.Jump:
		var direction = input_movement()
		velocity.x += direction * jump_hspeed * delta
		velocity.x = clamp(velocity.x, -max_hspeed,max_hspeed)
		
func player_animations():
	if current_state == playerState.Idle and is_on_floor():
		animated_sprite_2d.play('idle')
	elif current_state == playerState.Run and is_on_floor():
		animated_sprite_2d.play('run')
	elif current_state == playerState.Jump or !is_on_floor():
		animated_sprite_2d.play('jump')

func input_movement():
	var direction : float = Input.get_axis('move_left','move_right')
	return direction
