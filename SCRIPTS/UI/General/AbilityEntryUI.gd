extends InspectableElement
class_name AbilityEntryUI


@export var Background : TextureRect

@export var abilityTypeHeader : Label
@export var abilityNameText : Label
@export var abilityDescriptionText : RichTextLabel
@export var abilityIcon : TextureRect
@export var cooldownParent : Control
@export var cooldownText : Label

@export_category("Weapon Stats Granted")
@export var StatsGrantedParent : EntryList
@export var StatsGrantedPrefab : PackedScene

@export_category("Uses")
@export var usesParent : Control
@export var usageLeft : Label

@export_category("Range")
@export var rangeParent : Control
@export var rangeText : Label

@export_category("Targeting")
@export var targetingParent : Control
@export var targetingTypeText : Label

@export_category("Speed")
@export var speedParent : Control
@export var speedText : Label

@export_category("BG Gradients")
@export var AbilityBG : GradientTexture2D
@export var WeaponBG : GradientTexture2D
@export var TacticalBG : GradientTexture2D
@export var PassiveBG : GradientTexture2D


func Initialize(_packedScene : PackedScene):
	var ability = _packedScene.instantiate() as Ability
	Refresh(ability)

func Refresh(_ability : Ability):
	if _ability == null:
		return

	match _ability.type:
		Ability.AbilityType.Standard:
			if Background != null:
				Background.texture = AbilityBG

			if abilityTypeHeader != null:
				abilityTypeHeader.text = GameManager.LocalizationSettings.AbilityTypeAbilityTextShorthand
				abilityTypeHeader.modulate = GameManager.LocalizationSettings.AbilityTypeAbilityColor
		Ability.AbilityType.Weapon:
			if Background != null:
				Background.texture = WeaponBG

			if abilityTypeHeader != null:
				abilityTypeHeader.text = GameManager.LocalizationSettings.AbilityTypeWeaponTextShorthand
				abilityTypeHeader.modulate = GameManager.LocalizationSettings.AbilityTypeWeaponColor

			if StatsGrantedParent != null:
				StatsGrantedParent.ClearEntries()
				if _ability.StatData != null:
					for stats : StatDef in _ability.StatData.GrantedStats:
						var entry = StatsGrantedParent.CreateEntry(StatsGrantedPrefab)
						entry.statValue.text = str(stats.Value)
						entry.icon.texture = stats.Template.loc_icon

		Ability.AbilityType.Tactical:
			if Background != null:
				Background.texture = TacticalBG

			if abilityTypeHeader != null:
				abilityTypeHeader.text = GameManager.LocalizationSettings.AbilityTypeTacticalTextShorthand
				abilityTypeHeader.modulate = GameManager.LocalizationSettings.AbilityTypeTacticalColor
		Ability.AbilityType.Passive:
			if Background != null:
				Background.texture = PassiveBG

			if abilityTypeHeader != null:
				abilityTypeHeader.text = GameManager.LocalizationSettings.AbilityTypePassiveTextShorthand
				abilityTypeHeader.modulate = GameManager.LocalizationSettings.AbilityTypePassiveColor


	abilityNameText.text = _ability.loc_displayName
	abilityIcon.texture = _ability.icon

	if abilityDescriptionText != null:
		_ability.GetComponents() # Sometimes the references just drop off and the ability was JUST initialized. So manually call get components here for formatting
		var formatDict = FormatAbilityDescription(_ability)
		var translated_string = tr(_ability.loc_displayDesc)
		abilityDescriptionText.text = translated_string.format(formatDict)

	UpdateTargeting(_ability)
	UpdateSpeed(_ability)
	UpdateUsages(_ability)
	UpdateRange(_ability)

	cooldownParent.visible = _ability.abilityCooldown != 0
	if cooldownText != null:
		cooldownText.text = "{AMT}".format({"AMT" : _ability.abilityCooldown })


func UpdateTargeting(_ability : Ability):
	if targetingParent == null:
		return

	var targeting = _ability.TargetingData
	if targeting == null:
		targetingParent.visible = false
		return

	targetingParent.visible = true
	match targeting.Type:
		SkillTargetingData.TargetingType.Simple:
			targetingTypeText.text = GameManager.LocalizationSettings.TargetingSimpleText
			targetingTypeText.modulate = GameManager.LocalizationSettings.TargetingSimpleColor
			pass
		SkillTargetingData.TargetingType.ShapedFree:
			targetingTypeText.text = GameManager.LocalizationSettings.TargetingShapedText
			targetingTypeText.modulate = GameManager.LocalizationSettings.TargetingShapedColor
			pass
		SkillTargetingData.TargetingType.ShapedDirectional:
			targetingTypeText.text = GameManager.LocalizationSettings.TargetingDirectionalText
			targetingTypeText.modulate = GameManager.LocalizationSettings.TargetingDirectionalColor
			pass
		SkillTargetingData.TargetingType.Global:
			targetingTypeText.text = GameManager.LocalizationSettings.TargetingGlobalText
			targetingTypeText.modulate = GameManager.LocalizationSettings.TargetingGlobalColor
			pass
		SkillTargetingData.TargetingType.SelfOnly:
			targetingTypeText.text = GameManager.LocalizationSettings.TargetingSelfText
			targetingTypeText.modulate = GameManager.LocalizationSettings.TargetingSelfColor
			pass


