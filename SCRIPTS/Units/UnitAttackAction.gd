extends UnitActionBase
class_name UnitAttackAction

var TargetPosition : Vector2
var Log : ActionLog
var ActionIndex : int
var TimerLock : bool
var IsRetaliation : bool = false

func _Enter(_unit : UnitInstance, _map : Map):
	super(_unit, _map)

	unit.affinityIcon.visible = false
	unit.PlayPrepAnimation(TargetPosition - _unit.position)

	var combatResults : Array[PerformCombatStepResult]
	TimerLock = false
	var actions = Log.GetResultsFromActionIndex(ActionIndex)
	for result in actions:
		var combatRes = result as PerformCombatStepResult
		if combatRes == null:
			continue

		if IsRetaliation:
			if combatRes.Target != null && combatRes.RetaliationResult != null:
				combatResults.append(combatRes.RetaliationResult)
		else:
			combatResults.append(combatRes)
		if combatRes.Target == null:
			continue

		combatRes.Target.ShowHealthBar(true)

	await _unit.get_tree().create_timer(Juice.combatSequenceWarmupTimer).timeout

	var focusDelta = 0
	var sourceHealthDelta = 0
	for result in combatResults:
		focusDelta += result.FocusDelta
		sourceHealthDelta += result.SourceHealthDelta

		if result.Target == null:
			# only deal damage to tiles if there's no unit there
			Log.grid.ModifyTileHealth(result.HealthDelta, result.TileTargetData.Tile)

		if result.TileTargetData.Ignite > 0:
			Log.grid.IgniteTile(result.TileTargetData.Tile, result.TileTargetData.Ignite)


	_unit.PlayAttackAnimation(TargetPosition - _unit.position)
	var dst = (TargetPosition - _unit.position).normalized()
	dst = dst * (Juice.combatSequenceAttackOffset * map.TileSize)
	_unit.position += dst

	if sourceHealthDelta != 0:
		# WARNING: I don't actually know the best way to process the source of this effect. Fix this later
		unit.ModifyHealth(sourceHealthDelta, combatResults[0])

	unit.ModifyFocus(focusDelta)
	TimerLock = true

func _Execute(_unit : UnitInstance, delta):
	return ReturnToCenter(_unit, delta) && TimerLock

func ReturnToCenter(_unit, delta):
	var desired = _unit.GridPosition * map.TileSize
	# We should be off center now, move back towards your grid position
	position = lerp(position, (GridPosition * map.TileSize) as Vector2, Juice.combatSequenceReturnToOriginLerp * delta)
	if position.distance_squared_to(desired) < (Juice.combatSequenceReturnToOriginLerp * Juice.combatSequenceReturnToOriginLerp):
		position = desired
		return true

	return false

func _Exit():
	if unit != null:
		unit.PlayAnimation(UnitSettingsTemplate.ANIM_IDLE)

	unit.affinityIcon.visible = true
	pass
