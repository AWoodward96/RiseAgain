extends TargetingDataBase
### Targeting Summon Grid Entity Directional
## This is a two part targeting type.
## Part 1: Using TargetingDataBases TeamTargeting, teleport to a tile that is adjacent to a unit within range. This tile becomes action origin
## Part 2: Using TargetingTeleportAjacents ActionTeamTargeting flag, mark that tile as an affected tile and affect them.
class_name TargetingTeleportAdjacent

enum ETargetingTeleportAdjacentState { TargetTeleport, TargetAction }
@export var ActionTeamTargeting : TargetingDataBase.ETargetingTeamFlag

var State : ETargetingTeleportAdjacentState
var TeleportAvailables : Array[Tile]
var ActionAvailables : Array[Tile]
var PrevTeleportTile : Tile


func BeginTargeting(_log : ActionLog, _ctrl : PlayerController):
	super(_log, _ctrl)
	PrevTeleportTile = null
	EnterTargetTeleport()

func EnterTargetTeleport():
	log.affectedTiles.clear()
	ClearPreview()

	State = ETargetingTeleportAdjacentState.TargetTeleport
	TeleportAvailables = GetTilesInRange(source, currentGrid)
	log.availableTiles = TeleportAvailables

	if PrevTeleportTile != null:
		ctrl.ForceReticlePosition(PrevTeleportTile.Position)
	else:
		if TeleportAvailables.size() > 0:
			log.actionOriginTile = TeleportAvailables[0]
			ctrl.ForceReticlePosition(TeleportAvailables[0].Position)

	if TeleportAvailables.size() == 0:
		ShowAvailableTilesOnGrid()
		ctrl.combatHUD.ShowNoTargets(true)
	else:
		ShowPreview()

func EnterTargetAction():
	ClearPreview()

	State = ETargetingTeleportAdjacentState.TargetAction
	GetAvailableTilesForAction()

	# This is pretty safe. The former state basically garuntees that ActionAvailable tiles can never be null
	# So this clears
	log.availableTiles = ActionAvailables
	ctrl.ForceReticlePosition(ActionAvailables[0].Position)
	log.affectedTiles.clear()
	log.affectedTiles.append_array(GetAffectedTiles(source, ActionAvailables[0]))

	if ActionAvailables.size() == 0:
		ShowAvailableTilesOnGrid()
		ctrl.combatHUD.ShowNoTargets(true)
	else:
		ShowPreview()

	pass

func GetTilesInRange(_unit : UnitInstance, _grid : Grid):
	var options : Array[Tile]
	var tilesInRange : Array[Tile]
	tilesInRange = _grid.GetCharacterAttackOptions(_unit, [_unit.CurrentTile], TargetRange)
	for t in tilesInRange:
		if t.Occupant != null && OnCorrectTeam(TeamTargeting, source, t.Occupant):
			if t.Occupant == source && !CanTargetSelf:
				continue

			var adjacentTiles = currentGrid.GetAdjacentTiles(t)
			for a in adjacentTiles:
				if options.has(a) || a.Occupant != null || a.ActiveKillbox:
					continue
				options.append(a)

	return options

func GetAvailableTilesForAction():
	# Take the action origin tile, get adjacent tiles, filter for targeting, badaboom
	ActionAvailables.clear()
	var adjacentToOrigin = currentGrid.GetAdjacentTiles(log.actionOriginTile)
	for t in adjacentToOrigin:
		if t.Occupant != null && t.Occupant != source && OnCorrectTeam(ActionTeamTargeting, source, t.Occupant):
			ActionAvailables.append(t)


## Handles the input of this targeting
func HandleInput(_delta):
	# Goes through InitialTargets
	if !InputManager.inputAnyDown:
		return

	var targetingAvailableTiles : Array[Tile]
	if State == ETargetingTeleportAdjacentState.TargetTeleport:
		targetingAvailableTiles = TeleportAvailables
	else:
		targetingAvailableTiles = ActionAvailables

	log.availableTiles = targetingAvailableTiles
	if targetingAvailableTiles.size() == 0:
		ShowAvailableTilesOnGrid()
		ctrl.combatHUD.ShowNoTargets(true)
		return

	ctrl.combatHUD.ShowNoTargets(false)
	var curIndex = targetingAvailableTiles.find(log.actionOriginTile, 0)
	if InputManager.inputAnyDown:
		var currentTile = targetingAvailableTiles[curIndex]
		var inputDirection : GameSettingsTemplate.Direction

		if InputManager.inputDown[0]:
			inputDirection = GameSettingsTemplate.Direction.Up
		elif InputManager.inputDown[1]:
			inputDirection = GameSettingsTemplate.Direction.Right
		elif InputManager.inputDown[2]:
			inputDirection = GameSettingsTemplate.Direction.Down
		elif InputManager.inputDown[3]:
			inputDirection = GameSettingsTemplate.Direction.Left


		var newTile = currentGrid.GetBestTileFromDirection(currentTile, inputDirection, targetingAvailableTiles)
		if newTile != null:
			var newTileIndex = targetingAvailableTiles.find(newTile)
			if newTileIndex != -1:
				curIndex = newTileIndex


	ClearPreview()
	if State == ETargetingTeleportAdjacentState.TargetTeleport:
		log.actionOriginTile = targetingAvailableTiles[curIndex]
	else:
		log.affectedTiles.clear()
		log.affectedTiles.append_array(GetAffectedTiles(source, targetingAvailableTiles[curIndex]))
	ShowPreview()

	ctrl.ForceReticlePosition(targetingAvailableTiles[curIndex].Position)

## Called when the Controller presses confirm on a tile. Should return a true or a false value depending on if we can execute or not
# This is in here because some targeting systems need to know when select is down
func OnTileSelected():
	if State == ETargetingTeleportAdjacentState.TargetTeleport:
		PrevTeleportTile = log.actionOriginTile
		EnterTargetAction()
		return false
	return Validate()

## Called when the Controller presses cancel. Sometimes I don't want it to cancel out the entire targeting
# Returns true or false if we want to go all the way back to the context state
func OnCancel():
	if State == ETargetingTeleportAdjacentState.TargetAction:
		EnterTargetTeleport()
		return false
	return true
