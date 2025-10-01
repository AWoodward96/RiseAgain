extends GridEntityBase
class_name GEProximityBomb

@export var interruptionType : GameSettingsTemplate.TraversalResult
@export var damageData : DamageData
@export var defaultDamage : int = -4

func Spawn(_map : Map, _origin : Tile, _source : UnitInstance, _ability : Ability, _allegience : GameSettingsTemplate.TeamID, _direction : GameSettingsTemplate.Direction):
	super(_map, _origin, _source, _ability, _allegience, _direction)
	_origin.AddEntity(self)


func OnUnitTraversed(_unitInstance : UnitInstance, _tile : Tile):
	# If for some reason this hasn't been cleaned up yet, then say its good
	if Expired:
		return GameSettingsTemplate.TraversalResult.OK

	var newDamageStepResult = DamageStepResult.new()
	newDamageStepResult.Source = Source
	newDamageStepResult.AbilityData = SourceAbility

	if Source == null:
		newDamageStepResult.HealthDelta = defaultDamage
	else:
		newDamageStepResult.HealthDelta = -GameManager.GameSettings.DamageCalculation(Source, _unitInstance, damageData, Origin.AsTargetData(), SourceAbility)

	CurrentMap.grid.SetUnitGridPosition(_unitInstance, Origin.Position, true, false)
	_unitInstance.ModifyHealth(newDamageStepResult.HealthDelta, newDamageStepResult, true)

	if Source != null:

		# try and grant the source of this ability some exp for this
		var healthABS = abs(newDamageStepResult.HealthDelta)
		var expGained = 0
		if _unitInstance.currentHealth <= healthABS:
			# Hard coding AOE = false here bc how how this is set up. If a large aoe explosion is made, update this
			expGained = GameManager.GameSettings.ExpFromKillCalculation(healthABS, Source, _unitInstance, false)
		else:
			expGained = GameManager.GameSettings.ExpFromDamageCalculation(healthABS, Source, _unitInstance, false)

		var fakeResult = DamageStepResult.new()
		fakeResult.ExpGain = expGained
		fakeResult.Source = Source

		var passiveAction = PassiveAbilityAction.Construct(Source, SourceAbility)
		passiveAction.log.actionStepResults.append(fakeResult)
		passiveAction.executionStack.append(GainExpStep.new())

		CurrentMap.AppendPassiveAction(passiveAction)


	ExecutionComplete = true
	Expired = true
	CurrentMap.RemoveGridEntity(self)
	return interruptionType



func GetLocalizedDescription(_tile : Tile):
	var returnString = tr(localization_desc)
	var madlibs = {}
	if Source == null:
		madlibs["NUM"] = defaultDamage
	else:
		madlibs["NUM"] = -GameManager.GameSettings.DamageCalculation(Source, null, damageData, Origin.AsTargetData(), SourceAbility)

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
