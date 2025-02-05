extends Control
class_name AbilityEntryUI

signal EntrySelected

@export var SelectedParent : Control

@export var abilityNameText : Label
@export var abilityDescriptionText : RichTextLabel
@export var abilityIcon : TextureRect
@export var focusCostText : Label
@export var rangeText : Label
@export var usageLeft : Label


func Initialize(_packedScene : PackedScene):
	var ability = _packedScene.instantiate() as Ability
	Refresh(ability)

func Refresh(_ability : Ability):
	if _ability == null:
		return

	abilityNameText.text = _ability.loc_displayName
	abilityIcon.texture = _ability.icon

	if abilityDescriptionText != null:
		var formatDict = FormatAbilityDescription(_ability)
		abilityDescriptionText.text = tr(_ability.loc_displayDesc).format(formatDict)


	if focusCostText != null:
		focusCostText.text = "{AMT}".format({"AMT" : _ability.focusCost })

	if rangeText != null:
		var range = _ability.GetRange()
		if _ability.TargetingData != null && _ability.TargetingData.Type == SkillTargetingData.TargetingType.ShapedDirectional:
			rangeText.text = tr("ui_range_directional")
		else:
			rangeText.text = tr("ui_range_amount").format({"MIN" : range.x, "MAX" : range.y })

	if usageLeft != null:
		usageLeft.text = str(_ability.remainingUsages)


func FormatAbilityDescription(_ability : Ability):
	var dict = {}

	# Get the damage-based data
	if _ability.UsableDamageData != null:
		if _ability.UsableDamageData.DamageAffectsUsersHealth:
			dict["DMG_DRAINPERC"] = abs(_ability.UsableDamageData.DamageToHealthRatio * 100)

		dict["DMG_AGGRESSIVESTAT"] = tr(_ability.UsableDamageData.AgressiveStat.loc_displayName)

		# Scale this up as needed. Format should be DMG_VULNERABLE_[DESC or MULT]_[Index]
		if _ability.UsableDamageData.VulerableDescriptors.size() != 0:
			var count = 0
			for multiplier in _ability.UsableDamageData.VulerableDescriptors:
				dict["DMG_VULNERABLE_DESC_" + str(count)] = tr(multiplier.Descriptor.loc_name)
				dict["DMG_VULNERABLE_MULT_" + str(count)] = multiplier.Multiplier

	# Get the heal-based data
	if _ability.HealData != null:
		if _ability.HealData.ScalingStat != null:
			dict["HEAL_STAT"]= tr(_ability.HealData.ScalingStat.loc_displayName)
		dict["HEAL_MOD"] = _ability.HealData.ScalingMod * 100
		dict["HEAL_FLAT"] = _ability.HealData.FlatValue

	for stack in _ability.executionStack:
		var combateffect = stack as ApplyEffectStep
		if combateffect != null:
			var shield = combateffect.CombatEffect as ArmorEffect
			if shield != null:
				dict["SHIELD_FLAT"] = shield.FlatValue
				dict["SHIELD_STAT"] = tr(shield.RelativeStat.loc_displayName)
				dict["SHIELD_MOD"] = shield.Mod * 100

			var statBuff = combateffect.CombatEffect as StatChangeEffect
			if statBuff != null:
				dict["EFFECT_FLAT"] = statBuff.FlatValue
				dict["EFFECT_PERC"] = statBuff.SignedPercentageValue
				dict["EFFECT_DERIVEDSTAT"] = tr(statBuff.DerivedFromStat.loc_displayName)


	return dict


func _ready():
	gui_input.connect(OnGUI)
	focus_entered.connect(OnFocusEntered)
	focus_exited.connect(OnFocusExited)

func OnGUI(_event : InputEvent):
	if _event.is_action_pressed("select"):
		EntrySelected.emit()

func OnFocusEntered():
	SelectedParent.visible = true

func OnFocusExited():
	SelectedParent.visible = false
