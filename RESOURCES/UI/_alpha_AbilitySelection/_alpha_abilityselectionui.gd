extends CanvasLayer
class_name SelectAbilityUI

signal SelectionComplete(_packedScene : PackedScene)

@export var entryParent : EntryList
@export var abilityEntryPrefab : PackedScene


func Initialize(_abilities : Array[PackedScene]):
	entryParent.ClearEntries()
	for a in _abilities:
		var entry = entryParent.CreateEntry(abilityEntryPrefab)
		entry.Initialize(a)
		entry.EntrySelected.connect(OnAbilitySelected.bind(a))

	entryParent.FocusFirst()

func OnAbilitySelected(_ability : PackedScene):
	entryParent.ClearEntries()
	queue_free()
	SelectionComplete.emit(_ability)

static func Show(_root : Node2D, _abilities : Array[PackedScene]):
	var ui = UIManager.AbilitySelectionUI.instantiate() as SelectAbilityUI
	_root.add_child(ui)
	ui.Initialize(_abilities)
	return ui
