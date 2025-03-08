extends CombatEffectInstance
class_name StunEffectInstance

func OnTurnStart():
	if AffectedUnit != null:
		AffectedUnit.EndTurn()


func ToJSON():
	var dict = super()
	dict["type"] = "StunEffectInstance"
	return dict
