extends Node2D

@export var scenes: Array[PackedScene] 
@onready var sceneParent = $SceneParent

var current_scene := 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var new_scene = scenes[0].instantiate()
	$SceneParent.add_child(new_scene)
func _process(delta: float) -> void:
	pass
	
func change_scene(scene_id: int):
	for node in $SceneParent.get_children():
		node.queue_free()
	var new_scene = scenes[scene_id].instantiate()
	$SceneParent.add_child(new_scene)
	


func _on_next_level_body_entered(body: Node2D) -> void:
	if body.is_in_group('Player'):
		print('entered')
		current_scene +=1
		change_scene(current_scene)


func _on_previous_level_body_entered(body: Node2D) -> void:
	if body.is_in_group('Player'):
		print('entered')
		if current_scene > 0:
			current_scene -=1
			change_scene(current_scene)
