extends DetailContainer
class_name NewAbilityEntryUI

signal OnPressed(_entry : NewAbilityEntryUI)


@export var nameLabel : Label
@export var descLabel : Label
@export var icon : TextureRect
@export var animator : AnimationPlayer

@export var statChangeDetailParent : Control
@export var statChangeEntryParent : EntryList

@export var weaponRangeParent : Control
@export var weaponRangeText : Label
@export var weaponDetailsParent : EntryList

var ability : Ability
var unlockable : AbilityUnlockable
var persistData : UnlockablePersistData
var lastAddedStatChangeEntry : Control
var firstAddedWeaponIcon : Control

var speedEntry : DetailEntry
var targetingTypeEntry : DetailEntry

func Initialize(_ability : Ability, _optionalUnlockable : AbilityUnlockable = null):
	ability = _ability
	unlockable = _optionalUnlockable
	UpdateMetaData()
	AddWeaponRange()
	AddWeaponSpeed()
	AddWeaponTargeting()
	AddStatChangeData()

	if lastAddedStatChangeEntry != null && firstAddedWeaponIcon != null:
		UIManager.AssignFocusNeighbors_Horizontal(lastAddedStatChangeEntry.detailElement, firstAddedWeaponIcon)

	if lastAddedStatChangeEntry == null && firstAddedWeaponIcon != null:
		# Meaning there's no stat change entry but there is a weapon icon
		UIManager.AssignFocusNeighbors_Vertical(nameLabel, firstAddedWeaponIcon)
		UIManager.AssignFocusNeighbors_Vertical(firstAddedWeaponIcon, descLabel)



func UpdateMetaData():
	nameLabel.text = ability.loc_displayName
	var desc = tr(ability.loc_displayDesc)
	var formatDict = GameManager.LocalizationSettings.FormatAbilityDescription(ability)
	descLabel.text = desc.format(formatDict)
	icon.texture = ability.icon
	pass

func AddWeaponRange():
	if ability.TargetingData == null:
		weaponRangeParent.visible = false
	else:
		weaponRangeParent.visible = true
		var range = ability.GetRange()
		if range.x == range.y:
			weaponRangeText.text = str(range.x)
		else:
			weaponRangeText.text = tr(GameManager.LocalizationSettings.RangeAmountTextFormat).format({"MIN" : range.x, "MAX" : range.y })

	pass

func AddWeaponSpeed():
	match(ability.ability_speed):
		Ability.EAbilitySpeed.Fast:
			speedEntry = weaponDetailsParent.CreateEntry(UIManager.Generic_32x32_Texture)
			speedEntry.texture = GameManager.LocalizationSettings.FastSpeedIcon
			speedEntry.tooltip = GameManager.LocalizationSettings.FastSpeedDescText
		Ability.EAbilitySpeed.Slow:
			speedEntry = weaponDetailsParent.CreateEntry(UIManager.Generic_32x32_Texture)
			speedEntry.texture = GameManager.LocalizationSettings.SlowSpeedIcon
			speedEntry.tooltip = GameManager.LocalizationSettings.SlowSpeedDescText

	if speedEntry != null:
		Details.append(speedEntry)

	if firstAddedWeaponIcon == null:
		firstAddedWeaponIcon = speedEntry


func AddWeaponTargeting():
	if ability.TargetingData != null:
		match(ability.TargetingData.Type):
			SkillTargetingData.TargetingType.ShapedFree:
				targetingTypeEntry = weaponDetailsParent.CreateEntry(UIManager.Generic_32x32_Texture)
				targetingTypeEntry.texture = GameManager.LocalizationSettings.ShapedFreeIcon
				targetingTypeEntry.tooltip = GameManager.LocalizationSettings.ShapedFreeDescText
			SkillTargetingData.TargetingType.ShapedDirectional:
				targetingTypeEntry = weaponDetailsParent.CreateEntry(UIManager.Generic_32x32_Texture)
				targetingTypeEntry.texture = GameManager.LocalizationSettings.ShapedDirectionalIcon
				targetingTypeEntry.tooltip = GameManager.LocalizationSettings.ShapedDirectionalDescText
			SkillTargetingData.TargetingType.Global:
				targetingTypeEntry = weaponDetailsParent.CreateEntry(UIManager.Generic_32x32_Texture)
				targetingTypeEntry.texture = GameManager.LocalizationSettings.GlobalIcon
				targetingTypeEntry.tooltip = GameManager.LocalizationSettings.GlobalDescText
			SkillTargetingData.TargetingType.SelfOnly:
				targetingTypeEntry = weaponDetailsParent.CreateEntry(UIManager.Generic_32x32_Texture)
				targetingTypeEntry.texture = GameManager.LocalizationSettings.SelfOnlyIcon
				targetingTypeEntry.tooltip = GameManager.LocalizationSettings.SelfOnlyDescText

	if targetingTypeEntry != null:
		Details.append(targetingTypeEntry)

	if firstAddedWeaponIcon == null && targetingTypeEntry != null:
		firstAddedWeaponIcon = targetingTypeEntry


func AddStatChangeData():
	statChangeEntryParent.ClearEntries()
	if ability.StatData != null:
		statChangeDetailParent.focus_neighbor_top = statChangeDetailParent.get_path_to(nameLabel)
		nameLabel.focus_neighbor_bottom = nameLabel.get_path_to(statChangeDetailParent)
		statChangeDetailParent.focus_neighbor_bottom = statChangeDetailParent.get_path_to(descLabel)
		descLabel.focus_neighbor_top = descLabel.get_path_to(statChangeDetailParent)


		var index = 0
		var prevEntry : StatBlockEntry = null
		for stat in ability.StatData.GrantedStats:
			var statchange = statChangeEntryParent.CreateEntry(UIManager.Generic_StatBlockEntry) as StatBlockEntry
			statchange.icon.texture = stat.Template.loc_icon
			var prefix = "+" if stat.Value > 0 else "" # - values already get the -
			statchange.statValue.text = str(prefix, str(stat.Value))
			statchange.detailElement.tooltip = stat.Template.loc_description
			Details.append(statchange.detailElement)

			# ruh roh Godot 4.0 introduced a regression in how it navigates focusable UI's
			# so now I have to do all this shit by hand! : )
			statchange.detailElement.focus_neighbor_top = statchange.detailElement.get_path_to(nameLabel)
			statchange.detailElement.focus_neighbor_bottom = statchange.detailElement.get_path_to(descLabel)
			if index == 0:
				statChangeDetailParent.focus_neighbor_right = statChangeDetailParent.get_path_to(statchange.detailElement)
				statchange.detailElement.focus_neighbor_left = statchange.get_path_to(statChangeDetailParent)
			else:
				if prevEntry != null:
					prevEntry.detailElement.focus_neighbor_right = prevEntry.detailElement.get_path_to(statchange.detailElement)
					statchange.detailElement.focus_neighbor_left = statchange.detailElement.get_path_to(prevEntry.detailElement)

			index += 1
			prevEntry = statchange

		# for navigation
		lastAddedStatChangeEntry = prevEntry

func OnButtonPressed():
	OnPressed.emit(self)
