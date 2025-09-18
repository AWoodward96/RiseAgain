extends FullscreenUI
class_name SelectAbilityUI

static var Instance : SelectAbilityUI
signal SelectionComplete(_packedScene : PackedScene)

@export var entryParent : EntryList
@export var abilityEntryPrefab : PackedScene


func _ready() -> void:
	if Instance != null:
		print("ABILITYSELECTIONUI: Dupe detected. Closing self")
		queue_free()
		return

	Instance = self

func _exit_tree() -> void:
	super()
	print("ABILITYSELECTIONUI: Exit tree start")
	if Instance == self:
		Instance = null
	print("ABILITYSELECTIONUI: Exit tree end")

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
	print("ABILITYSELECTIONUI: Ability Selected, UI will now close")
	entryParent.ClearEntries()
	SelectionComplete.emit(_ability)
	queue_free()

static func Show(_root : Node2D, _abilities : Array[String]):
	var ui = UIManager.OpenFullscreenUI(UIManager.AbilitySelectionUI) as SelectAbilityUI
	ui.Initialize(_abilities)
	return ui
