extends CombatEffectInstance
class_name EnergizedEffectInstance

func ToJSON():
	var dict = super()
	dict["type"] = "EnergizedEffectInstance"
	return dict
