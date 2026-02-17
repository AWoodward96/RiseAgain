extends TargetingDataBase

## Should be abstract, and be overwritten to determine how the multi-selection should work
## This is simply a framework to handle selection across different targeting types
## We're inherriting TargetingSimple, but we're really only concerned with the GetStandardTargetingFromAvailableTiles method
class_name TargetingMultiSimpleBase

var hoveredTile : Tile
var selectedTiles : Array[Tile]
var filteredAvailableTiles : Array[Tile]


## Called when targeting begins
func BeginTargeting(_log : ActionLog, _ctrl : PlayerController):
	super(_log, _ctrl)

	## Very similar to TargetingSimple, but we do a little bit less due to action origin tile not really doing anything
	log.availableTiles = GetTilesInRange(source, currentGrid)

	HoverNextPotentialTarget()
	if filteredAvailableTiles.size() == 0:
		ShowAvailableTilesOnGrid()
		ctrl.combatHUD.ShowNoTargets(true)
		return


	RefreshPreview()

## Handles the input of this targeting
func HandleInput(_delta):
	# Goes through InitialTargets
	if !InputManager.inputAnyDown:
		return

	RefreshTargetList()
	if filteredAvailableTiles.size() == 0:
		ShowAvailableTilesOnGrid()
		ctrl.combatHUD.ShowNoTargets(true)
		return

	if selectedTiles.size() >= GetMaximumNumberOfTargets():
		return

	var inputDirection : GameSettingsTemplate.Direction
	var curIndex = filteredAvailableTiles.find(hoveredTile, 0)

	if InputManager.inputDown[0]:
		inputDirection = GameSettingsTemplate.Direction.Up
	elif InputManager.inputDown[1]:
		inputDirection = GameSettingsTemplate.Direction.Right
	elif InputManager.inputDown[2]:
		inputDirection = GameSettingsTemplate.Direction.Down
	elif InputManager.inputDown[3]:
		inputDirection = GameSettingsTemplate.Direction.Left

	var newTile = currentGrid.GetBestTileFromDirection(hoveredTile, inputDirection, filteredAvailableTiles)
	if newTile != null:
		var newTileIndex = filteredAvailableTiles.find(newTile)
		if newTileIndex != -1:
			curIndex = newTileIndex


	hoveredTile = filteredAvailableTiles[curIndex]
	RefreshPreview()
	ctrl.ForceReticlePosition(hoveredTile.Position)

func RefreshPreview():
	ClearPreview()
	# Standard targeting means it's just one tile being targeted
	# so make the affected tiles the current target tile
	log.affectedTiles.clear()
	for tile in selectedTiles:
		log.affectedTiles.append_array(GetAffectedTiles(source, tile))
	# We do NOT include the hovered tile here until it's selected

	ctrl.combatHUD.UpdateTargetingInstructions(true, GetTargetingString(), {"NUM" = GetMaximumNumberOfTargets() - selectedTiles.size()})

	ShowPreview()


func RefreshTargetList():
	filteredAvailableTiles = GetStandardTargetingFromAvailableTiles()
	filteredAvailableTiles = filteredAvailableTiles.filter(func(tile) : return !selectedTiles.has(tile))


func HoverNextPotentialTarget():
	RefreshTargetList()
	if selectedTiles.size() >= GetMaximumNumberOfTargets():
		ShowAvailableTilesOnGrid()
		ctrl.ForceReticlePosition(source.CurrentTile.Position)
		return

	if filteredAvailableTiles.size() > 0:
		hoveredTile = filteredAvailableTiles[0]
		log.affectedTiles.clear()
		for tile in selectedTiles:
			log.affectedTiles.append_array(GetAffectedTiles(source, tile))
	else:
		ShowAvailableTilesOnGrid()
		ctrl.combatHUD.ShowNoTargets(true)
		ctrl.ForceReticlePosition(source.CurrentTile.Position)
		return

	ctrl.ForceReticlePosition(hoveredTile.Position)

func OnTileSelected():
	# this is the early exit of this
	if InputManager.startDown && selectedTiles.size() > 0:
		log.actionOriginTile = selectedTiles[0]
		return Validate()

	# Select only adds a target. Start (above) is what kicks it off
	var maxTargets = GetMaximumNumberOfTargets() # should be overwritten depending on the type of multitargeting
	if selectedTiles.size() < maxTargets:
		selectedTiles.append(hoveredTile)
		HoverNextPotentialTarget()
		RefreshPreview()

	return false


func InherritedValidation():
	if selectedTiles.size() == 0:
		return false

	return true

## Called when the Controller presses cancel. Sometimes I don't want it to cancel out the entire targeting
# Returns true or false if we want to go all the way back to the context state
func OnCancel():
	if selectedTiles.size() > 0:
		var t = selectedTiles.pop_back()
		ctrl.ForceReticlePosition(t.Position)
		hoveredTile = t
		RefreshPreview()
		return false
	return true

func GetMaximumNumberOfTargets():
	# Defaults to 2, for testing purposes. Remember, this should be inherrited
	return 2

func GetTargetingString():
	if selectedTiles.size() >= GetMaximumNumberOfTargets():
		return "ui_targeting_confirmselection"
	return "ui_targeting_selectnumtargets"
