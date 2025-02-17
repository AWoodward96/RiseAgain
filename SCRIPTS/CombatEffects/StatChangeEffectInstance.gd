extends CombatEffectInstance
class_name StatChangeEffectInstance


# There isn't anything in here. The Buffs are stored as children on this object - ideally

func GetEffects():
	var buffs : Array[StatBuff]
	for child in get_children():
		var castToBuff = child as StatBuff
		if castToBuff != null:
			buffs.append(castToBuff)
	return buffs
