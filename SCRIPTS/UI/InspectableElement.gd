extends Control
class_name InspectableElement

signal EntrySelected

@export var SelectedParent : Control

func _ready():
	gui_input.connect(OnGUI)
	focus_entered.connect(OnFocusEntered)
	focus_exited.connect(OnFocusExited)

func OnGUI(_event : InputEvent):
	if _event.is_action_pressed("select"):
		EntrySelected.emit()

func OnFocusEntered():
	if SelectedParent != null:
		SelectedParent.visible = true

func OnFocusExited():
	if SelectedParent != null:
		SelectedParent.visible = false
