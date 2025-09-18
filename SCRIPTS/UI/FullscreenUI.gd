extends Control
class_name FullscreenUI


@export var Priority = 1
@export var TrackOnStack = true

var BlockedFocusables : Array[Control]
var BlockedFocusablesState : Array[FocusMode]
var IsInDetailState : bool = false
var LastFocusedElement : Control


func _enter_tree() -> void:
	UIManager.UIOpened.emit(self)

func _exit_tree() -> void:
	UIManager.UIClosed.emit(self)

func _ready():
	if get_parent() == get_tree().root:
		call_deferred("OpenDeferred")


func OpenDeferred():
	UIManager.OnUIOpened(self)

func ReturnFocus():
	pass

func StartShowDetails():
	if !IsInDetailState:
		IsInDetailState = true

		LastFocusedElement = UIManager.CurrentInspectedElement

		var allControls = GetControlChildrenRecursive(self)
		BlockedFocusables.clear()
		BlockedFocusablesState.clear()
		for ctrl : Control in allControls:
			BlockedFocusables.append(ctrl)
			BlockedFocusablesState.append(ctrl.focus_mode)
			ctrl.focus_mode = Control.FOCUS_NONE
	pass

func GetControlChildrenRecursive(_node : Control):
	var nodes : Array[Control]
	for n in _node.get_children():
		if n is DetailEntry:
			continue

		if n is not Control:
			continue

		if n.get_child_count() > 0:
			nodes.append(n)
			nodes.append_array(GetControlChildrenRecursive(n))
		else:
			nodes.append(n)
	return nodes

func EndShowDetails():
	if IsInDetailState:
		IsInDetailState = false
		for i in range(0, BlockedFocusables.size()):
			BlockedFocusables[i].focus_mode = BlockedFocusablesState[i]

		LastFocusedElement.grab_focus()
		InputManager.ReleaseCancel()
	pass
