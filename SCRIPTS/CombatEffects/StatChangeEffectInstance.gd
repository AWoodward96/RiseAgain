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

func ToJSON():
	var dict = super()
	dict["type"] = "StatChangeEffectInstance"

	var buffArray : Array[Dictionary] = []
	for child in get_children():
		var castToBuff = child as StatBuff
		if castToBuff != null:
			buffArray.append(castToBuff.ToJSON())

	dict["StatChanges"] = buffArray
	return dict

func InitFromJSON(_dict, _map : Map):
	super(_dict, _map)
	for dictionary in _dict["StatChanges"]:
		var newBuff = StatBuff.FromJSON(dictionary)
		add_child(newBuff)
