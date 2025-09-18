extends CombatEffectInstance
class_name StealthEffectInstance


func ToJSON():
	var dict = super()
	dict["type"] = "StealthEffectInstance"
	return dict
