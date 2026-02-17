extends TargetingShapedBase
### Targeting Multi Shaped Free
## Same general concept as TargetingShapedFree, but here we can select multiple origin tiles, which need to be tracked
class_name TargetingMultiShapedFree


var hoveredTile : Tile
var selectedTiles : Array[Tile]
var lastMoveTimer : float = 0


func BeginTargeting(_log : ActionLog, _ctrl : PlayerController):
	super(_log, _ctrl)
	# we do it like this, because technically for a shaped free targeting, allegiance does not come into play
	# until it comes to dealing damage
	_ctrl.ForceReticlePosition(source.GridPosition)
	log.availableTiles = currentGrid.GetCharacterAttackOptions(source, [source.CurrentTile], TargetRange)
	log.availableTiles.push_front(source.CurrentTile)
	hoveredTile = source.CurrentTile
	ctrl.combatHUD.UpdateTargetingInstructions(true, GetTargetingString(), {"NUM" = GetMaximumNumberOfTargets() - selectedTiles.size()})
	ShowPreview()

func HandleInput(_delta):
	# only update when there's input
	if !InputManager.inputAnyDown:
		return

	if canRotate:
		if InputManager.bumpInputDown[0] :
			direction = GameSettingsTemplate.RotateDirectionLeft(direction)
		if InputManager.bumpInputDown[1] :
			direction = GameSettingsTemplate.RotateDirectionRight(direction)

	log.actionDirection = direction

	if selectedTiles.size() == GetMaximumNumberOfTargets():
		ctrl.ForceReticlePosition(source.GridPosition)
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
			hoveredTile = tile
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
				hoveredTile = tile
			lastMoveTimer = 0

		lastMoveTimer += _delta


	RefreshPreview()


func RefreshPreview():
	ClearPreview()
	# Standard targeting means it's just one tile being targeted
	# so make the affected tiles the current target tile
	log.affectedTiles.clear()
	for tile in selectedTiles:
		log.affectedTiles.append_array(GetAffectedTiles(source, tile, 0, direction))

	# We do NOT include the hovered tile here until it's selected
	ctrl.combatHUD.UpdateTargetingInstructions(true, GetTargetingString(), {"NUM" = GetMaximumNumberOfTargets() - selectedTiles.size()})
	ShowPreview()

func ShowAvailableTilesOnGrid():
	currentGrid.ClearActions()
	var isAttack = ability.IsDamage()
	var hitTiles : Array[TileTargetedData] = []
	for tile in selectedTiles:
		hitTiles.append_array(shapedTiles.GetTargetedTilesFromDirection(source, ability, currentGrid, tile,  log.actionDirection, 0, stopShapeOnWall))

	if !selectedTiles.has(hoveredTile):
		hitTiles.append_array(shapedTiles.GetTargetedTilesFromDirection(source, ability, currentGrid, hoveredTile, log.actionDirection, 0, stopShapeOnWall))

	for tileData in log.availableTiles:
		tileData.InRange = true

		for target in hitTiles:
			if isAttack:
				target.Tile.CanAttack = true
			else:
				target.Tile.CanBuff = true
	currentGrid.ShowActions()

func OnTileSelected():
	# this is the early exit of this
	if InputManager.startDown && selectedTiles.size() > 0:
		log.actionOriginTile = selectedTiles[0]
		return Validate()

	if selectedTiles.has(hoveredTile):
		return false

	if hoveredTile.IsWall && !CanTargetTerrain:
		return false

	# We don't really care about validating targeting of anything other than this
	# If you need an ability that can only hit Enemies or only hit Allies (and that targeting is enforced)
	# - you should be using a Simple targeting varient
	if TeamTargeting == TargetingDataBase.ETargetingTeamFlag.Empty:
		if hoveredTile.Occupant != null:
			return false


	var maxTargets = GetMaximumNumberOfTargets() # should be overwritten depending on the type of multitargeting
	if selectedTiles.size() < maxTargets:
		selectedTiles.append(hoveredTile)
		RefreshPreview()
		if selectedTiles.size() == maxTargets:
			ctrl.ForceReticlePosition(source.GridPosition)

	return false

func OnCancel():
	if selectedTiles.size() > 0:
		var t = selectedTiles.pop_back()
		ctrl.ForceReticlePosition(t.Position)
		hoveredTile = t
		RefreshPreview()
		return false
	return true


func InherritedValidation():
	if selectedTiles.size() == 0:
		return false

	return true

func GetMaximumNumberOfTargets():
	return 2

func GetTargetingString():
	if selectedTiles.size() >= GetMaximumNumberOfTargets():
		return "ui_targeting_confirmselection"
	return "ui_targeting_selectnumtargets"
