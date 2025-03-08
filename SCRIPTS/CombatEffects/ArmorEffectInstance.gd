extends CombatEffectInstance
class_name ArmorEffectInstance

@export var ArmorValue : int


func IsExpired():
	if TurnsRemaining == 0 || ArmorValue <= 0:
		return true

func ToJSON():
	var dict = super()
	dict["type"] = "ArmorEffectInstance"
	dict["ArmorValue"] = ArmorValue
	return dict

func InitFromJSON(_dict, _map : Map):
	super(_dict, _map)
	ArmorValue = int(_dict["ArmorValue"])
