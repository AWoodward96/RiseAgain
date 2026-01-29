extends Control
class_name DetailEntry

@export var tooltip : String
@export var showHighlight : bool = true

func _ready():
	DisableFocus()

func EnableFocus():
	focus_mode = Control.FOCUS_ALL

func DisableFocus():
	if has_focus():
		release_focus()
	focus_mode = Control.FOCUS_NONE
