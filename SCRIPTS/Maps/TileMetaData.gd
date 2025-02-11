extends Resource
class_name TileMetaData

@export var Health : int
@export var Killbox : bool
@export var FireSpreadChance : float = 0.5


func OnUnitTraversed(_unitInstance : UnitInstance):
	return false
