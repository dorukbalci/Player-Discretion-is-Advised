extends VBoxContainer

var default_rules := [
	"Try to Win.",
	"First to reach 9 points wins.",
	"Player who loses the round can change any rules.",
	"Keep eyes open.",
]

@onready var rule_container: VBoxContainer = $RuleScroll/RuleList
@onready var add_input: LineEdit = $AddRow/RuleInput

func _ready() -> void:
	for rule_text in default_rules:
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
	delete_btn.pressed.connect(row.queue_free)
	row.add_child(delete_btn)

	rule_container.add_child(row)

func _on_add_button_pressed() -> void:
	var text := add_input.text.strip_edges()
	if text.is_empty():
		return
	_add_rule_block(text)
	add_input.text = ""
