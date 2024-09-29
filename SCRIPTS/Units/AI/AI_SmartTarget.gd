extends AIBehaviorBase
class_name AISmartTarget

@export var Flags : Array[AITargetingFlag]

var options : Array[EnemyAIOption]
var selectedOption : EnemyAIOption

func StartTurn(_map : Map, _unit : UnitInstance):
	super(_map, _unit)

	options.clear()
	selectedOption = null
	# STEP ZERO:
	# Check if this enemy even has an ability to use. If they don't, then there's nothing to do
	var item = unit.EquippedWeapon
	if item == null || !item.IsDamage():
		unit.QueueEndTurn()
		return

	for i in range(0, Flags.size()):
		var aiflag = Flags[i]
		var allUnitsOnTeam = map.GetUnitsOnTeam(aiflag.Team)
		if aiflag.Descriptor != null:
			allUnitsOnTeam = allUnitsOnTeam.filter(func(x) : return x.Template.Descriptors.find(aiflag.Descriptor) != -1)

		for u in allUnitsOnTeam:
			var newOption = EnemyAIOption.new()
			newOption.flagIndex = i
			newOption.totalFlags = Flags.size()
			newOption.Update(_unit, u, map)

			if newOption.valid:
				newOption.UpdateWeight()
				options.append(newOption)

	if options.size() == 0:
		unit.QueueEndTurn()
		return

	options.sort_custom(SortOptions)

	# And what we're doing is.... the first option.
	# Because no other options are valid
	selectedOption = options[0]

	unit.MoveCharacterToNode(selectedOption.path, selectedOption.tileToMoveTo)
	TryCombat()


func SortOptions(_optA : EnemyAIOption, _optB : EnemyAIOption):
	return _optA.weight > _optB.weight


func TryCombat():
	if selectedOption.targetUnit == null || !selectedOption.canDealDamage:
		unit.QueueEndTurn()
		return

	## default to the first item
	if selectedOption.unitUsable != null && selectedOption.unitUsable.UsableDamageData != null:
		var log = ActionLog.Construct(map.grid, unit, selectedOption.unitUsable)
		log.actionOriginTile = selectedOption.tileToAttack
		log.sourceTile = selectedOption.tileToMoveTo	# Remember, we're pathfinding to this tile so the source has to be from here
		log.affectedTiles.append(selectedOption.targetUnit.CurrentTile.AsTargetData())
		log.damageData = selectedOption.unitUsable.UsableDamageData

		# The unit still needs to get to their destination first, so queue it up as a sequence
		unit.QueueDelayedCombatAction(log)
	else:
		push_error("Unit is attempting to TryCombat with TargetClosest AI, without an Item that does damage")
