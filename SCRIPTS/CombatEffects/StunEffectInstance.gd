extends CombatEffectInstance
class_name StunEffectInstance

func OnTurnStart():
	if AffectedUnit != null:
		AffectedUnit.EndTurn()
