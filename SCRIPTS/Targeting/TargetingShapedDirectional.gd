extends TargetingShapedBase
### Targeting Shaped Directional:
## A more restrictive type of targeting that locks the ability into a direction IE Up, Right, Down, or Left
## That attack can hit multiple ties, but has to be cast in one of those directions, centered on the user
class_name TargetingShapedDirectional

var shapedDirectionalRange : int = 0
var prevShapedDirection : int = 0

func BeginTargeting(_log : ActionLog, _ctrl : PlayerController):
	super(_log, _ctrl)
	var range = log.ability.GetRange()
	shapedDirectionalRange = range.x
	# Shaped directional just uses the dict from the targeting data as the available tiles
	log.actionDirection = GameSettingsTemplate.GetValidDirectional(source.CurrentTile, currentGrid, log.source.facingDirection)
	log.availableTiles = currentGrid.GetAdjacentTiles(source.CurrentTile)
	log.affectedTiles.append_array(GetAffectedTiles(source, source.CurrentTile, shapedDirectionalRange, log.actionDirection))
	log.atRange = shapedDirectionalRange
	direction = log.actionDirection

	# try and get the proper targeted tile based on the facing direction
	var adj = currentGrid.GetTile(log.source.CurrentTile.Position + (GameSettingsTemplate.GetVectorFromDirection(log.actionDirection)))
	ctrl.ShowShapedDirectionalHelper(adj, range, log.actionDirection)
	var tile = currentGrid.GetTile(log.source.CurrentTile.Position + (GameSettingsTemplate.GetVectorFromDirection(log.actionDirection) * shapedDirectionalRange))
	if tile != null:
		log.actionOriginTile = tile

	ctrl.ForceReticlePosition(log.actionOriginTile.Position)
	ShowPreview()

func HandleInput(_delta):
	# only update when there's input
	if !InputManager.inputAnyDown:
		return

	ClearPreview()
	var newShaped
	if InputManager.inputDown[0] :
		newShaped = 0
	if InputManager.inputDown[1] :
		newShaped = 1
	if InputManager.inputDown[2] :
		newShaped = 2
	if InputManager.inputDown[3] :
		newShaped = 3

	var range = log.ability.GetRange()
	if newShaped == prevShapedDirection:
		shapedDirectionalRange += 1
		if shapedDirectionalRange > range.y:
			shapedDirectionalRange = range.x

	log.atRange = shapedDirectionalRange
	var targetTilePosition = source.CurrentTile.Position + (GameSettingsTemplate.GetVectorFromDirection(newShaped) * shapedDirectionalRange)
	var newTargetTile = currentGrid.GetTile(targetTilePosition)
	if newTargetTile != null:
		log.actionOriginTile = currentGrid.GetTile(targetTilePosition)
		log.actionDirection = newShaped
		direction = newShaped

	log.affectedTiles.clear()
	log.affectedTiles.append_array(GetAffectedTiles(source, source.CurrentTile, shapedDirectionalRange, log.actionDirection))


	var adjacentTile =  currentGrid.GetTile(source.CurrentTile.Position + (GameSettingsTemplate.GetVectorFromDirection(newShaped)))
	ctrl.ForceReticlePosition(log.actionOriginTile.Position)
	ctrl.ShowShapedDirectionalHelper(adjacentTile, range, newShaped)
	ShowAvailableTilesOnGrid()
	ShowPreview()
	prevShapedDirection = newShaped

func ShowAvailableTilesOnGrid():
	currentGrid.ClearActions()
	var isAttack = ability.IsDamage()

	# We do this because GetAffectedTiles automatically filters out tiles that you can't damage (like allies)
	# We want to draw the shape - REGARDLESS of if you can hit it or not
	var tiles = shapedTiles.GetTargetedTilesFromDirection(source, ability, currentGrid, source.CurrentTile,  log.actionDirection, shapedDirectionalRange, stopShapeOnWall)
	for targetData in tiles:
		if isAttack:
			targetData.Tile.CanAttack = true
		else:
			targetData.Tile.CanBuff = true
	currentGrid.ShowActions()
