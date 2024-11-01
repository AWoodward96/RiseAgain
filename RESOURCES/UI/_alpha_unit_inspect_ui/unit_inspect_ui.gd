extends CanvasLayer
class_name UnitInspectUI

@export var portrait : TextureRect
@export var nameText : Label
@export var descriptionText : Label
@export var classSprite :TextureRect
@export var affinityIcon :TextureRect
@export var unitHealthBar : UnitHealthBar

@export var affinityEntryPrefab : PackedScene
@export var strongAgainstEntryList : EntryList
@export var weakAgainstEntryList : EntryList

@export var statBlockEntryList : EntryList
@export var statBlockEntry : PackedScene
@export var statBlockLocalization : String = "ui_statblock_label_large"


@export var itemSlotEntryList : EntryList
@export var itemSlotEntry : PackedScene

var unit : UnitInstance

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

	itemSlotEntryList.ClearEntries()
	for item in unit.ItemSlots:
		var entry = itemSlotEntryList.CreateEntry(itemSlotEntry)
		entry.Refresh(item)


	statBlockEntryList.ClearEntries()
	var statsToBeDisplayed = GameManager.GameSettings.UIDisplayedStats
	for stat in statsToBeDisplayed:
		var currentValue = unit.GetWorkingStat(stat)
		var entry = statBlockEntryList.CreateEntry(statBlockEntry)
		entry.icon.texture = stat.loc_icon
		entry.statlabel.text = tr(statBlockLocalization).format({"TEXT": tr(stat.loc_displayName_short), "VALUE" : str(currentValue)})

static func Show(_unitInstance : UnitInstance):
	var ui = UIManager.UnitInspectionUI.instantiate()
	ui.Initialize(_unitInstance)
	GameManager.add_child(ui)
	return ui
