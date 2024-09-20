extends CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

const gravity = 1000
const speed = 300
const jumpForce = 300

enum playerState {Idle, Run, Jump}
var current_state

func _ready() -> void:
	current_state = playerState.Idle
	
func _physics_process(delta: float) -> void:
	player_falling(delta)
	player_idle(delta)
	player_run(delta)
	player_jump(delta)
	
	move_and_slide()
	
	player_animations()

func player_falling(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

func player_idle(delta):
	if is_on_floor():
		current_state = playerState.Idle

func player_run(delta):
	var direction = Input.get_axis('move_left','move_right')
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	
	if direction != 0:
		current_state = playerState.Run
		animated_sprite_2d.flip_h = false if direction > 0 else true
		
func player_jump(delta):
	if Input.is_action_just_pressed('jump'):
		velocity.y = -jumpForce
		current_state = playerState.Jump
	if !is_on_floor() and current_state== playerState.Jump:
		var direction = Input.get_axis('move_left','move_right')
		velocity.x += direction * speed/3 * delta
	
		
func player_animations():
	if current_state == playerState.Idle and is_on_floor():
		animated_sprite_2d.play('idle')
	elif current_state == playerState.Run and is_on_floor():
		animated_sprite_2d.play('run')
	elif current_state == playerState.Jump or !is_on_floor():
		animated_sprite_2d.play('jump')
