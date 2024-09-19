extends CombatEffectInstance
class_name StatChangeEffectInstance


# There isn't anything in here. The Buffs are stored as children on this object - ideally

func GetEffect():
	return get_child(0) as StatBuff
