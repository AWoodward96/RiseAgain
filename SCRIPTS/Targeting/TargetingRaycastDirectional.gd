extends TargetingShapedBase
class_name TargetingRaycastDirectional

var invalidCast : bool = false

func BeginTargeting(_log : ActionLog, _ctrl : PlayerController):
	super(_log, _ctrl)
	# Shaped directional just uses the dict from the targeting data as the available tiles
	log.actionDirection = GameSettingsTemplate.GetValidDirectional(source.CurrentTile, currentGrid, log.source.facingDirection)
	log.availableTiles = currentGrid.GetAdjacentTiles(source.CurrentTile)

	# try and get the proper targeted tile based on the facing direction
	RaycastToTarget()
	ShowPreview()

func RaycastToTarget():
	var raycastedRange : int = -1
	var range = log.ability.GetRange()
	var directionVector = GameSettingsTemplate.GetVectorFromDirection(log.actionDirection)

	# raycast
	var rangeIndex = range.x
	if range.x > range.y:
		push_error("Range of ability ", log.ability.internalName, " is impossibly set up and cannot be used with TargetingRaycastDirectional. The Y range is less than the X range. Plz Fix")
		return

	while rangeIndex <= range.y:
		var position = log.source.CurrentTile.Position + (directionVector * rangeIndex)
		var tile = currentGrid.GetTile(position)
		log.actionOriginTile = tile

		if OnCorrectTeam(TeamTargeting, source, tile.Occupant) || tile.IsWall:
			raycastedRange = rangeIndex
			break

		rangeIndex += 1

	ctrl.ForceReticlePosition(log.actionOriginTile.Position)
	if raycastedRange == -1:
		invalidCast = true
		ctrl.combatHUD.ShowNoTargets(true)
		return


	ctrl.combatHUD.ShowNoTargets(false)
	invalidCast = false

	log.affectedTiles = GetAffectedTiles(source, log.actionOriginTile, 0, log.actionDirection)
	log.atRange = raycastedRange
	pass

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

	log.actionDirection = newShaped
	RaycastToTarget()
	if !invalidCast:
		ShowPreview()

func InherritedValidation():
	return !invalidCast

func ShowAvailableTilesOnGrid():
	currentGrid.ClearActions()
	var isAttack = ability.IsDamage()

	# We do this because GetAffectedTiles automatically filters out tiles that you can't damage (like allies)
	# We want to draw the shape - REGARDLESS of if you can hit it or not
	var tiles = shapedTiles.GetTargetedTilesFromDirection(source, ability, currentGrid, source.CurrentTile,  log.actionDirection, log.atRange, stopShapeOnWall)
	for targetData in tiles:
		if isAttack:
			targetData.Tile.CanAttack = true
		else:
			targetData.Tile.CanBuff = true
	currentGrid.ShowActions()
