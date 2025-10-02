extends ActionStep
class_name PerformCombatStep

@export var useAttackAction : bool = true
@export var useDefendAction : bool = true

var cooloff : float

var waitForActionToFinish : bool
var waitForPostActionToFinish : bool
var affectedTiles : Array[TileTargetedData]


func Enter(_actionLog : ActionLog):
	super(_actionLog)
	cooloff = 0

	#if useAttackAction:
		# The attack will take the log - and will determine who they're 'striking' visually based on the log
	source.QueueAttackSequence(log.actionOriginTile.GlobalPosition, log, useAttackAction, false)

	# The defending units however, need the specific result to take damage from
	var results = log.GetResultsFromActionIndex(log.actionStackIndex)
	for stack in results:
		var subActionRes = null
		var damageStepResult = stack as PerformCombatStepResult
		if damageStepResult == null:
			subActionRes = stack as RepeatStep
			if subActionRes != null:
				if subActionRes.SubStepResult[log.subActionStackIndex] is PerformCombatStepResult:
					damageStepResult = subActionRes.SubStepResult[log.subActionStackIndex] as PerformCombatStepResult



		damageStepResult.RollChance(Map.Current.mapRNG)
		print(damageStepResult.ToString())

		if subActionRes != null:
			subActionRes.ExpGain += damageStepResult.ExpGain

		if damageStepResult.Target != null:
			# ignore any unit that's dying
			if damageStepResult.Target.IsDying:
				damageStepResult.Invalidate()
				continue

			if useDefendAction:
				damageStepResult.Target.QueueDefenseSequence(source.global_position, damageStepResult)

				if damageStepResult.RetaliationResult != null:
					var retaliation = damageStepResult.RetaliationResult
					if retaliation.Source != null && retaliation.Source.currentHealth > 0 && !damageStepResult.Kill:
						log.responseResults.append(retaliation)
						retaliation.RollChance(Map.Current.mapRNG)
						retaliation.Source.QueueAttackSequence(retaliation.Target.global_position, log, true, true)
						retaliation.Target.QueueDefenseSequence(retaliation.Source.global_position, retaliation)
			else:
				damageStepResult.Target.DoCombat(damageStepResult)
	pass

func Execute(_delta):
	if AffectedUnitsClear():
		cooloff += _delta
		return cooloff > Juice.combatSequenceCooloffTimer

	return false

func WillRetaliate(_result : PerformCombatStepResult):
	if CSR.BlockRetaliation:
		return false

	if _result.Source == null:
		return false

	if _result.AbilityData.type == Ability.AbilityType.Standard:
		# This is a normal ability, and no retaliation is available
		return false

	if _result.Kill && _result.AbilityData.type != Ability.AbilityType.Weapon:
		return false

	var defendingUnit = _result.Target
	if defendingUnit == null:
		return false

	if defendingUnit.EquippedWeapon == null:
		return false

	for ce in defendingUnit.CombatEffects:
		if ce is StunEffectInstance:
			return false

	var retaliationWeapon = defendingUnit.EquippedWeapon
	if retaliationWeapon.UsableDamageData == null:
		return false

	var range = defendingUnit.EquippedWeapon.GetRange()
	if range == Vector2i.ZERO:
		return false

	var combatDistance = defendingUnit.map.grid.GetManhattanDistance(_result.SourceTile.Position, defendingUnit.GridPosition)
	# so basically, if the weapon this unit is holding, has a max range
	if range.x <= combatDistance && range.y >= combatDistance:
		return true

	return false

func BuildRetaliationResult(_result : PerformCombatStepResult):
	if WillRetaliate(_result):
		var retaliationResult = ConstructResult(_result.Target.EquippedWeapon, _result.SourceTile.AsTargetData(), _result.Source.CurrentTile, _result.Target, _result.Source, [_result.SourceTile.AsTargetData()])

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

func ConstructResult(_ability : Ability, _tile : TileTargetedData, _sourceTile : Tile, _source : UnitInstance, _target : UnitInstance, _affectedTiles : Array[TileTargetedData]):
	var result = PerformCombatStepResult.new()
	result.AbilityData = _ability
	result.TileTargetData = _tile
	result.Source = _source
	result.Target = _target
	result.SourceTile = _sourceTile
	result.AffectedTiles = _affectedTiles

	result.PreCalculate()

	return result

func GetResults(_actionLog : ActionLog, _affectedTiles : Array[TileTargetedData]):
	var all : Array[PerformCombatStepResult]
	for specificTile in _affectedTiles:
		var returned = ConstructResult(_actionLog.ability, specificTile, _actionLog.sourceTile, _actionLog.source, specificTile.Tile.Occupant, _actionLog.affectedTiles)
		BuildRetaliationResult(returned)
		all.append(returned)
	return all
