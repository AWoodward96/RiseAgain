extends ActionStep
class_name PerformCombatStep

@export var useAttackAction : bool = true
@export var useDefendAction : bool = true

var cooloff : float
var dealtDamage : bool

var waitForActionToFinish : bool
var waitForPostActionToFinish : bool

func Enter(_actionLog : ActionLog):
	super(_actionLog)
	cooloff = 0
	dealtDamage = false

	if useAttackAction:
		# The attack will take the log - and will determine who they're 'striking' visually based on the log
		source.QueueAttackSequence(log.actionOriginTile.GlobalPosition, log)

	# The defending units however, need the specific result to take damage from
	var results = log.GetResultsFromActionIndex(log.abilityStackIndex)
	for stack in results:
		var damageStepResult = stack as PerformCombatStepResult
		if damageStepResult == null:
			continue

		dealtDamage = true

		damageStepResult.RollChance(Map.Current.rng)

		if damageStepResult.Target != null:
			if useDefendAction:
				damageStepResult.Target.QueueDefenseSequence(source.global_position, damageStepResult)
				CheckForRetaliation(damageStepResult)
			else:
				damageStepResult.Target.DoCombat(damageStepResult)

	pass

func Execute(_delta):
	# If we didn't deal damage - just go next
	if !dealtDamage:
		return true

	if AffectedUnitsClear():
		cooloff += _delta
		return cooloff > Juice.combatSequenceCooloffTimer

	return false


func CheckForRetaliation(_result : PerformCombatStepResult):
	if log.source == null:
		return

	if log.ability.type == Ability.AbilityType.Standard:
		# This is a normal ability, and no retaliation is available
		return

	var defendingUnit = _result.Target
	if log.canRetaliate && !_result.Kill:
		if defendingUnit.EquippedWeapon == null:
			return

		var retaliationWeapon = defendingUnit.EquippedWeapon
		if retaliationWeapon.UsableDamageData == null:
			return

		var range = defendingUnit.EquippedWeapon.GetRange()
		if range == Vector2i.ZERO:
			return

		var combatDistance = defendingUnit.map.grid.GetManhattanDistance(log.sourceTile.Position, defendingUnit.GridPosition)
		# so basically, if the weapon this unit is holding, has a max range
		if range.x <= combatDistance && range.y >= combatDistance:
			# okay at this point retaliation is possible
			# oh boy time to make a brand new combat data
			var newData = ActionLog.Construct(log.grid, defendingUnit, defendingUnit.EquippedWeapon)
			var tileData = log.source.CurrentTile.AsTargetData()
			newData.affectedTiles.append(tileData)
			# turn off retaliation or else these units will be fighting forever
			newData.canRetaliate = false
			newData.ability = retaliationWeapon

			var retaliationResult = GetResult(newData, tileData)
			retaliationResult.RollChance(Map.Current.rng)

			newData.actionStepResults.append(retaliationResult)
			log.responseResults.append(retaliationResult)

			defendingUnit.QueueAttackSequence(log.source.global_position, newData)
			log.source.QueueDefenseSequence(defendingUnit.global_position, retaliationResult)
			pass

func AffectedUnitsClear():
	var r = true
	for u in log.actionStepResults:
		if u.Target == null:
			continue

		if !u.Target.IsStackFree:
			r = false

	return r

func GetResult(_actionLog : ActionLog, _specificTile : TileTargetedData):
	var result = PerformCombatStepResult.new()
	result.AbilityData = _actionLog.ability
	result.TileTargetData = _specificTile
	result.Source = _actionLog.source
	result.Target = _specificTile.Tile.Occupant
	result.PreCalculate()
	return result
