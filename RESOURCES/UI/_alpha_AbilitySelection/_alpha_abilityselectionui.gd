extends FullscreenUI
class_name SelectAbilityUI

static var Instance : SelectAbilityUI
signal SelectionComplete(_packedScene : PackedScene)

@export var entryParent : EntryList
@export var abilityEntryPrefab : PackedScene

@export_category("Unit Stat Container")
@export var unitIcon : TextureRect
@export var unitName : Label
@export var unitStatEntry : PackedScene
@export var unitStatParent : EntryList

var currentUnit : UnitInstance

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

func Initialize(_unit : UnitInstance, _abilities : Array[String]):
	currentUnit = _unit
	entryParent.ClearEntries()
	for abilityPath in _abilities:
		var entry = entryParent.CreateEntry(abilityEntryPrefab)
		var packedScene = load(abilityPath)
		if packedScene == null:
			continue
		entry.Initialize(packedScene)
		entry.EntrySelected.connect(OnAbilitySelected.bind(packedScene))

	entryParent.FocusFirst()
	RefreshStats()

func RefreshStats():
	unitIcon.texture = currentUnit.Template.icon
	unitName.text = currentUnit.Template.loc_DisplayName

	unitStatParent.ClearEntries()
	for stats in GameManager.GameSettings.LevelUpStats:
		var entry = unitStatParent.CreateEntry(unitStatEntry) as StatBlockEntry
		entry.Refresh(stats, currentUnit.GetWorkingStat(stats))


	pass

func OnAbilitySelected(_ability : PackedScene):
	print("ABILITYSELECTIONUI: Ability Selected, UI will now close")
	entryParent.ClearEntries()
	SelectionComplete.emit(_ability)
	queue_free()

static func Show(_unit : UnitInstance, _abilities : Array[String]):
	var ui = UIManager.OpenFullscreenUI(UIManager.AbilitySelectionUI) as SelectAbilityUI
	ui.Initialize(_unit, _abilities)
	return ui
