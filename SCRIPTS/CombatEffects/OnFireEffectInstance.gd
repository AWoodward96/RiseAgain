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

	var tiles : Array[TileTargetedData]
	tiles.append(AffectedUnit.CurrentTile.AsTargetData())
	newPassiveAction.AssignAffectedTiles(AffectedUnit.CurrentTile, tiles)
	newPassiveAction.AddCameraFocusStep()
	newPassiveAction.AddDelayStep()


	var createVFX = CreateVFXStep.new()
	createVFX.VFXPrefab = Template.ActivelyOnFire
	createVFX.PositionOnSource = true

	newPassiveAction.executionStack.append(createVFX)

	var combatStep = DealDirectDamageStep.new()
	combatStep.DamageAmount = Template.GetDamageFromStacks(Stacks)
	combatStep.Targeting = CombatEffectTemplate.EEffectTargetType.Targets
	newPassiveAction.executionStack.append(combatStep)

	newPassiveAction.AddDelayStep()

	newPassiveAction.AddGainEXPStep()

	newPassiveAction.BuildResults()
	Map.Current.AppendPassiveAction(newPassiveAction)


func ToJSON():
	var dict = super()
	dict["type"] = "OnFireEffectInstance"
	return dict