func UpdateRange(_ability : Ability):
	if rangeParent == null:
		return

	var targeting = _ability.TargetingData
	if targeting == null:
		rangeParent.visible = false
		return

	match targeting.Type:
		SkillTargetingData.TargetingType.Simple, SkillTargetingData.TargetingType.ShapedFree:
			rangeParent.visible = true
			var range = _ability.GetRange()
			if range.x == range.y:
				rangeText.text = str(range.x)
			else:
				rangeText.text = tr(GameManager.LocalizationSettings.RangeAmountTextFormat).format({"MIN" : range.x, "MAX" : range.y })
		_:
			rangeParent.visible = false

func UpdateUsages(_ability : Ability):
	if usesParent == null:
		return

	if _ability.limitedUsage == -1:
		usesParent.visible = false
		return

	usesParent.visible = true
	usageLeft.text = str(_ability.remainingUsages)

func UpdateSpeed(_ability : Ability):
	if speedText == null:
		return

	if _ability.type == Ability.AbilityType.Passive:
		speedParent.visible = false
		return

	speedParent.visible = true

	match _ability.ability_speed:
		Ability.AbilitySpeed.Normal:
			speedText.text = GameManager.LocalizationSettings.AbilitySpeedNormalText
			speedText.modulate = GameManager.LocalizationSettings.AbilitySpeedNormalColor
			pass
		Ability.AbilitySpeed.Fast:
			speedText.text = GameManager.LocalizationSettings.AbilitySpeedFastText
			speedText.modulate = GameManager.LocalizationSettings.AbilitySpeedFastColor
			pass
		Ability.AbilitySpeed.Slow:
			speedText.text = GameManager.LocalizationSettings.AbilitySpeedSlowText
			speedText.modulate = GameManager.LocalizationSettings.AbilitySpeedSlowColor
			pass

func FormatAbilityDescription(_ability : Ability):
	var dict = {}

	# Get the damage-based data
	if _ability.UsableDamageData != null:
		if _ability.UsableDamageData.DamageAffectsUsersHealth:
			dict["DMG_DRAINPERC"] = abs(_ability.UsableDamageData.DamageToHealthRatio * 100)

		dict["DMG_AGGRESSIVESTAT"] = tr(_ability.UsableDamageData.AgressiveStat.loc_displayName_short)
		dict["DMG_AGGRESSIVEMOD"] = "%+d%%" % (_ability.UsableDamageData.AgressiveMod * 100)

		# Scale this up as needed. Format should be DMG_VULNERABLE_[DESC or MULT]_[Index]
		if _ability.UsableDamageData.VulerableDescriptors.size() != 0:
			var count = 0
			for multiplier in _ability.UsableDamageData.VulerableDescriptors:
				dict["DMG_VULNERABLE_DESC_" + str(count)] = tr(multiplier.Descriptor.loc_name)
				dict["DMG_VULNERABLE_MULT_" + str(count)] = multiplier.Multiplier
				count += 1

	# Get the heal-based data
	if _ability.HealData != null:
		if _ability.HealData.ScalingStat != null:
			dict["HEAL_STAT"]= tr(_ability.HealData.ScalingStat.loc_displayName)
		dict["HEAL_MOD"] = "%+d%%" % (_ability.HealData.ScalingMod * 100)
		dict["HEAL_FLAT"] = _ability.HealData.FlatValue

	for stack in _ability.executionStack:
		var combateffect = stack as ApplyEffectStep
		if combateffect != null:
			dict["EFFECT_TURNS"] = str(combateffect.CombatEffect.Turns)
			var shield = combateffect.CombatEffect as ArmorEffect
			if shield != null:
				dict["SHIELD_FLAT"] = shield.FlatValue
				dict["SHIELD_STAT"] = tr(shield.RelativeStat.loc_displayName)
				dict["SHIELD_MOD"] =  "%+d%%" % (shield.Mod * 100)

			var statBuff = combateffect.CombatEffect as StatChangeEffect
			if statBuff != null:
				# Format should be EFFECT_[NUM]_[FLAT/PERC/DERIVEDSTAT] etc
				var count = 0
				for effect in statBuff.StatChanges:
					dict["EFFECT_" + str(count) + "_FLAT"] = effect.FlatValue
					dict["EFFECT_" + str(count) + "_PERC"] = effect.SignedPercentageValue
					dict["EFFECT_" + str(count) + "_MODIFIEDSTAT"] = tr(effect.Stat.loc_displayName)
					if effect.DerivedFromStat != null:	dict["EFFECT_" + str(count) + "_DERIVEDSTAT"] = tr(effect.DerivedFromStat.loc_displayName)
					count += 1

	return dict
