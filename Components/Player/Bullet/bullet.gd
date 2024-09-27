extends AnimatedSprite2D

@export var speed := 600
var direction : int

func _physics_process(delta: float) -> void:
	move_local_x(direction * speed * delta)


func _on_timer_timeout() -> void:
	queue_free()


func _on_hitbox_area_entered(area: Area2D) -> void:
	print('bullet area entered')
	


func _on_hitbox_body_entered(body: Node2D) -> void:
	print('bullet body entered')
