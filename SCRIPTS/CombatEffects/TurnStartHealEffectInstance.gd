extends CombatEffectInstance
class_name TurnStartHealEffectInstance


func OnEffectApplied():
	if Template.HealOnApply:
		DoHeal()

func OnTurnStart():
	DoHeal()
	pass

func DoHeal():
	if AbilitySource.HealData != null:
		if AffectedUnit.currentHealth >= AffectedUnit.maxHealth && !Template.AllowHealAtFull:
			# We might block this because we don't want the turn start to take 30s long if we have a lot of these
			return

		var newPassiveAction = PassiveAbilityAction.Construct(AbilitySource.ownerUnit, AbilitySource) as PassiveAbilityAction
		var tiles : Array[TileTargetedData]
		tiles.append(AffectedUnit.CurrentTile.AsTargetData())
		newPassiveAction.AssignAffectedTiles(AffectedUnit.CurrentTile, tiles)

		newPassiveAction.AddCameraFocusStep()
		newPassiveAction.AddDelayStep()
		newPassiveAction.AddPlayAbilityPopup()
		newPassiveAction.AddDelayStep(0.2)
		newPassiveAction.AddHealStep()

		newPassiveAction.AddDelayStep()
		newPassiveAction.AddGainEXPStep()

		newPassiveAction.BuildResults()
		Map.Current.AppendPassiveAction(newPassiveAction)
		pass
	pass

func DoMod(_val):
	match Template.ScalingModType:
		DamageData.EModificationType.None:
			pass
		DamageData.EModificationType.Additive:
			_val += Template.ScalingMod
		DamageData.EModificationType.Multiplicative:
			_val *= Template.ScalingMod
		DamageData.EModificationType.Divisitive:
			_val /= Template.ScalingMod

	return _val


func ToJSON():
	var dict = super()
	dict["type"] = "TurnStartHealEffectInstance"
	return dict
