extends GridEntityBase
class_name GEProximityBomb

@export var interruptionType : GameSettingsTemplate.TraversalResult
@export var damageData : DamageData
@export var defaultDamage : int = -4

func Spawn(_map : Map, _origin : Tile, _source : UnitInstance, _ability : Ability, _allegience : GameSettingsTemplate.TeamID, _direction : GameSettingsTemplate.Direction):
	super(_map, _origin, _source, _ability, _allegience, _direction)
	_origin.AddEntity(self)


func OnUnitTraversed(_unitInstance : UnitInstance, _tile : Tile):
	var newDamageStepResult = DamageStepResult.new()
	newDamageStepResult.Source = Source
	newDamageStepResult.AbilityData = SourceAbility

	if Source == null:
		newDamageStepResult.HealthDelta = defaultDamage
	else:
		newDamageStepResult.HealthDelta = -GameManager.GameSettings.DamageCalculation(Source, _unitInstance, damageData, Origin.AsTargetData())

	CurrentMap.grid.SetUnitGridPosition(_unitInstance, Origin.Position, true, false)
	_unitInstance.ModifyHealth(newDamageStepResult.HealthDelta, newDamageStepResult, true)

	ExecutionComplete = true
	Expired = true
	return interruptionType

func GetLocalizedDescription(_tile : Tile):
	var returnString = tr(localization_desc)
	var madlibs = {}
	if Source == null:
		madlibs["NUM"] = defaultDamage
	else:
		madlibs["NUM"] = -GameManager.GameSettings.DamageCalculation(Source, null, damageData, Origin.AsTargetData())

	return returnString.format(madlibs)


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
