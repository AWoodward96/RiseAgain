extends Control
class_name ContextMenu

signal OnAnyActionSelected()

@export var entryParent : Control
@export var entryPrefab : PackedScene

@export_category("SFX")
@export var OnShowSound : FmodEventEmitter2D


func Initialize():
	SelectFirst()
	if OnShowSound != null:
		OnShowSound.play()

func Clear():
	for n in entryParent.get_children():
		entryParent.remove_child(n)
		n.queue_free()

func SelectFirst():
	entryParent.get_child(0).grab_focus()

func LoopButtons():
	var firstEntry = entryParent.get_child(0) as ContextButtonEntry
	var lastEntry = entryParent.get_child(entryParent.get_child_count() - 1) as ContextButtonEntry
	firstEntry.focus_neighbor_top = lastEntry.get_path()
	lastEntry.focus_neighbor_bottom = firstEntry.get_path()


func SelectIndex(_index : int):
	var obj = entryParent.get_child(_index)
	if obj != null:
		obj.grab_focus()

func AddButton(_text : String, _enabled : bool, _callback : Callable):
	var entry = entryPrefab.instantiate() as ContextButtonEntry
	if entry != null :
		entryParent.add_child(entry)
		entry.Initialize(_text, _enabled, _callback)
		entry.OnSelectedCallback.connect(AnyButtonPressed)

	return entry

func AddAbilityButton(_ability : Ability, _enabled : bool, _callback : Callable):
	var btn = AddButton(_ability.loc_displayName, _enabled, _callback)
	btn.AddAbility(_ability)
	return btn

func AnyButtonPressed():
	OnAnyActionSelected.emit()
