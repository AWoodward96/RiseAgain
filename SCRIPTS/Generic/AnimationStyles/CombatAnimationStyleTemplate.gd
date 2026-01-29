extends AnimationStyleTemplate
class_name CombatAnimationStyleTemplate

# called when the style should deal the damage
signal PerformDamageCallback
@export var HasStandardWindup : bool = true
@export var HasStandardCooloff : bool = true

var isRetaliation : bool = false
var unitTargets : Array[UnitInstance]

func Prepare(_direction : Vector2, _source : UnitInstance, _data):
	super(_direction, _source, _data)
	unitTargets.clear()
	if actionLog != null:
		var results = actionLog.GetResultsFromActionIndex(actionLog.actionStackIndex)
		for r in results:
			var damageStepResult = r as DamageStepResult
			if damageStepResult != null && damageStepResult.Target != null:
				unitTargets.append(damageStepResult.Target)

func Enter():
	super()
	PerformDamageCallback.emit()

func PlayPrepAnimations():
	if source.damage_indicator != null:
		source.damage_indicator.HideCombatClutter()
	source.PlayPrepAnimation(initialDirection)

	var targets = unitTargets
	if isRetaliation:
		targets.clear()
		for retaliationResult in actionLog.responseResults:
			if retaliationResult.Target != null:
				targets.append(retaliationResult.Target)

	for target in targets:
		target.PlayPrepAnimation(initialDirection * Vector2(-1, -1)) # Invert it so that you're looking at your target
		if target.damage_indicator != null:
			target.damage_indicator.HideCombatClutter()


func PlayJuice():
	var crit = false
	var results = actionLog.GetResultsFromActionIndex(actionLog.actionStackIndex)
	for r in results:
		var damageStepResult = r as DamageStepResult
		if damageStepResult != null:
			if damageStepResult.Crit:
				crit = true
				break

	if crit:
		Juice.ScreenShakeCombatCrit()
	else:
		Juice.ScreenShakeCombatStandard()
	Juice.PlayHitRumble()

func PlayVFX_OnSource(_packedVFX: PackedScene):
	if source != null && _packedVFX != null:
		var vfx = _packedVFX.instantiate()
		vfx.position = source.position

	pass

func PlayVFX_OnAffectedTiles(_packedVFX: PackedScene):
	if actionLog == null:
		return

	if actionLog != null && _packedVFX != null:
		for tileTargetData in actionLog.affectedTiles:
			if tileTargetData != null:
				var vfx = _packedVFX.instantiate()
				vfx.position = tileTargetData.Tile.GlobalPosition

	pass

func Exit():
	super()
	source.damage_indicator.ShowCombatClutter()
	for target in unitTargets:
		if !target.IsDying:
			target.damage_indicator.ShowCombatClutter()
