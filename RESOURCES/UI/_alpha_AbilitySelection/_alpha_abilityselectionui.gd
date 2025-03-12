extends FullscreenUI
class_name SelectAbilityUI

static var Instance : SelectAbilityUI
signal SelectionComplete(_packedScene : PackedScene)

@export var entryParent : EntryList
@export var abilityEntryPrefab : PackedScene


func _ready() -> void:
	if Instance != null:
		queue_free()
		return
	Instance = self

func _exit_tree() -> void:
	super()
	if Instance == self:
		Instance = null

func Initialize(_abilities : Array[String]):
	entryParent.ClearEntries()
	for abilityPath in _abilities:
		var entry = entryParent.CreateEntry(abilityEntryPrefab)
		var packedScene = load(abilityPath)
		if packedScene == null:
			continue
		entry.Initialize(packedScene)
		entry.EntrySelected.connect(OnAbilitySelected.bind(packedScene))

	entryParent.FocusFirst()

func OnAbilitySelected(_ability : PackedScene):
	entryParent.ClearEntries()
	queue_free()
	SelectionComplete.emit(_ability)

static func Show(_root : Node2D, _abilities : Array[String]):
	var ui = UIManager.AbilitySelectionUI.instantiate() as SelectAbilityUI
	_root.add_child(ui)
	ui.Initialize(_abilities)
	return ui
