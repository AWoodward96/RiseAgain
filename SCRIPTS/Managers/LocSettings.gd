extends Resource
class_name LocSettings

# This class is for hard coded localization.

static var Level_Num_Short = "ui_level_num_short"
static var Level_Num = "ui_level_num"
static var X_Num = "ui_xNUM"
static var OneX_TEXT = "ui_1x_text"
static var Current_Max = "ui_current_max"
static var UI_Yes = "ui_yes"
static var UI_No = "ui_no"
static var Health_Submerged = "ui_healthunknown"

static var Optional_Objective_Block = "Optional Objective: \n{TEXT}"
static var Status_Unknown = "ui_status_unknown"
static var Status_Healthy = "ui_status_healthy"
static var Status_Injured = "ui_status_injured"
static var Location_Tavern = "ui_location_tavern"
static var Location_Campsite = "ui_location_campsite"

@export_category("Missing Info")
@export var Missing_CombatEffectIcon : Texture2D
@export var Missing_CombatEffectName : String


@export_category("Damage Text Formatting")
@export var HealColor : Color
@export var DamageColor : Color
@export var CritColor : Color
@export var CollisionColor : Color

@export_category("Ability Text Formatting")
@export var RangeAmountTextFormat : String

@export var AbilityTypeWeaponTextShorthand : String
@export var AbilityTypeWeaponColor : Color
@export var AbilityTypeTacticalTextShorthand : String
@export var AbilityTypeTacticalColor : Color
@export var AbilityTypeAbilityTextShorthand : String
@export var AbilityTypeAbilityColor : Color

@export var AbilityTypePassiveTextShorthand : String
@export var AbilityTypePassiveColor : Color

@export var TargetingSimpleText : String
@export var TargetingSimpleColor : Color
@export var TargetingDirectionalText : String
@export var TargetingDirectionalColor : Color
@export var TargetingShapedText : String
@export var TargetingShapedColor : Color
@export var TargetingSelfText : String
@export var TargetingSelfColor : Color
@export var TargetingGlobalText : String
@export var TargetingGlobalColor : Color

@export var AbilitySpeedNormalText : String
@export var AbilitySpeedNormalColor : Color
@export var AbilitySpeedFastText : String
@export var AbilitySpeedFastColor : Color
@export var AbilitySpeedSlowText : String
@export var AbilitySpeedSlowColor : Color

@export var FastSpeedIcon : Texture2D
@export var FastSpeedDescText : String
@export var SlowSpeedIcon : Texture2D
@export var SlowSpeedDescText : String
@export var ShapedFreeIcon : Texture2D
@export var ShapedFreeDescText : String
@export var ShapedDirectionalIcon : Texture2D
@export var ShapedDirectionalDescText : String
@export var GlobalIcon : Texture2D
@export var GlobalDescText : String
@export var SelfOnlyIcon : Texture2D
@export var SelfOnlyDescText : String

@export_category("Bastion Localization")
@export var prestiegeLevelNum : String = "ui_prestiegeLevelNum"
@export var prestiegeExpValue : String = "ui_prestiegeExpValues"


@export_category("Context UI")
@export var waitAction : String = "ui_wait"
@export var openChestAction : String = "ui_openchest"


@export_category("Item Acquired UI")
@export var gotItemConcat : String = "ui_gotitem_concat"
@export var stoleItemConcat : String = "ui_stoleitem_concat"
@export var butSentToConvoyConcat : String = "ui_but_it_was_sent_to_convoy"

func FormatAsHeal(_healAmount : int):
	var htmlHash = HealColor.to_html(false)
	return FormatCenter("[color=#" + htmlHash + "]" + str(_healAmount) + "[/color]")

func FormatForCombat(_damageAmount : int, _collisionAmount : int, _healAmount : int, _forceShow : bool = false):
	var string = ""
	if _damageAmount != 0 || (_damageAmount == 0 && _collisionAmount == 0 && _healAmount == 0 && _forceShow):
		string += "[color=#{hash}]{dmg}[/color] ".format({"hash" : DamageColor.to_html(false), "dmg" : str(_damageAmount)})
	if _collisionAmount != 0:
		string += "[color=#{hash}]{dmg}[/color] ".format({"hash" : CollisionColor.to_html(false), "dmg" : str(_collisionAmount)})
	if _healAmount != 0:
		string += "[color=#{hash}]+{dmg}[/color] ".format({"hash" : HealColor.to_html(false), "dmg" : str(_healAmount)})
	return FormatCenter(string)

func FormatCenter(_string : String):
	return "[center]" + _string + "[/center]"


func FormatAbilityDescription(_ability : Ability):
	var dict = {}

	if _ability.StatData != null:
		var count = 1
		for statgrowth in _ability.StatData.GrantedStats:
			dict["STAT" + str(count)] = _ability.tr(statgrowth.Template.loc_displayName_short)
			dict["GROWTH" + str(count)] = str(statgrowth.Value)
			count += 1

	if  _ability is Item && _ability.growthModifierData != null:
		var count = 1
		for statgrowth in _ability.growthModifierData.GrowthModifiers:
			dict["STATGROWTHSTAT" + str(count)] = _ability.tr(statgrowth.Template.loc_displayName_short)
			dict["STATGROWTHPERC" + str(count)] = str(statgrowth.Value)
			count += 1

		dict["GROWTHCOUNT"] = str(_ability.growthModifierData.SuccessCount)

	# Get the damage-based data
	if _ability.UsableDamageData != null:
		if _ability.UsableDamageData.DamageAffectsUsersHealth:
			dict["DMG_DRAINPERC"] = abs(_ability.UsableDamageData.DamageToHealthRatio * 100)

		dict["DMG_AGGRESSIVESTAT"] = tr(_ability.UsableDamageData.AgressiveStat.loc_displayName_short)
		dict["DMG_AGGRESSIVEMOD"] = _ability.UsableDamageData.AgressiveMod * 100

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
		dict["HEAL_MOD"] = _ability.HealData.ScalingMod * 100
		dict["HEAL_FLAT"] = _ability.HealData.FlatValue

	for stack in _ability.executionStack:
		var combateffect = stack as ApplyEffectStep
		if combateffect != null:
			dict["EFFECT_TURNS"] = str(combateffect.CombatEffect.Turns)
			var shield = combateffect.CombatEffect as ArmorEffect
			if shield != null:
				dict["SHIELD_FLAT"] = shield.FlatValue
				if shield.RelativeStat != null: dict["SHIELD_STAT"] = tr(shield.RelativeStat.loc_displayName)
				dict["SHIELD_MOD"] = shield.Mod * 100

			var statBuff = combateffect.CombatEffect as StatChangeEffect
			if statBuff != null:
				# Format should be EFFECT_[NUM]_[FLAT/PERC/DERIVEDSTAT] etc
				var count = 0
				for effect in statBuff.StatChanges:
					dict["EFFECT_" + str(count) + "_FLAT"] = effect.FlatValue
					dict["EFFECT_" + str(count) + "_PERC"] = effect.SignedPercentageValue
					if effect.Stat != null: dict["EFFECT_" + str(count) + "_MODIFIEDSTAT"] = tr(effect.Stat.loc_displayName)
					if effect.DerivedFromStat != null:	dict["EFFECT_" + str(count) + "_DERIVEDSTAT"] = tr(effect.DerivedFromStat.loc_displayName)
					count += 1

	return dict
