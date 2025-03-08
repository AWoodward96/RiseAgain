extends CutsceneEventBase
class_name SmartSelectUnitEvent

@export var Unit : UnitTemplate
@export var Allegience : GameSettingsTemplate.TeamID = GameSettingsTemplate.TeamID.ALLY
@export var UseTutorialReticle : bool = true
@export var ClearReticleAfterEvent : bool = true

var unitInstance : UnitInstance = null
var actionComplete : bool = false

func Enter(_context : CutsceneContext):
	if Map.Current == null:
		return false

	for un : UnitInstance in Map.Current.teams[Allegience]:
		if un.Template == Unit:
			unitInstance = un
			break

	if unitInstance == null:
		return false

	actionComplete = false
	Map.Current.playercontroller.forcedTileSelection = unitInstance.CurrentTile
	Map.Current.playercontroller.ShowTutorialReticle(unitInstance.CurrentTile.Position)
	Map.Current.playercontroller.OnTileSelected.connect(TileSelected)
	return true

func Execute(_delta, _context : CutsceneContext):
	return actionComplete

func TileSelected(_tile : Tile):
	if _tile.Occupant == unitInstance && unitInstance != null:
		actionComplete = true
	pass

func Exit(_context : CutsceneContext):
	if Map.Current != null:
		if Map.Current.playercontroller.OnTileSelected.is_connected(TileSelected):
			Map.Current.playercontroller.OnTileSelected.disconnect(TileSelected)

		if ClearReticleAfterEvent:
			Map.Current.playercontroller.HideTutorialReticle()
