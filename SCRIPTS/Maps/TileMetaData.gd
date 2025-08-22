extends Resource
class_name TileMetaData

@export var loc_name : String
@export var Health : int = -1
@export var Killbox : bool
@export var Water : bool
@export var FireSpreadChance : float = 0.5
@export var Shroud : bool = false


func OnUnitTraversed(_unitInstance : UnitInstance):
	return false
