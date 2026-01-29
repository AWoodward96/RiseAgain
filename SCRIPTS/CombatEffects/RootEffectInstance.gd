extends CombatEffectInstance
class_name RootEffectInstance

# Handled by the Unit

func ToJSON():
	var dict = super()
	dict["type"] = "RootEffectInstance"
	return dict
