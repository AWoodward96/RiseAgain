extends AIBehaviorBase
class_name AISmartTarget

@export var Flags : Array[AITargetingFlag]

var options : Array[EnemyAIOption]
var selectedOption : EnemyAIOption
var attacked : bool = false

func StartTurn(_map : Map, _unit : UnitInstance):
	super(_map, _unit)

	options.clear()
	selectedOption = null
	attacked = false

	# STEP ZERO:
	# Check if this enemy even has an ability to use. If they don't, then there's nothing to do
	var hasWeaponToUse = false
	var weaponsAvailableForUse : Array[UnitUsable]
	for a in unit.Abilities:
		if a.type != Ability.AbilityType.Tactical && a.IsDamage():
			weaponsAvailableForUse.append(a)
			hasWeaponToUse = true
			break

	if !hasWeaponToUse:
		unit.QueueEndTurn()
		return

	for i in range(0, Flags.size()):
		var aiflag = Flags[i]
		var filteredUnitsOnTeam = map.GetUnitsOnTeam(aiflag.Team)
		if aiflag.SpecificUnit != null:
			filteredUnitsOnTeam = filteredUnitsOnTeam.filter(func(x) : return x.Template == aiflag.SpecificUnit)

		if aiflag.Descriptor != null:
			filteredUnitsOnTeam = filteredUnitsOnTeam.filter(func(x) : return x.Template.Descriptors.find(aiflag.Descriptor) != -1)

		for u in filteredUnitsOnTeam:
			for weapon in weaponsAvailableForUse:
				var newOption = EnemyAIOption.new()
				newOption.flagIndex = i
				newOption.totalFlags = Flags.size()
				newOption.Update(_unit, u, map, weapon)

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

	# Moved trycombat to the runturn method
	#TryCombat()


func RunTurn():
	if unit.IsStackFree && unit.Activated && !attacked:
		TryCombat()
	pass


func SortOptions(_optA : EnemyAIOption, _optB : EnemyAIOption):
	return _optA.weight > _optB.weight


func TryCombat():
	attacked = true
	if selectedOption.targetUnit == null || !selectedOption.canDealDamage:
		unit.QueueEndTurn()
		return

	## default to the first item
	if selectedOption.ability != null && selectedOption.ability.UsableDamageData != null:
		var log = ActionLog.Construct(map.grid, unit, selectedOption.ability)
		log.actionOriginTile = selectedOption.tileToAttack
		log.sourceTile = selectedOption.tileToMoveTo	# Remember, we're pathfinding to this tile so the source has to be from here
		log.affectedTiles.append_array(selectedOption.tilesHitByAttack)
		log.damageData = selectedOption.ability.UsableDamageData
		log.actionDirection = selectedOption.direction
		log.BuildStepResults()

		# The unit still needs to get to their destination first, so queue it up as a sequence
		unit.QueueDelayedCombatAction(log)
	else:
		push_error("Unit is attempting to TryCombat with TargetClosest AI, without an Item that does damage")
