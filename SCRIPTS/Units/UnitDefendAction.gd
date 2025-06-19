extends UnitActionBase
class_name UnitDefendAction

var SourcePosition : Vector2
var tween : Tween

var TimerLock : bool
var Result : DamageStepResult

func _Enter(_unit : UnitInstance, _map : Map):
	super(_unit, _map)

	TimerLock = false
	unit.affinityIcon.visible = false
	unit.PlayPrepAnimation(SourcePosition - position, 1)

	await _unit.get_tree().create_timer(Juice.combatSequenceWarmupTimer).timeout

	var dst = (position - SourcePosition).normalized()
	dst = dst * (Juice.combatSequenceDefenseOffset * map.TileSize)
	position += dst

	TimerLock = true

	_unit.DoCombat(Result)
	if Result.Crit:
		Juice.ScreenShakeCombatCrit()
	else:
		Juice.ScreenShakeCombatStandard()
	Juice.PlayHitRumble()


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
