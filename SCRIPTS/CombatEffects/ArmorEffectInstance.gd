extends CombatEffectInstance
class_name ArmorEffectInstance

@export var ArmorValue : int


func IsExpired():
	if TurnsRemaining == 0 || ArmorValue <= 0:
		return true
