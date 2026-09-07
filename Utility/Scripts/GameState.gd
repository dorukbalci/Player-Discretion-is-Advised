extends Node

var p1score = 0
var p2score = 0

const DEFAULT_RULESET := {
	"speed": 20000,
	"gravity": 1000,
	"jump_force": 600,
	"jump_amount": 1,
	"shoot_speed": 500.0,
	"shoot_cooldown": 0.5,
	"bullet_size": 1.0,
	"bullet_count": 1,
	"bullet_bounces": 0,
	"knockback_force": 0.0,
	"friction": 1.0,
	"reflect_on_block": false,
	"one_hit_mode": false,
	"block_duration": 1.0,
	"block_cooldown": 1.0,
	"dash_speed": 50000,
	"dash_duration": 0.2,
	"dash_cooldown": 0.5,
	"scale_x": 1.7,
	"scale_y": 1.7,
	"map": 0,
	"round_timer_enabled": false,
	"round_time": 30.0,
	"house_rules": [
		"Try to Win.",
		"First to reach 9 points wins.",
		"Player who loses the round can change any rules.",
		"Keep eyes open.",
	],
}

var ruleset := {}

func _ready() -> void:
	reset_ruleset()

func reset_ruleset() -> void:
	ruleset = DEFAULT_RULESET.duplicate(true)

func apply_ruleset_to_player(player) -> void:
	player.speed = ruleset.speed
	player.max_hspeed = ruleset.speed
	player.gravity = ruleset.gravity
	player.jumpForce = ruleset.jump_force
	player.jump_amount = ruleset.jump_amount
	player.shoot_speed = ruleset.shoot_speed
	player.shoot_cooldown = ruleset.shoot_cooldown
	player.bullet_size = ruleset.bullet_size
	player.bullet_count = ruleset.bullet_count
	player.bullet_bounces = ruleset.bullet_bounces
	player.knockback_force = ruleset.knockback_force
	player.friction = ruleset.friction
	player.reflect_on_block = ruleset.reflect_on_block
	player.block_duration = ruleset.block_duration
	player.block_cooldown = ruleset.block_cooldown
	player.dash_speed = ruleset.dash_speed
	player.dash_duration = ruleset.dash_duration
	player.dash_cooldown = ruleset.dash_cooldown
	player.scale = Vector2(ruleset.scale_x, ruleset.scale_y)

func apply_ruleset_to_all(tree: SceneTree) -> void:
	for player in tree.get_nodes_in_group('Player'):
		apply_ruleset_to_player(player)

func ruleset_to_json() -> String:
	return JSON.stringify(ruleset, "\t")

func ruleset_from_json(json_string: String) -> bool:
	var json := JSON.new()
	var err := json.parse(json_string)
	if err != OK:
		return false
	var data = json.data
	if data is Dictionary:
		for key in data:
			ruleset[key] = data[key]
		return true
	return false
