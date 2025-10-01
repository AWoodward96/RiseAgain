extends CombatEffectInstance
class_name OnFireEffectInstance

var vfxInstance : FireVFX


func OnEffectApplied():
	if vfxInstance == null:
		vfxInstance = Template.VFX.instantiate() as FireVFX
		vfxInstance.AttachToUnit(AffectedUnit)
		pass
	pass

func OnEffectRemoved():
	if vfxInstance != null:
		vfxInstance.queue_free()
	pass


func OnTurnStart():
	var newPassiveAction = PassiveAbilityAction.Construct(AbilitySource.ownerUnit, AbilitySource) as PassiveAbilityAction
	newPassiveAction.log.actionOriginTile = AffectedUnit.CurrentTile
	var tiles : Array[TileTargetedData]
	tiles.append(AffectedUnit.CurrentTile.AsTargetData())
	newPassiveAction.log.affectedTiles = tiles
	newPassiveAction.log.source = SourceUnit
	newPassiveAction.log.ability = AbilitySource

	var cameraFocusStep = FocusCameraStep.new()
	cameraFocusStep.Instant = false
	newPassiveAction.executionStack.append(cameraFocusStep)


	var delay = DelayStep.new()
	delay.time = 0.5
	newPassiveAction.executionStack.append(delay)

	var createVFX = CreateVFXStep.new()
	createVFX.VFXPrefab = Template.ActivelyOnFire
	createVFX.PositionOnSource = true

	newPassiveAction.executionStack.append(createVFX)

	var combatStep = DealDirectDamageStep.new()
	combatStep.DamageAmount = Template.GetDamageFromStacks(Stacks)
	combatStep.Targeting = CombatEffectTemplate.EEffectTargetType.Targets
	newPassiveAction.executionStack.append(combatStep)

	var secondDelay = DelayStep.new()
	secondDelay.time = 0.5
	newPassiveAction.executionStack.append(secondDelay)

	var expGain = GainExpStep.new()
	newPassiveAction.executionStack.append(expGain)

	newPassiveAction.BuildResults()
	Map.Current.AppendPassiveAction(newPassiveAction)


func ToJSON():
	var dict = super()
	dict["type"] = "OnFireEffectInstance"
	return dict
