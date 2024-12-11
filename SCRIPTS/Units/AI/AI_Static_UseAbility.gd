extends AIBehaviorBase
class_name AIStaticUseAbility

# This unit will stand still and try their best to use the ability they have
func StartTurn(_map : Map, _unit : UnitInstance):
	super(_map, _unit)

	# Lets make it happen baby
	for ability in _unit.Abilities:
		if ability.type == Ability.AbilityType.Standard:
			if _unit.currentFocus >= ability.focusCost:
				var log = ActionLog.Construct(map.grid, ability.ownerUnit, ability)
				log.affectedTiles = ability.TargetingData.GetAffectedTiles(ability.ownerUnit, map.grid, ability.ownerUnit.CurrentTile)
				log.actionOriginTile = ability.ownerUnit.CurrentTile
				ability.ownerUnit.QueueTurnStartDelay()
				ability.ownerUnit.QueueDelayedCombatAction(log)
				return

	_unit.QueueEndTurn()
