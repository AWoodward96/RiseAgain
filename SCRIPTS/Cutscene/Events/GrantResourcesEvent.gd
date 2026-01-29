extends CutsceneEventBase
class_name GrantResourcesEvent

@export var resources : PackedResourceDef
@export var showAquisition : bool = true
@export var tileCoordinate : Vector2i
@export var gridSize : int = 64


func Enter(_context : CutsceneContext):
	PersistDataManager.universeData.AddPackedResources(resources, tileCoordinate * gridSize, showAquisition)
	return true
