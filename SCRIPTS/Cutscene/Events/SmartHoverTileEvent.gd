extends CutsceneEventBase
class_name SmartHoverTileEvent

@export var Position : Vector2i
@export var PlaceTutorialReticle : bool
@export var ClearReticleOnExit : bool

@export var BlockSelect : bool
@export var BlockCancel : bool
@export var BlockInspect : bool

var myTile : Tile

func Enter(_cutsceneContext : CutsceneContext):
	if Map.Current == null:
		return false

	var tile = Map.Current.grid.GetTile(Position)
	if tile == null:
		return false

	myTile = tile
	if PlaceTutorialReticle:
		Map.Current.playercontroller.ShowTutorialReticle(Position)
		# Don't hide it if place is false - I can't think of many places where this would be necessary

	CutsceneManager.local_block_select_input = BlockSelect
	CutsceneManager.local_block_cancel_input = BlockCancel
	CutsceneManager.local_block_inspect_input = BlockInspect
	return true

func Execute(_delta, _cutsceneContext : CutsceneContext):
	return Map.Current.playercontroller.CurrentTile == myTile

func Exit(_cutscene : CutsceneContext):
	if Map.Current != null && Map.Current.playercontroller != null && ClearReticleOnExit:
		Map.Current.playercontroller.HideTutorialReticle()
