extends CombatEffectTemplate
class_name WildNecroPassive

@export var UnitPairs : Array[UnitPair]
@export var SpawnedUnitAI : AIBehaviorBase
@export var SpawnedUnitAggroBehavior : AlwaysAggro


func CreateInstance(_sourceUnit : UnitInstance, _affectedUnit : UnitInstance, _actionLog : ActionLog):
	var passiveInstance = WildNecroPassiveInstance.new()
	passiveInstance.Template = self
	passiveInstance.SourceUnit = _sourceUnit
	return passiveInstance
