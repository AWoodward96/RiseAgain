extends CutsceneEventBase
class_name SpawnUnitEvent

@export var unitTemplate : UnitTemplate
@export var position : Vector2i
@export var level : int = 1
@export var allegience : GameSettingsTemplate.TeamID
@export var aiBehavior : AIBehaviorBase
@export var aggroBehavior : AlwaysAggro
@export var healthPerc : float = 1
@export var preAppliedEffects : Array[CombatEffectTemplate]


func Enter(_context : CutsceneContext):
	if unitTemplate == null:
		return true

	if Map.Current == null:
		return true

	var unit = Map.Current.CreateUnit(unitTemplate, level, healthPerc)
	Map.Current.InitializeUnit(unit, position, allegience)
	unit.SetAI(aiBehavior, aggroBehavior)

	for effect in preAppliedEffects:
		var instance = effect.CreateInstance(unit, unit, null)
		unit.AddCombatEffect(instance)

	if Map.Current.CurrentCampaign != null && allegience == GameSettingsTemplate.TeamID.ALLY:
		Map.Current.CurrentCampaign.CurrentRoster.append(unit)
	return true
