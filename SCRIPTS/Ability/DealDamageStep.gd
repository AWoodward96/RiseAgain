extends ActionStep
class_name DealDamageStep

@export var useAttackAction : bool = true
@export var useDefendAction : bool = true
@export var damageDataOverride : DamageDataResource

var cooloff : float
var dealtDamage : bool

func Enter(_actionLog : ActionLog):
	super(_actionLog)
	cooloff = 0
	dealtDamage = false

	for damageResult in log.actionResults:
		dealtDamage = true
		var damageData
		if damageDataOverride != null:
			damageData = damageDataOverride
		else:
			damageData = ability.UsableDamageData

		damageResult.Ability_CalculateResult(ability, damageData)

		if useDefendAction:
			damageResult.Target.QueueDefenseSequence(source.global_position, damageResult)
		else:
			damageResult.Target.DoCombat(damageResult)

	if useAttackAction:
		source.QueueAttackSequence(log.actionOriginTile.GlobalPosition, log)
	pass

func Execute(_delta):
	# If we didn't deal damage - just go next
	if !dealtDamage:
		return true

	if log.source.IsStackFree:
		cooloff += _delta
		return cooloff > Juice.combatSequenceCooloffTimer

	return false

func GetDamageBeingDealt(_unitUsable : UnitUsable, _source: UnitInstance, _target : UnitInstance, _targetedTileData : TileTargetedData):
	var damageData
	if damageDataOverride != null:
		damageData = damageDataOverride
	else:
		damageData = _unitUsable.UsableDamageData # Can't get Ability at this point bc it's set in _enter

	return -GameManager.GameSettings.UnitDamageCalculation(_source, _target, damageData, _targetedTileData.AOEMultiplier)
