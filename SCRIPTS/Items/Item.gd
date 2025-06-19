extends Node2D
class_name Item

@export_category("Meta Data")
@export var internalName : String
@export var loc_displayName : String
@export var loc_displayDesc : String
@export var icon : Texture2D

@export_category("Item Data")
@export var statData : HeldItemComponent
@export var growthModifierData : HeldItemStatGrowthModifier

var currentMap : Map

func SetMap(_map : Map):
	currentMap = _map

func GetStatDelta(_statTemplate : StatTemplate):
	var delta = 0

	# Get the stats granted by the HeldItemComponent
	if statData != null:
		for stats in statData.StatsToGrant:
			if stats.Template == _statTemplate:
				delta += stats.Value

	return delta

func ToJSON():
	var dict = {
		"prefab" : self.scene_file_path
	}

	if growthModifierData != null:
		dict["ModifierSucceedCount"] = growthModifierData.SuccessCount
	return dict

static func FromJSON(_dict : Dictionary):
	if !_dict.has("prefab") || _dict["prefab"] == "":
		return null

	var item = load(_dict["prefab"]).instantiate() as Item
	if _dict.has("ModifierSucceededCount"):
		item.growthModifierData.SuccessCount = _dict["ModifierSucceededCount"]

	return item
