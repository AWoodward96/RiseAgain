extends MultipanelBase

@export var InspectUI : UnitInspectUI

@export var statBlockEntryList : EntryList
@export var statBlockEntry : PackedScene
@export var statBlockLocalization : String = "ui_statblock_label_large"


@export_category("Combat Effects")

@export var effectsList : EntryList
@export var effectsIconPrefab : PackedScene
@export var noEffectsLabel : Control

var unit : UnitInstance


func OnVisiblityChanged():
	if InspectUI != null:
		unit = InspectUI.unit
		UpdateStats()
		UpdateCombatEffects()
	pass

func UpdateStats():
	if unit == null:
		return

	statBlockEntryList.ClearEntries()
	var statsToBeDisplayed = GameManager.GameSettings.UIDisplayedStats
	for stat in statsToBeDisplayed:
		var currentValue = unit.GetWorkingStat(stat)
		var entry = statBlockEntryList.CreateEntry(statBlockEntry)
		entry.icon.texture = stat.loc_icon
		entry.statName.text = tr(stat.loc_displayName_short)
		entry.statValue.text = str(currentValue)

func UpdateCombatEffects():
	if effectsList == null:
		noEffectsLabel.visible = true
		return

	noEffectsLabel.visible = unit.CombatEffects.size() == 0

	effectsList.ClearEntries()
	for effect in unit.CombatEffects:
		var effectTemplate = effect.Template
		var entry = effectsList.CreateEntry(effectsIconPrefab) as EffectEntry

		var icon = GameManager.LocalizationSettings.Missing_CombatEffectIcon
		var labeltext = GameManager.LocalizationSettings.Missing_CombatEffectName
		if effectTemplate != null && effectTemplate.loc_icon != null:
				icon = effectTemplate.loc_icon

		if effectTemplate != null && effectTemplate.loc_name != "":
			labeltext = tr(effectTemplate.loc_name)

		if entry.icon != null: entry.icon.texture = icon
		if entry.label != null: entry.label.text = labeltext
