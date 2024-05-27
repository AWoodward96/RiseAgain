extends Control
class_name ContextMenu

signal OnDefend()
signal OnAttack()
signal OnWait()
signal OnAnyActionSelected()

@export var entryParent : Control


func Initialize():
	entryParent.get_child(0).grab_focus()

func OnWaitButton():
	OnWait.emit()
	OnAnyActionSelected.emit()
	pass

func OnAttackButton():
	OnAttack.emit()
	OnAnyActionSelected.emit()
	pass

func OnDefendButton():
	OnDefend.emit()
	OnAnyActionSelected.emit()
	pass

