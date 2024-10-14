extends RigidBody2D

@export var speed: float = 500.0
@export var life_time: float = 2.0  # Time in seconds

var time_alive: float = 0.0
var bullet_rotation

func _ready():
	# Apply velocity in the direction the bullet is facing
	#linear_velocity = Vector2(cos(rotation), sin(rotation)) * speed
	pass

func _physics_process(delta: float):
	# Track bullet lifetime and destroy it when time exceeds life_time
	time_alive += delta
	if time_alive > life_time:
		queue_free()

func _on_body_entered(body):
	# Handle collision (destroy bullet on impact)
	queue_free()
