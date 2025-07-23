extends PassiveListenerBase
class_name TurnStartListener

@export var requireAffectedTilesToTrigger : bool = true

func RegisterListener(_ability : Ability, _map : Map):
	super(_ability, _map)
	if !_map.OnTurnStart.is_connected(TurnStart):
		_map.OnTurnStart.connect(TurnStart)


func TurnStart(_turn : GameSettingsTemplate.TeamID):
	var owner = ability.ownerUnit
	if owner.UnitAllegiance == _turn:
		var passiveInstance = PassiveAbilityAction.Construct(ability.ownerUnit, ability)
		passiveInstance.executionStack = ability.executionStack
		passiveInstance.log.actionOriginTile = owner.CurrentTile

		if ability.TargetingData != null:
			passiveInstance.log.affectedTiles = ability.TargetingData.GetAffectedTiles(owner, Map.Current.grid, owner.CurrentTile)
			if requireAffectedTilesToTrigger && passiveInstance.log.affectedTiles.size() == 0:
				return

		passiveInstance.BuildResults()
		Map.Current.AppendPassiveAction(passiveInstance)
		pass
	pass
