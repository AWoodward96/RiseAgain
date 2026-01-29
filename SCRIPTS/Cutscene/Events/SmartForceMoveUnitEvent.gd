extends CutsceneEventBase
class_name SmartForceMoveUnitEvent

@export var unitAtPosition : Vector2i
@export var destination : Vector2i

@export var UseTutorialReticle : bool
@export var ClearReticleOnExit : bool

@export var BlockCancel : bool
@export var BlockInspect : bool

var startingTile : Tile
var endingTile : Tile
var playerController : PlayerController
var Unit : UnitInstance

func Enter(_cutsceneContext : CutsceneContext):
	if Map.Current == null:
		return false

	var tile = Map.Current.grid.GetTile(unitAtPosition)
	var destinationTile = Map.Current.grid.GetTile(destination)
	if tile == null || destinationTile == null || tile.Occupant == null:
		return false

	Unit = tile.Occupant
	startingTile = tile
	endingTile = destinationTile
	playerController = Map.Current.playercontroller

	DoSelection()

	# Gotta turn this off for things to work
	CutsceneManager.local_block_select_input = false
	CutsceneManager.local_block_cancel_input = BlockCancel
	CutsceneManager.local_block_inspect_input = BlockInspect
	return true

func DoSelection():
	playerController.forcedTileSelection = startingTile
	if UseTutorialReticle:
		Map.Current.playercontroller.ShowTutorialReticle(unitAtPosition)
		# Don't hide it if place is false - I can't think of many places where this would be necessary

func DoMovement():
	playerController.forcedTileSelection = endingTile
	if UseTutorialReticle:
		Map.Current.playercontroller.ShowTutorialReticle(endingTile.Position)
		# Don't hide it if place is false - I can't think of many places where this would be necessary


func Execute(_delta, _cutsceneContext : CutsceneContext):
	if playerController == null:
		return false

	if playerController.ControllerState is SelectionControllerState:
		DoSelection()
		return false

	if playerController.ControllerState is UnitMoveControllerState:
		DoMovement()
		return false

	if Unit.CurrentTile == endingTile && Unit.IsStackFree:
		return true
	return false

func Exit(_cutscene : CutsceneContext):
	if Map.Current != null && Map.Current.playercontroller != null && ClearReticleOnExit:
		Map.Current.playercontroller.HideTutorialReticle()
