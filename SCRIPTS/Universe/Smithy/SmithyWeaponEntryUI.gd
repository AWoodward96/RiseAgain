extends Control
class_name SmithyWeaponEntryUI

@export var weaponTitle : Label
@export var weaponDesc : Label
@export var weaponIcon : TextureRect
@export var statChangeEntryParent : EntryList
@export var costParent : EntryList
@export var costEntry : PackedScene
@export var canUseParent : EntryList
@export var weaponDetailsParent : EntryList
@export var canAffordColor : Color = Color.WHITE
@export var cantAffordColor : Color = Color.WHITE

var ability : Ability
var createdUnitIcons : Array[TextureRect]

func Initialize(_weaponData : SmithyWeaponUnlockDef, _levelReq : int):
	if _weaponData == null || _weaponData.unlockableTemplate == null:
		queue_free()
		return

	var packedScene = load(_weaponData.unlockableTemplate.AbilityPath) as PackedScene
	if packedScene == null:
		queue_free()
		return

	var local = packedScene.instantiate()
	if local is not Ability:
		queue_free()
		return

	ability = local
	weaponTitle.text = ability.loc_displayName
	weaponDesc.text = ability.loc_displayDesc
	weaponIcon.texture = ability.icon

	costParent.ClearEntries()
	for c in _weaponData.cost.cost:
		var entry = costParent.CreateEntry(costEntry)
		entry.Initialize(c, canAffordColor, cantAffordColor)

	canUseParent.ClearEntries()
	for units in GameManager.UnitSettings.AllyUnitManifest:
		var persist = PersistDataManager.universeData.GetUnitPersistence(units)
		if persist == null:
			continue

		#if !persist.Unlocked:
			# return
		var found = false
		for unitWeaponDescriptor in units.WeaponDescriptors:
			for itemDescriptor in _weaponData.unlockableTemplate.Descriptors:
				if itemDescriptor == unitWeaponDescriptor:
					var entry = canUseParent.CreateEntry(UIManager.Generic_32x32_Texture)
					entry.texture = units.icon

					found = true
					break

			if found:
				break

	statChangeEntryParent.ClearEntries()
	if ability.StatData != null:
		for stat in ability.StatData.GrantedStats:
			var statchange = statChangeEntryParent.CreateEntry(UIManager.Generic_StatBlockEntry)
			statchange.icon.texture = stat.Template.loc_icon
			statchange.statValue.text = str(stat.Value)



	weaponDetailsParent.ClearEntries()
	match(ability.ability_speed):
		Ability.AbilitySpeed.Fast:
			var entry = weaponDetailsParent.CreateEntry(UIManager.Generic_32x32_Texture)
			entry.texture = GameManager.LocalizationSettings.FastSpeedIcon
		Ability.AbilitySpeed.Slow:
			var entry = weaponDetailsParent.CreateEntry(UIManager.Generic_32x32_Texture)
			entry.texture = GameManager.LocalizationSettings.SlowSpeedIcon

	if ability.TargetingData != null:
		match(ability.TargetingData.Type):
			SkillTargetingData.TargetingType.ShapedFree:
				var entry = weaponDetailsParent.CreateEntry(UIManager.Generic_32x32_Texture)
				entry.texture = GameManager.LocalizationSettings.ShapedFreeIcon
			SkillTargetingData.TargetingType.ShapedDirectional:
				var entry = weaponDetailsParent.CreateEntry(UIManager.Generic_32x32_Texture)
				entry.texture = GameManager.LocalizationSettings.ShapedDirectionalIcon
			SkillTargetingData.TargetingType.Global:
				var entry = weaponDetailsParent.CreateEntry(UIManager.Generic_32x32_Texture)
				entry.texture = GameManager.LocalizationSettings.GlobalIcon
			SkillTargetingData.TargetingType.SelfOnly:
				var entry = weaponDetailsParent.CreateEntry(UIManager.Generic_32x32_Texture)
				entry.texture = GameManager.LocalizationSettings.SelfOnlyIcon
