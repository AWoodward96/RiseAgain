extends CombatEffectInstance
class_name InvulnerableEffectInstance


func ToJSON():
	var dict = super()
	dict["type"] = "InvulnerableEffectInstance"
	return dict
