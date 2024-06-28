extends UnitActionBase
class_name UnitAttackAction

var TargetPosition : Vector2
var Log : ActionLog
var TimerLock : bool

func _Enter(_unit : UnitInstance, _map : Map):
	super(_unit, _map)

	TimerLock = false
	for res in Log.actionResults:
		if res.Target == null:
			continue
		res.Target.ShowHealthBar(true)

	await _unit.get_tree().create_timer(Juice.combatSequenceWarmupTimer).timeout

	var focusDelta = 0
	var sourceHealthDelta = 0
	for result in Log.actionResults:
		if result.Target == null:
			continue
		focusDelta += result.FocusDelta
		sourceHealthDelta += result.SourceHealthDelta

	var dst = (TargetPosition - _unit.position).normalized()
	dst = dst * (Juice.combatSequenceAttackOffset * map.TileSize)
	_unit.position += dst

	if sourceHealthDelta != 0:
		unit.ModifyHealth(sourceHealthDelta)

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
