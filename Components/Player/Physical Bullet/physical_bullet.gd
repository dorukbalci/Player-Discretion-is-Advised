extends RigidBody2D

@export var speed: float = 500.0
@export var life_time: float = 2.0
@export var damage := 20
@export var max_bounces := 0
@export var knockback_force := 0.0

var time_alive: float = 0.0
var bounce_count := 0

func _ready():
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float):
	time_alive += delta
	if time_alive > life_time:
		queue_free()

func _on_body_entered(body):
	if body is CharacterBody2D:
		return
	bounce_count += 1
	if bounce_count > max_bounces:
		queue_free()
