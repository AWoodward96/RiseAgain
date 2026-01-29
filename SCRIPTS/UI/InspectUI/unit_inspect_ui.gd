extends CanvasLayer
class_name UnitInspectUI

static var Instance : UnitInspectUI

@export var portrait : TextureRect
@export var nameText : Label
@export var descriptionText : Label
@export var classSprite :TextureRect
@export var affinityIcon :TextureRect
@export var unitHealthBar : UnitHealthBar

@export var affinityEntryPrefab : PackedScene
@export var strongAgainstEntryList : EntryList
@export var weakAgainstEntryList : EntryList


var unit : UnitInstance

func _ready() -> void:
	if Instance != null:
		queue_free()
	else:
		Instance = self

func _exit_tree() -> void:
	if Instance == self:
		Instance = null

func Initialize(_unitInstance : UnitInstance):
	unit = _unitInstance
	Refresh()

func Refresh():
	if unit == null || unit.Template == null:
		return

	unitHealthBar.SetUnit(unit)
	portrait.texture = unit.Template.icon
	nameText.text = unit.Template.loc_DisplayName
	descriptionText.text = unit.Template.loc_Description

	classSprite.texture = unit.Template.icon
	affinityIcon.texture = unit.Template.Affinity.loc_icon

	var thisAffinity = unit.Template.Affinity
	var allAffinities = GameManager.GameSettings.AllAffinities
	strongAgainstEntryList.ClearEntries()
	weakAgainstEntryList.ClearEntries()
	for affinityTemplate in allAffinities:
		if thisAffinity.strongAgainst & affinityTemplate.affinity:
			var newAddition = strongAgainstEntryList.CreateEntry(affinityEntryPrefab)
			newAddition.texture = affinityTemplate.loc_icon

		if affinityTemplate.strongAgainst & thisAffinity.affinity:
			var newAddition = weakAgainstEntryList.CreateEntry(affinityEntryPrefab)
			newAddition.texture = affinityTemplate.loc_icon

static func Show(_unitInstance : UnitInstance):
	var ui = UIManager.UnitInspectionUI.instantiate()
	ui.Initialize(_unitInstance)
	GameManager.add_child(ui)
	return ui
