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
		if Context.canRetaliate && u.IsDefending:
			if u.EquippedItem == null:
				continue

			if u.EquippedItem.ItemDamageData == null:
				continue

			var range = u.EquippedItem.GetRange()
			if range == Vector2i.ZERO:
				continue

			var combatDistance = Context.grid.GetManhattanDistance(Context.sourceCombatTile.Position ,u.GridPosition)
			# so basically, if the weapon this unit is holding, has a max range
			if range.x <= combatDistance && range.y >= combatDistance:
				# okay at this point retaliation is possible
				# oh boy time to make a brand new combat data
				var newData = CombatLog.new()
				newData.Construct(Context.map, u, u.EquippedItem, u.CurrentTile, _unit.CurrentTile)
				newData.targetTiles.append(_unit.CurrentTile)
				# turn off retaliation or else these units will be fighting forever
				newData.canRetaliate = false

				u.QueueAttackSequence(_unit.global_position, newData, [_unit])
				pass

	var dst = (TargetPosition - _unit.position).normalized()
	dst = dst * (Juice.combatSequenceAttackOffset * map.TileSize)
	_unit.position += dst

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

func DamagedEnemiesClear():
	var r = true
	for u in UnitsToTakeDamage:
		if u == null:
			continue

		if !u.IsStackFree:
			r = false
	return r
