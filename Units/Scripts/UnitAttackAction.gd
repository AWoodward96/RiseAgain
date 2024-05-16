extends UnitActionBase
class_name UnitAttackAction

var TargetPosition : Vector2
var Context : CombatLog
var UnitsToTakeDamage : Array[UnitInstance]
var TimerLock : bool

func _Enter(_unit : UnitInstance, _map : Map):
	super(_unit, _map)

	TimerLock = false
	for u in UnitsToTakeDamage:
		u.ShowHealthBar(true)

	await _unit.get_tree().create_timer(Juice.combatSequenceWarmupTimer).timeout

	for u in UnitsToTakeDamage:
		u.QueueDefenseSequence(_unit.position, Context, _unit)

	var dst = (TargetPosition - _unit.position).normalized()
	dst = dst * (Juice.combatSequenceAttackOffset * map.TileSize)
	_unit.position += dst

	TimerLock = true

func _Execute(_unit : UnitInstance, delta):
	return ReturnToCenter(_unit, delta) && DamagedEnemiesClear() && TimerLock

func ReturnToCenter(_unit, delta):
	var desired = _unit.GridPosition * map.TileSize
	# We should be off center now, move back towards your grid position
	position = lerp(position, (GridPosition * map.TileSize) as Vector2, Juice.combatSequenceReturnToOriginLerp * delta)
	if position.distance_squared_to(desired) < (Juice.combatSequenceReturnToOriginLerp * Juice.combatSequenceReturnToOriginLerp):
		position = desired
		return true

	return false

func DamagedEnemiesClear():
	var r = true
	for u in UnitsToTakeDamage:
		if u == null:
			continue

		if !u.IsStackFree:
			r = false
	return r
