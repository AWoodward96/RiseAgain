extends Control
class_name ContextMenu

signal OnAnyActionSelected()

@export var entryParent : Control
@export var entryPrefab : PackedScene


func Initialize():
	SelectFirst()

func Clear():
	for n in entryParent.get_children():
		entryParent.remove_child(n)
		n.queue_free()

func SelectFirst():
	entryParent.get_child(0).grab_focus()

func AddButton(_text : String, _callback : Callable):
	var entry = entryPrefab.instantiate() as ContextButtonEntry
	if entry != null :
		entryParent.add_child(entry)
		entry.Initialize(_text, _callback)
		entry.pressed.connect(AnyButtonPressed)

func AnyButtonPressed():
	OnAnyActionSelected.emit()
