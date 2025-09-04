extends Control
class_name FullscreenUI

@export var Priority = 1

func _enter_tree() -> void:
	UIManager.UIOpened.emit(self)

func _process(_delta: float) -> void:
	if !visible:
		return

	if get_viewport().gui_get_focus_owner() == null:
		ReturnFocus()

func _exit_tree() -> void:
	UIManager.UIClosed.emit(self)

func ReturnFocus():
	pass
