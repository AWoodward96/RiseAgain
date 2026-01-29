extends Resource
class_name CampaignBlock

# A campaign block holds a set of maps together in one big 'set' of maps
# They should all hold the same tileet and general biome, with the last map of the set being a 'boss' map
# Each campaign block knows where you can move to next - to stop a winter campaign block from moving to a desert block etc etc
@export var mapOptions : Array[MapBlock]
@export_file("*.tres") var nextCampaignBlocks : Array[String]


func GetMapBlock(_index : int):
	return mapOptions[_index % mapOptions.size()]
