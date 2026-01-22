extends TargetingDataBase
### Targeting Simple:
## Your run of the mill fire-emblem style targeting.
## Using the range of the ability, select a target (either a unit or a terrain) to attack or heal
class_name TargetingSimple



## Called when targeting begins
func BeginTargeting(_log : ActionLog, _ctrl : PlayerController):
	super(_log, _ctrl)
	log.availableTiles = GetTilesInRange(source, currentGrid)

	var filteredList = GetStandardTargetingFromAvailableTiles()
	if filteredList.size() > 0:
		log.actionOriginTile = filteredList[0]
		log.affectedTiles.clear()
		log.affectedTiles.append_array(GetAffectedTiles(source, log.actionOriginTile))
	else:
		ShowAvailableTilesOnGrid()
		ctrl.combatHUD.ShowNoTargets(true)
		return

	if log.actionOriginTile == null:
		log.actionOriginTile = log.availableTiles[0]

	ctrl.ForceReticlePosition(log.actionOriginTile.Position)
	ShowPreview()


## Handles the input of this targeting
func HandleInput(_delta):
	# Goes through InitialTargets
	if !InputManager.inputAnyDown:
		return

	var filteredList : Array[Tile] = GetStandardTargetingFromAvailableTiles()
	if filteredList.size() == 0:
		ShowAvailableTilesOnGrid()
		ctrl.combatHUD.ShowNoTargets(true)
		return

	ctrl.combatHUD.ShowNoTargets(false)
	var curIndex = filteredList.find(log.actionOriginTile, 0)
	if InputManager.inputAnyDown:
		var currentTile = filteredList[curIndex]
		var inputDirection : GameSettingsTemplate.Direction

		if InputManager.inputDown[0]:
			inputDirection = GameSettingsTemplate.Direction.Up
		elif InputManager.inputDown[1]:
			inputDirection = GameSettingsTemplate.Direction.Right
		elif InputManager.inputDown[2]:
			inputDirection = GameSettingsTemplate.Direction.Down
		elif InputManager.inputDown[3]:
			inputDirection = GameSettingsTemplate.Direction.Left


		var newTile = currentGrid.GetBestTileFromDirection(currentTile, inputDirection, filteredList)
		if newTile != null:
			var newTileIndex = filteredList.find(newTile)
			if newTileIndex != -1:
				curIndex = newTileIndex



	ClearPreview()
	log.actionOriginTile = filteredList[curIndex]
	# Standard targeting means it's just one tile being targeted
	# so make the affected tiles the current target tile
	log.affectedTiles.clear()
	log.affectedTiles.append_array(GetAffectedTiles(source, log.actionOriginTile))
	ShowPreview()

	ctrl.ForceReticlePosition(log.actionOriginTile.Position)

func GetStandardTargetingFromAvailableTiles():
	var filteredList : Array[Tile] = []
	var unitsFound = []
	for t in log.availableTiles:
		var added = false
		if t.Occupant == null && t.MaxHealth > 0 && t.Health > 0 && CanTargetTerrain:
			filteredList.append(t)
			added = true

		var target = t.Occupant
		if target != null && \
			OnCorrectTeam(TeamTargeting, source, t.Occupant) && \
			# Because some units are bigger than 1x1 and we don't want to count them twice
			!unitsFound.has(target) && \
			!target.ShroudedFromPlayer:
				unitsFound.append(target)
				if !added:
					filteredList.append(t)

	filteredList.sort_custom(SortStandardTargetingOptions)
	return filteredList

func SortStandardTargetingOptions(a : Tile, b : Tile):
	if a == null && b != null:
		return true
	if b == null && a != null:
		return false

	if a.Occupant == null && b.Occupant == null:
		return true

	if a.Occupant != null && b.Occupant == null:
		return true

	if b.Occupant != null && a.Occupant == null:
		return false

	return a.Occupant.currentHealth < b.Occupant.currentHealth

func InherritedValidation():
	# If it's a valid terrain to target - you can target it - full stop
	if log.actionOriginTile.MaxHealth > 0 && log.actionOriginTile.Health > 0 && CanTargetTerrain:
		return true

	# If there's an occupant, but they're shrouded
	# This should be handled by the filter tbh, but it's fine
	if log.actionOriginTile.Occupant != null && log.actionOriginTile.Occupant.ShroudedFromPlayer:
		return false

	return true
