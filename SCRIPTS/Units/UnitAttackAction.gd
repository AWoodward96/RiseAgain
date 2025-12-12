extends UnitActionBase
class_name UnitAttackAction

var TargetPosition : Vector2
var Log : ActionLog
var ActionIndex : int
var IsRetaliation : bool = false
var TimerLock : bool = false
var AnimationStyle : CombatAnimationStyleTemplate
var combatResults : Array[PerformCombatStepResult]
var damageDealt : bool = false
var retaliationQueued : bool = false

func _Enter(_unit : UnitInstance, _map : Map):
	super(_unit, _map)

	TimerLock = false
	damageDealt = false
	retaliationQueued = false
	unit.damage_indicator.HideCombatClutter()

	if AnimationStyle != null:
		AnimationStyle.isRetaliation = IsRetaliation
		AnimationStyle.Prepare(TargetPosition - _unit.position, _unit, Log)


	combatResults = []
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



	if AnimationStyle == null || (AnimationStyle != null && AnimationStyle.HasStandardWindup):
		await _unit.get_tree().create_timer(Juice.combatSequenceWarmupTimer).timeout

	if AnimationStyle == null:
		PerformDamage()
	else:
		AnimationStyle.PerformDamageCallback.connect(PerformDamage)
		AnimationStyle.Enter()


	# Without a timer lock, Execute starts going off immediately without the combat warmup
	TimerLock = true


func _Execute(_unit : UnitInstance, delta):
	if !TimerLock:
		return false

	if AnimationStyle != null:
		if AnimationStyle.Execute(delta, TargetPosition - unit.position):
			# A little extra code just to ensure that the UnitAttackAction actually deals damage no matter what
			if !damageDealt:
				PerformDamage()
			return true
		else:
			return false

	else:
		# keeping this generic implementation just in case.
		if !damageDealt:
			PerformDamage()
		return ReturnToCenter(_unit, delta)

func ReturnToCenter(_unit, delta):
	if AnimationStyle != null:
		AnimationStyle.PerformDamageCallback.disconnect(PerformDamage)

	var desired = _unit.GridPosition * map.TileSize
	# We should be off center now, move back towards your grid position
	position = lerp(position, (GridPosition * map.TileSize) as Vector2, Juice.combatSequenceReturnToOriginLerp * delta)
	if position.distance_squared_to(desired) < (Juice.combatSequenceReturnToOriginLerp * Juice.combatSequenceReturnToOriginLerp):
		position = desired
		return true

	return false

func PerformDamage():
	damageDealt = true
	var sourceHealthDelta = 0
	for result in combatResults:
		sourceHealthDelta += result.SourceHealthDelta

		if result.Target == null:
			if result.TileTargetData.HitsEnvironment:
				Log.grid.ModifyTileHealth(result.HealthDelta, result.TileTargetData.Tile)
		else:
			result.Target.DoCombat(result)

	if sourceHealthDelta != 0:
		unit.ModifyHealth(sourceHealthDelta, combatResults[0])

#func QueueRetaliation():
	#if !IsRetaliation:
		#if !retaliationQueued:
			#retaliationQueued = true
#
			#for combatRes in combatResults:
				#var retaliation = combatRes.RetaliationResult
				#if retaliation != null && retaliation.Source != null && retaliation.Source.currentHealth > 0 && !combatRes.Kill:
					#retaliation.Source.QueueAttackSequence(retaliation.Target.global_position, Log, retaliation.AbilityData.animationStyle, true)
#
		#pass

func _Exit():
	if unit != null:
		unit.TryPlayIdleAnimation()

	if AnimationStyle != null:
		AnimationStyle.Exit()

pass
