extends ScrollContainer


func _ready():
	# Call the function to disable keyboard input for all children
	disable_keyboard_input_for_children(self)

# Function to recursively disable keyboard input for all child nodes
func disable_keyboard_input_for_children(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			child.focus_mode = Control.FocusMode.FOCUS_CLICK  # Disable keyboard input
		# Recursively call the function for each child node
		disable_keyboard_input_for_children(child)
