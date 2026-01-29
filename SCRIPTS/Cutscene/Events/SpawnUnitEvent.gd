extends CutsceneEventBase
class_name SpawnUnitEvent

@export var unitTemplate : UnitTemplate
@export var fromContext : String
@export var position : Vector2i
@export var level : int = 1
@export var allegience : GameSettingsTemplate.TeamID = GameSettingsTemplate.TeamID.ALLY
@export var aiBehavior : AIBehaviorBase
@export var aggroBehavior : AlwaysAggro
@export var healthPerc : float = 1
@export var preAppliedEffects : Array[CombatEffectTemplate]


func Enter(_context : CutsceneContext):
	if Map.Current == null:
		return true

	var loadedUnit : UnitInstance = null
	if unitTemplate != null:
		loadedUnit = Map.Current.CreateUnit(unitTemplate, level, healthPerc)
		if Map.Current.CurrentCampaign != null && allegience == GameSettingsTemplate.TeamID.ALLY:
			Map.Current.CurrentCampaign.CurrentRoster.append(loadedUnit)

	elif fromContext != "":
		# If we're initializing from context, then the unit instance should already exist in context
		var unitInContext = _context.ContextDict[fromContext]
		if unitInContext is UnitInstance:
			loadedUnit = unitInContext
			loadedUnit.currentHealth = loadedUnit.maxHealth * healthPerc
		elif unitInContext is UnitTemplate:
			loadedUnit = Map.Current.CreateUnit(unitInContext, level, healthPerc)

	Map.Current.InitializeUnit(loadedUnit, position, allegience)
	loadedUnit.SetAI(aiBehavior, aggroBehavior)

	for effect in preAppliedEffects:
		var instance = effect.CreateInstance(loadedUnit, loadedUnit, null, null)
		loadedUnit.AddCombatEffect(instance)

	return true
