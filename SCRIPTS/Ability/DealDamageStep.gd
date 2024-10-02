extends ActionStep
class_name DealDamageStep

@export var useAttackAction : bool = true
@export var useDefendAction : bool = true
@export var damageDataOverride : DamageDataResource

var cooloff : float
var dealtDamage : bool

var waitForActionToFinish : bool
var waitForPostActionToFinish : bool

func Enter(_actionLog : ActionLog):
	super(_actionLog)
	cooloff = 0
	dealtDamage = false

	if useAttackAction:
		source.QueueAttackSequence(log.actionOriginTile.GlobalPosition, log)

	for damageResult in log.actionResults:
		dealtDamage = true
		var damageData
		if damageDataOverride != null:
			damageData = damageDataOverride
		else:
			damageData = ability.UsableDamageData

		damageResult.Ability_CalculateResult(ability, damageData)

		if damageResult.Target != null:
			if useDefendAction:
				damageResult.Target.QueueDefenseSequence(source.global_position, damageResult)
				CheckForRetaliation(damageResult)
			else:
				damageResult.Target.DoCombat(damageResult)

	pass

func Execute(_delta):
	# If we didn't deal damage - just go next
	if !dealtDamage:
		return true

	if AffectedUnitsClear():
		cooloff += _delta
		return cooloff > Juice.combatSequenceCooloffTimer

	return false


func CheckForRetaliation(_result : ActionResult):
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
			newData.affectedTiles.append(log.source.CurrentTile.AsTargetData())
			# turn off retaliation or else these units will be fighting forever
			newData.canRetaliate = false
			newData.ability = retaliationWeapon

			var retaliationResult = ActionResult.new()
			retaliationResult.Source = defendingUnit
			retaliationResult.Target = log.source
			retaliationResult.TileTargetData = log.source.CurrentTile.AsTargetData()
			retaliationResult.Ability_CalculateResult(retaliationWeapon, retaliationWeapon.UsableDamageData)

			newData.actionResults.append(retaliationResult)
			log.responseResults.append(retaliationResult)

			defendingUnit.QueueAttackSequence(log.source.global_position, newData)
			log.source.QueueDefenseSequence(defendingUnit.global_position, retaliationResult)
			pass

func AffectedUnitsClear():
	var r = true
	for u in log.actionResults:
		if u.Target == null:
			continue

		if !u.Target.IsStackFree:
			r = false

	return r

func GetDamageBeingDealt(_unitUsable : UnitUsable, _source: UnitInstance, _target : UnitInstance, _targetedTileData : TileTargetedData):
	var damageData
	if damageDataOverride != null:
		damageData = damageDataOverride
	else:
		damageData = _unitUsable.UsableDamageData # Can't get Ability at this point bc it's set in _enter

	return -GameManager.GameSettings.DamageCalculation(_source, _target, damageData, _targetedTileData.AOEMultiplier)
