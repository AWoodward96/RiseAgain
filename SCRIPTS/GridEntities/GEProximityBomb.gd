extends GridEntityBase
class_name GEProximityBomb

@export var interruptionType : GameSettingsTemplate.TraversalResult
@export var damageData : DamageData
@export var defaultDamage : int = -4

func Spawn(_map : Map, _origin : Tile, _source : UnitInstance, _ability : Ability, _allegience : GameSettingsTemplate.TeamID):
	super(_map, _origin, _source, _ability, _allegience)
	_origin.AddEntity(self)


func OnUnitTraversed(_unitInstance : UnitInstance, _tile : Tile):
	var newDamageStepResult = DamageStepResult.new()
	newDamageStepResult.Source = Source
	newDamageStepResult.AbilityData = SourceAbility

	if Source == null:
		newDamageStepResult.HealthDelta = defaultDamage
	else:
		newDamageStepResult.HealthDelta = -GameManager.GameSettings.DamageCalculation(Source, _unitInstance, damageData, Origin.AsTargetData())

	_unitInstance.ModifyHealth(newDamageStepResult.HealthDelta, newDamageStepResult, true)

	ExecutionComplete = true
	Expired = true
	return interruptionType

func Exit():
	Origin.RemoveEntity(self)

func ToJSON():
	var dict = super()
	dict["type"] = "GEProximityBomb"
	return dict

func InitFromJSON(_dict : Dictionary):
	super(_dict)
	position = Origin.GlobalPosition
	Origin.AddEntity(self)
	pass
