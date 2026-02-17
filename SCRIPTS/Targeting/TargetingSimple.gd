extends TargetingDataBase
### Targeting Simple:
## Your run of the mill fire-emblem style targeting.
## Using the range of the ability, select a target (either a unit or a terrain) to attack or heal
class_name TargetingSimple

var filteredAvailableTiles : Array[Tile]

## Called when targeting begins
func BeginTargeting(_log : ActionLog, _ctrl : PlayerController):
	super(_log, _ctrl)
	log.availableTiles = GetTilesInRange(source, currentGrid)

	filteredAvailableTiles = GetStandardTargetingFromAvailableTiles()
	if filteredAvailableTiles.size() > 0:
		log.actionOriginTile = filteredAvailableTiles[0]
		log.affectedTiles.clear()
		log.affectedTiles.append_array(GetAffectedTiles(source, log.actionOriginTile))
	else:
		ShowAvailableTilesOnGrid()
		ctrl.combatHUD.ShowNoTargets(true)
		return

	if log.actionOriginTile == null:
		log.actionOriginTile = log.availableTiles[0]

	ctrl.ForceReticlePosition(log.actionOriginTile.Position)
	ctrl.combatHUD.UpdateTargetingInstructions(true, GetTargetingString(), {})
	ShowPreview()


## Handles the input of this targeting
func HandleInput(_delta):
	# Goes through InitialTargets
	if !InputManager.inputAnyDown:
		return

	filteredAvailableTiles.clear()
	filteredAvailableTiles = GetStandardTargetingFromAvailableTiles()
	if filteredAvailableTiles.size() == 0:
		ShowAvailableTilesOnGrid()
		ctrl.combatHUD.ShowNoTargets(true)
		return

	ctrl.combatHUD.UpdateTargetingInstructions(true, GetTargetingString(), {})
	var curIndex = filteredAvailableTiles.find(log.actionOriginTile, 0)
	var currentTile = filteredAvailableTiles[curIndex]
	var inputDirection : GameSettingsTemplate.Direction

	if InputManager.inputDown[0]:
		inputDirection = GameSettingsTemplate.Direction.Up
	elif InputManager.inputDown[1]:
		inputDirection = GameSettingsTemplate.Direction.Right
	elif InputManager.inputDown[2]:
		inputDirection = GameSettingsTemplate.Direction.Down
	elif InputManager.inputDown[3]:
		inputDirection = GameSettingsTemplate.Direction.Left


	var newTile = currentGrid.GetBestTileFromDirection(currentTile, inputDirection, filteredAvailableTiles)
	if newTile != null:
		var newTileIndex = filteredAvailableTiles.find(newTile)
		if newTileIndex != -1:
			curIndex = newTileIndex


	ClearPreview()
	log.actionOriginTile = filteredAvailableTiles[curIndex]
	# Standard targeting means it's just one tile being targeted
	# so make the affected tiles the current target tile
	log.affectedTiles.clear()
	log.affectedTiles.append_array(GetAffectedTiles(source, log.actionOriginTile))
	ShowPreview()

	ctrl.ForceReticlePosition(log.actionOriginTile.Position)



func InherritedValidation():
	# If it's a valid terrain to target - you can target it - full stop
	if log.actionOriginTile.MaxHealth > 0 && log.actionOriginTile.Health > 0 && CanTargetTerrain:
		return true

	# If there's an occupant, but they're shrouded
	# This should be handled by the filter tbh, but it's fine
	if log.actionOriginTile.Occupant != null && log.actionOriginTile.Occupant.ShroudedFromPlayer:
		return false

	return true

func GetTargetingString():
	return "ui_targeting_simple"
