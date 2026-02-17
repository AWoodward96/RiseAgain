extends TargetingShapedBase
### Targeting Shaped Free:
## An open targeting system that lets you hit multiple tiles at once with one attack based on a shape
class_name TargetingShapedFree

var lastMoveTimer : float = 0

func BeginTargeting(_log : ActionLog, _ctrl : PlayerController):
	super(_log, _ctrl)
	# we do it like this, because technically for a shaped free targeting, allegiance does not come into play
	# until it comes to dealing damage
	_ctrl.ForceReticlePosition(source.GridPosition)
	log.availableTiles = currentGrid.GetCharacterAttackOptions(source, [source.CurrentTile], TargetRange)
	log.availableTiles.push_front(source.CurrentTile)
	log.affectedTiles.append_array(GetAffectedTiles(source, source.CurrentTile))
	log.actionOriginTile = source.CurrentTile
	ctrl.combatHUD.UpdateTargetingInstructions(true, GetTargetingString(), {})
	ShowPreview()

func HandleInput(_delta):
	# only update when there's input
	if !InputManager.inputAnyDown:
		return

	var reticle = ctrl.reticle
	var tileSize = ctrl.tileSize
	var movementThisFrame = Vector2.ZERO
	if InputManager.inputHeldTimer < InputManager.inputHeldThreshold:
		if InputManager.inputDown[0] : movementThisFrame.y -= 1
		if InputManager.inputDown[1] : movementThisFrame.x += 1
		if InputManager.inputDown[2] : movementThisFrame.y += 1
		if InputManager.inputDown[3] : movementThisFrame.x -= 1

		var newLocation = reticle.global_position + (movementThisFrame * tileSize)
		var tile = currentGrid.GetTile(newLocation / tileSize)
		if log.availableTiles.has(tile):
			reticle.global_position += movementThisFrame * tileSize
			log.actionOriginTile = tile
	else:
		if InputManager.inputHeld[0] : movementThisFrame.y -= 1
		if InputManager.inputHeld[1] : movementThisFrame.x += 1
		if InputManager.inputHeld[2] : movementThisFrame.y += 1
		if InputManager.inputHeld[3] : movementThisFrame.x -= 1

		if lastMoveTimer > InputManager.inputHeldMoveTick:
			var newLocation = reticle.global_position + (movementThisFrame * tileSize)
			var tile = currentGrid.GetTile(newLocation / tileSize)
			if log.availableTiles.has(tile):
				reticle.global_position += movementThisFrame * tileSize
				log.actionOriginTile = tile
			lastMoveTimer = 0

		lastMoveTimer += _delta

	if canRotate:
		if InputManager.bumpInputDown[0] :
			direction = GameSettingsTemplate.RotateDirectionLeft(direction)
		if InputManager.bumpInputDown[1] :
			direction = GameSettingsTemplate.RotateDirectionRight(direction)

	log.actionDirection = direction
	ClearPreview()
	log.affectedTiles.clear()
	log.affectedTiles = GetAffectedTiles(source, log.actionOriginTile, 0, direction)
	ShowPreview()


func ShowAvailableTilesOnGrid():
	currentGrid.ClearActions()
	var isAttack = ability.IsDamage()
	var hitTiles = shapedTiles.GetTargetedTilesFromDirection(source, ability, currentGrid, log.actionOriginTile,  log.actionDirection, 0, stopShapeOnWall)
	for tileData in log.availableTiles:
		tileData.InRange = true

		for target in hitTiles:
			if isAttack:
				target.Tile.CanAttack = true
			else:
				target.Tile.CanBuff = true
	currentGrid.ShowActions()

func GetTargetingString():
	return "ui_targeting_simple"
