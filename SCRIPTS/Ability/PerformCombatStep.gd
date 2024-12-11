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
	var results = log.GetResultsFromActionIndex(log.actionStackIndex)
	for stack in results:
		var damageStepResult = stack as PerformCombatStepResult
		if damageStepResult == null:
			continue

		dealtDamage = true

		damageStepResult.RollChance(Map.Current.rng)

		if damageStepResult.Target != null:
			if useDefendAction:
				damageStepResult.Target.QueueDefenseSequence(source.global_position, damageStepResult)

				if damageStepResult.RetaliationResult != null:
					var retaliation = damageStepResult.RetaliationResult
					if retaliation.Source != null && retaliation.Source.currentHealth > 0 && !damageStepResult.Kill:
						log.responseResults.append(retaliation)
						retaliation.RollChance(Map.Current.rng)
						retaliation.Source.QueueAttackSequence(retaliation.Target.global_position, log)
						retaliation.Target.QueueDefenseSequence(retaliation.Source.global_position, retaliation)
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

func WillRetaliate(_result : PerformCombatStepResult):
	if _result.Source == null:
		return

	if _result.AbilityData.type == Ability.AbilityType.Standard:
		# This is a normal ability, and no retaliation is available
		return

	if _result.Kill:
		return

	var defendingUnit = _result.Target
	if defendingUnit == null:
		return

	if !_result.Kill:
		if defendingUnit.EquippedWeapon == null:
			return

		var retaliationWeapon = defendingUnit.EquippedWeapon
		if retaliationWeapon.UsableDamageData == null:
			return

		var range = defendingUnit.EquippedWeapon.GetRange()
		if range == Vector2i.ZERO:
			return

		var combatDistance = defendingUnit.map.grid.GetManhattanDistance(_result.SourceTile.Position, defendingUnit.GridPosition)
		# so basically, if the weapon this unit is holding, has a max range
		if range.x <= combatDistance && range.y >= combatDistance:
			return true

	return false

func BuildRetaliationResult(_result : PerformCombatStepResult):
	if WillRetaliate(_result):
		var retaliationResult = ConstructResult(_result.Target.EquippedWeapon, _result.SourceTile.AsTargetData(), _result.Source.CurrentTile, _result.Target, _result.Source)

		# This Step Index feels like it should be important, but I'm not sure if it's required to set, or what to set it to.
		# Leaving it commented out for now, but if something breaks somewhere, check the retaliation results index
		#retaliationResult.StepIndex = 0

		_result.RetaliationResult = retaliationResult
		pass

func AffectedUnitsClear():
	var r = true
	for u in log.actionStepResults:
		if u.Target == null:
			continue

		if !u.Target.IsStackFree:
			r = false

	return r

func ConstructResult(_ability : Ability, _tile : TileTargetedData, _sourceTile : Tile, _source : UnitInstance, _target : UnitInstance):
	var result = PerformCombatStepResult.new()
	result.AbilityData = _ability
	result.TileTargetData = _tile
	result.Source = _source
	result.Target = _target
	result.SourceTile = _sourceTile
	result.PreCalculate()
	return result

func GetResult(_actionLog : ActionLog, _specificTile : TileTargetedData):
	var returned = ConstructResult(_actionLog.ability, _specificTile, _actionLog.sourceTile, _actionLog.source, _specificTile.Tile.Occupant)
	BuildRetaliationResult(returned)
	return returned
