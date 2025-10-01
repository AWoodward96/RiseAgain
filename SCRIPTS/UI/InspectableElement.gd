extends Control
class_name InspectableElement

# TODO: Cleanup - probably delete?
# The focus system already does this and I can design around this

signal EntrySelected

@export var SelectedParent : Control
@export var FocusSound : FmodEventEmitter2D
@export var SelectedSound : FmodEventEmitter2D
@export var SelectDisabledSound :FmodEventEmitter2D
var disabled : bool = false


func _ready():
	gui_input.connect(OnGUI)
	focus_entered.connect(OnFocusEntered)
	focus_exited.connect(OnFocusExited)

func OnGUI(_event : InputEvent):
	if _event.is_action_pressed("select"):
		if !disabled:
			if SelectedSound != null:
				SelectedSound.play()
			EntrySelected.emit()
		else:
			if SelectDisabledSound != null:
				SelectDisabledSound.play()

func SetDisabled(_disabled : bool):
	disabled = _disabled

func OnFocusEntered():
	if SelectedParent != null:
		SelectedParent.visible = true

	if FocusSound != null:
		FocusSound.play()

func OnFocusExited():
	if SelectedParent != null:
		SelectedParent.visible = false
