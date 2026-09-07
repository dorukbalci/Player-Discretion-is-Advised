extends VBoxContainer

@onready var rule_container: VBoxContainer = $RuleScroll/RuleList
@onready var add_input: LineEdit = $AddRow/RuleInput

func _ready() -> void:
	for rule_text in GameState.ruleset.house_rules:
		_add_rule_block(rule_text)

func _add_rule_block(text: String) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label := Label.new()
	label.text = "• " + text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(label)

	var delete_btn := Button.new()
	delete_btn.text = "X"
	delete_btn.pressed.connect(_remove_rule.bind(row))
	row.add_child(delete_btn)

	rule_container.add_child(row)

func _remove_rule(row: HBoxContainer) -> void:
	row.queue_free()
	_sync_to_gamestate.call_deferred()

func _sync_to_gamestate() -> void:
	var rules: Array = []
	for row in rule_container.get_children():
		if row is HBoxContainer:
			var label = row.get_child(0) as Label
			if label:
				rules.append(label.text.substr(2))
	GameState.ruleset.house_rules = rules

func _on_add_button_pressed() -> void:
	var text := add_input.text.strip_edges()
	if text.is_empty():
		return
	_add_rule_block(text)
	add_input.text = ""
	_sync_to_gamestate()

var random_rules := [
	"Loser must play with one hand.",
	"Winner picks the next map.",
	"No blocking allowed this round.",
	"Both players must jump constantly.",
	"Loser gives the winner a compliment.",
	"Play the next round in silence.",
	"Switch seats after this round.",
	"Loser has to close one eye next round.",
	"Winner gets to change two rules instead of one.",
	"Both players must narrate their actions out loud.",
	"No dashing allowed.",
	"Loser plays with inverted controls next round.",
	"If you touch the ground, you lose 10 HP.",
	"Rock-paper-scissors to decide who picks the rules.",
	"Loser must stand up while playing next round.",
	"Winner chooses a handicap for themselves.",
	"No shooting for the first 5 seconds.",
	"Both players must use the same controls.",
	"Trash talk is mandatory.",
	"The next round is played in slow motion (change speed to minimum).",
]

func _on_random_rule_pressed() -> void:
	var rule = random_rules[randi() % random_rules.size()]
	_add_rule_block(rule)
	_sync_to_gamestate()
