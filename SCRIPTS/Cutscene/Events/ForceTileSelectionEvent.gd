extends CutsceneEventBase
class_name ForceTileSelectionEvent

@export var tileLocation : Vector2i
@export var clear : bool = false
@export var autoUnblockSelectionInput : bool = false

var referencedTile : Tile
var executionComplete = false

func Enter(_context : CutsceneContext):
	if Map.Current == null || Map.Current.playercontroller == null:
		return false

	if clear:
		executionComplete = true
		Map.Current.playercontroller.forcedTileSelection = null
		return true

	referencedTile = Map.Current.grid.GetTile(tileLocation)
	if referencedTile == null:
		push_error("ForceTileSelectionEvent: Could not find a valid tile. Defaulting to accepting")
		return true

	if autoUnblockSelectionInput:
		CutsceneManager.local_block_select_input = false

	executionComplete = false
	Map.Current.playercontroller.forcedTileSelection = referencedTile
	Map.Current.playercontroller.OnTileSelected.connect(TileSelected)
	return true

func Execute(_delta, _context : CutsceneContext):
	return executionComplete

func TileSelected(_tile : Tile):
	if _tile == referencedTile:
		executionComplete = true

func Exit(_context : CutsceneContext):
	if Map.Current.playercontroller.OnTileChanged.is_connected(TileSelected):
		Map.Current.playercontroller.OnTileSelected.disconnect(TileSelected)
	Map.Current.playercontroller.forcedTileSelection = null
