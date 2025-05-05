extends Control
class_name InspectableElement

signal EntrySelected

@export var SelectedParent : Control
@export var FocusSound : FmodEventEmitter2D
@export var SelectedSound : FmodEventEmitter2D

func _ready():
	gui_input.connect(OnGUI)
	focus_entered.connect(OnFocusEntered)
	focus_exited.connect(OnFocusExited)

func OnGUI(_event : InputEvent):
	if _event.is_action_pressed("select"):
		if SelectedSound != null:
			SelectedSound.play()
		EntrySelected.emit()

func OnFocusEntered():
	if SelectedParent != null:
		SelectedParent.visible = true
	
	if FocusSound != null:
		FocusSound.play()

func OnFocusExited():
	if SelectedParent != null:
		SelectedParent.visible = false
