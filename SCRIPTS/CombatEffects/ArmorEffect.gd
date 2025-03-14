extends CombatEffectTemplate
class_name ArmorEffect

@export_group("Armor Data")
@export var UseDamageDealtAsValue : bool
@export var UseSourceForStats : bool

@export_group("Mod Data")
@export var FlatValue : float
@export var RelativeStat : StatTemplate
@export var ModType : DamageData.ModificationType
@export var Mod : float
@export var MultiplyByX : bool


func CreateInstance(_sourceUnit : UnitInstance, _affectedUnit : UnitInstance, _actionLog : ActionLog):
	if _affectedUnit.Template.Descriptors.count(ImmunityDescriptor) > 0:
		return null

	var armorInstance = ArmorEffectInstance.new()

	armorInstance.Template = self
	armorInstance.SourceUnit = _sourceUnit
	armorInstance.AffectedUnit = _affectedUnit
	armorInstance.TurnsRemaining = Turns

	if _actionLog != null:
		armorInstance.AbilitySource = _actionLog.ability

	var value = FlatValue
	if UseDamageDealtAsValue && _actionLog != null:
		# Loop through the action results - they should know how much damage is being delt.
		# If at this point your action results are empty - you're doing this wrong.
		# Your effect should either not be using damage dealt as a value, or your ordering of the ability is incorrect
		for results in _actionLog.actionResults:
			if results.Source == _sourceUnit && results.HealthDelta < 0: # HealthDelta is signed. Negative for damage
				value += abs(results.HealthDelta)

	if RelativeStat != null:
		if UseSourceForStats && _sourceUnit != null:
			value += _sourceUnit.GetWorkingStat(RelativeStat)
		elif _affectedUnit != null:
			value += _affectedUnit.GetWorkingStat(RelativeStat)

	# Check if this value should be scaled at all
	if ModType != DamageData.ModificationType.None:
		match ModType:
			DamageData.ModificationType.None:
				pass
			DamageData.ModificationType.Additive:
				value += Mod
			DamageData.ModificationType.Multiplicative:
				value = floori(value * Mod)
			DamageData.ModificationType.Divisitive:
				value = floori(value / Mod)

	if MultiplyByX:
		value = value * _sourceUnit.currentFocus

	armorInstance.ArmorValue = value

	Juice.CreateArmorPopup(value, _affectedUnit.CurrentTile)
	return armorInstance
