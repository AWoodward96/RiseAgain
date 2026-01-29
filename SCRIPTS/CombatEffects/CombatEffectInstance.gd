extends Node2D
class_name CombatEffectInstance

@export var TurnsRemaining : int
@export var Stacks : int = 1

var Template : CombatEffectTemplate
var SourceUnit : UnitInstance
var AffectedUnit : UnitInstance
var AbilitySource : Ability

static func Create(_sourceUnit : UnitInstance, _affectedUnit : UnitInstance, _template : CombatEffectTemplate,  _abilitySource : Ability, _actionLog : ActionLog):
	if _template == null || _affectedUnit == null:
		return null

	return _template.CreateInstance(_sourceUnit, _affectedUnit, _abilitySource, _actionLog)

func IsExpired():
	if TurnsRemaining == 0:
		return true

func OnEffectApplied():
	pass

func OnEffectRemoved():
	pass

func OnTurnStart():
	pass

func OnStackUpdated():
	pass

func ToJSON():
	var dict = {
			"type" : "CombatEffectInstance",
			"TurnsRemaining" : TurnsRemaining,
			"Template" : Template.resource_path,
			"Stacks" : Stacks
		}

	if SourceUnit != null:
		dict["SourceUnitPosition"] = SourceUnit.GridPosition

	if AffectedUnit != null:
		dict["AffectedUnitPosition"] = AffectedUnit.GridPosition

	if AbilitySource != null:
		dict["AbilitySourceUnitPosition"] = AbilitySource.ownerUnit.GridPosition
		dict["AbilitySourceName"] = AbilitySource.internalName
		if AbilitySource.internalName == "":
			push_error("Ability: " + AbilitySource.name + " doesn't have an internal name. Just give it one")

	return dict

func InitFromJSON(_dict, _map : Map):
	TurnsRemaining = int(_dict["TurnsRemaining"])
	Template = load(_dict["Template"]) as CombatEffectTemplate
	Stacks = _dict["Stacks"]

	if _dict.has("SourceUnitPosition"):
		var tile = _map.grid.GetTile(PersistDataManager.String_To_Vector2(_dict["SourceUnitPosition"]))
		if tile != null && tile.Occupant != null:
			SourceUnit = tile.Occupant
		else:
			push_error("Error in loading source unit position from save file")

	if _dict.has("AffectedUnitPosition"):
		var tile = _map.grid.GetTile(PersistDataManager.String_To_Vector2(_dict["AffectedUnitPosition"]))
		if tile != null && tile.Occupant != null:
			AffectedUnit = tile.Occupant
		else:
			push_error("Error in loading Affected unit position from save file")

	if _dict.has("AbilitySourceUnitPosition"):
		var tile = _map.grid.GetTile(PersistDataManager.String_To_Vector2(_dict["AbilitySourceUnitPosition"]))
		if tile != null && tile.Occupant != null:
			for ability in tile.Occupant.Abilities:
				if _dict["AbilitySourceName"] == ability.internalName:
					AbilitySource = ability
					break
		else:
			push_error("Error in loading Affected unit position from save file")

static func FromJSON(_dict : Dictionary):
	var combatEffectBase = CombatEffectInstance.new()

	match _dict["type"]:
		"WildNecromancerPassiveInstance":
			combatEffectBase = WildNecroPassiveInstance.new()
		"StunEffectInstance":
			combatEffectBase = StunEffectInstance.new()
		"StatChangeEffectInstance":
			combatEffectBase = StatChangeEffectInstance.new()
		"EnergizedEffectInstance":
			combatEffectBase = EnergizedEffectInstance.new()
		"ArmorEffectInstance":
			combatEffectBase = ArmorEffectInstance.new()
		"CombatEffectInstance":
			combatEffectBase = CombatEffectInstance.new()
		"StealthEffectInstance":
			combatEffectBase = StealthEffectInstance.new()
		"OnFireEffectInstance":
			combatEffectBase = OnFireEffectInstance.new()
		"InvulnerableEffectInstance":
			combatEffectBase = InvulnerableEffectInstance.new()
		"TurnStartHealEffectInstance":
			combatEffectBase = TurnStartHealEffectInstance.new()
		"SnapBlossomEffectInstance":
			combatEffectBase = SnapBlossomEffectInstance.new()

	# Call Deferred is actually goated
	# The Grid isn't gonna be fully initialized yet, so we defer this call so that the Occupants are set
	# Because on this frame they're not set - but next frame they will be!
	combatEffectBase.call_deferred("InitFromJSON", _dict, Map.Current)
	return combatEffectBase
