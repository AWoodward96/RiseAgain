extends PlayerControllerState
class_name TargetingControllerState

var targetingData : SkillTargetingData
var source

var log : ActionLog
var currentItem : Item
var currentAbility : Ability
var unitUsable : UnitUsable
var currentTargetTile : Tile
var cachedTargetUnits : Array[UnitInstance]
var shapedTargetingTiles : Array[TileTargetedData]
var shapedDirection : GameSettingsTemplate.Direction
var targetSelected : bool # To lock out double-attacks
var unitMovement : PackedVector2Array

func _Enter(_ctrl : PlayerController, ItemOrAbility):
	super(_ctrl, ItemOrAbility)
	targetSelected = false
	unitUsable = ItemOrAbility
	# Grid should already be showing the actionable tiles from the Item Selection state
	# That information should be passed here for our selection
	if ItemOrAbility is Item:
		currentItem = ItemOrAbility as Item

	if ItemOrAbility is Ability:
		currentAbility = ItemOrAbility as Ability

	if ItemOrAbility is UnitUsable:
		source = ItemOrAbility.ownerUnit

		targetingData = ItemOrAbility.TargetingData
		log = ActionLog.Construct(source, ItemOrAbility)
		log.grid = currentGrid

		match targetingData.Type:
			SkillTargetingData.TargetingType.Simple:
				log.availableTiles = targetingData.GetTilesInRange(source, currentGrid)
			SkillTargetingData.TargetingType.ShapedFree:
				# we do it like this, because technically for a shaped free targeting, allegiance does not come into play
				# until it comes to dealing damage
				log.availableTiles = currentGrid.GetCharacterAttackOptions(source, [source.CurrentTile], targetingData.TargetRange)
				log.availableTiles.push_front(source.CurrentTile)
				shapedTargetingTiles = targetingData.GetAdditionalTileTargets(source, currentGrid, log.availableTiles[0])
			SkillTargetingData.TargetingType.ShapedDirectional:
				# Shaped directional just uses the dict from the targeting data as the available tiles
				shapedDirection = GameSettingsTemplate.GetValidDirectional(source.CurrentTile, currentGrid, log.source.facingDirection)
				log.availableTiles = currentGrid.GetAdjacentTiles(source.CurrentTile)
				log.affectedTiles = targetingData.GetDirectionalAttack(source, currentGrid, shapedDirection)

				# try and get the proper targeted tile based on the facing direction
				var tile = currentGrid.GetTile(log.source.CurrentTile.Position + GameSettingsTemplate.GetVectorFromDirection(shapedDirection))
				if tile != null:
					currentTargetTile = tile

		if log.availableTiles.size() == 0:
			push_error("TargetingControllerState: No available tiles for selected action. Is your targeting script set up properly?")
			return

		if currentTargetTile == null:
			currentTargetTile = log.availableTiles[0]
		ctrl.ForceReticlePosition(currentTargetTile.Position)
		ShowAvailableTilesOnGrid()
		ShowPreview()


func UpdateInput(_delta):
	if targetingData == null:
		return

	match targetingData.Type:
		SkillTargetingData.TargetingType.Simple:
			# Simple is simple. The Initial Targets section of the struct should have all the units already
			if log.availableTiles[0].Occupant == null:
				reticle.visible = false
				ctrl.combatHUD.ShowNoTargets(true)
			else:
				ctrl.combatHUD.ShowNoTargets(false)
				StandardTargetingInput(_delta)
			pass
		SkillTargetingData.TargetingType.ShapedFree:
			# If it's shaped free, then we don't actually need to select a tile with a target on it
			ShapedFreeTargetingInput(_delta)
			pass
		SkillTargetingData.TargetingType.ShapedDirectional:
			ShapedDirectionalTargetingInput(_delta)
			pass

	if unitUsable.MovementData != null:
		UpdateMoveData(_delta)

	if InputManager.selectDown && !targetSelected:
		TileSelected()

	if InputManager.cancelDown:
		ClearPreview()
		if currentItem != null:
			ctrl.EnterItemSelectionState(ctrl.lastItemFilter)
		else:
			ctrl.EnterContextMenuState()

func TileSelected():
	if unitUsable.MovementData != null && unitMovement != null:
		if unitMovement.size() == 0:
			return
		else:
			log.moveSelf = true

	var validSimple = currentTargetTile.Occupant != null && targetingData.Type == SkillTargetingData.TargetingType.Simple
	var validShapedFree = targetingData.Type == SkillTargetingData.TargetingType.ShapedFree
	if validSimple || validShapedFree:
		log.actionOriginTile = currentTargetTile
		log.affectedTiles = targetingData.GetAdditionalTileTargets(source, currentGrid, currentTargetTile)
		targetSelected = true
		# This will wait for the previous actions to be complete, and then do the stuff
		source.QueueDelayedCombatAction(log)
	elif targetingData.Type == SkillTargetingData.TargetingType.ShapedDirectional:
		log.actionOriginTile = currentTargetTile
		log.actionDirection = shapedDirection
		log.affectedTiles = targetingData.GetDirectionalAttack(source, currentGrid, shapedDirection)
		targetSelected = true
		source.QueueDelayedCombatAction(log)
		pass

func _Exit():
	ClearPreview()
	pass

func StandardTargetingInput(_delta):
	# Goes through InitialTargets
	if !InputManager.inputAnyDown:
		return

	var filteredList = []
	for t in log.availableTiles:
		if t.Occupant != null:
			filteredList.append(t)

	if filteredList.size() == 0:
		return

	var curIndex = filteredList.find(currentTargetTile, 0)
	if InputManager.inputDown[0] || InputManager.inputDown[1]:
		curIndex += 1
		if curIndex >= filteredList.size():
			curIndex = 0

	if InputManager.inputDown[2] || InputManager.inputDown[3]:
		curIndex -= 1
		if curIndex < 0:
			curIndex = filteredList.size() - 1

	ClearPreview()
	currentTargetTile = filteredList[curIndex]
	ShowPreview()

	ctrl.ForceReticlePosition(currentTargetTile.Position)

func ShapedFreeTargetingInput(_delta):
	# only update when there's input
	if !InputManager.inputAnyDown:
		return

	var tileSize = ctrl.tileSize
	movementThisFrame = Vector2.ZERO
	if InputManager.inputHeldTimer < InputManager.inputHeldThreshold:
		if InputManager.inputDown[0] : movementThisFrame.y -= 1
		if InputManager.inputDown[1] : movementThisFrame.x += 1
		if InputManager.inputDown[2] : movementThisFrame.y += 1
		if InputManager.inputDown[3] : movementThisFrame.x -= 1

		var newLocation = reticle.global_position + (movementThisFrame * tileSize)
		var tile = currentGrid.GetTile(newLocation / tileSize)
		if log.availableTiles.has(tile):
			reticle.global_position += movementThisFrame * tileSize
			currentTargetTile = tile
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
				currentTargetTile = tile
			lastMoveTimer = 0

		lastMoveTimer += _delta

	shapedTargetingTiles = targetingData.GetAdditionalTileTargets(source, currentGrid, currentTargetTile)
	ShowAvailableTilesOnGrid()
	ClearPreview()
	ShowPreview()
	pass

func UpdateMoveData(_delta):
	unitMovement = unitUsable.MovementData.PreviewMove(currentGrid, source, currentTargetTile, shapedDirection)
	if unitMovement.size() > 0:
		ctrl.movement_tracker.visible = true
		ctrl.movement_preview_sprite.visible = true

		ctrl.movement_tracker.clear_points()
		ctrl.movement_tracker.points = unitMovement
		ctrl.movement_preview_sprite.texture = source.Template.icon
		ctrl.movement_preview_sprite.position = unitMovement[unitMovement.size() - 1]
	else:
		ctrl.movement_tracker.visible = false
		ctrl.movement_preview_sprite.visible = false
	pass

func ShapedDirectionalTargetingInput(_delta):
	# only update when there's input
	if !InputManager.inputAnyDown:
		return

	var newShaped
	if InputManager.inputDown[0] :
		newShaped = 0
	if InputManager.inputDown[1] :
		newShaped = 1
	if InputManager.inputDown[2] :
		newShaped = 2
	if InputManager.inputDown[3] :
		newShaped = 3

	var targetTilePosition = source.CurrentTile.Position + GameSettingsTemplate.GetVectorFromDirection(newShaped)
	var newTargetTile = currentGrid.GetTile(targetTilePosition)
	if newTargetTile != null:
		currentTargetTile = currentGrid.GetTile(targetTilePosition)
		shapedDirection = newShaped

	log.affectedTiles = targetingData.GetDirectionalAttack(source, currentGrid, shapedDirection)

	ctrl.ForceReticlePosition(currentTargetTile.Position)

	ShowAvailableTilesOnGrid()
	ClearPreview()
	ShowPreview()
	pass

func ClearPreview():
	if currentTargetTile != null && currentTargetTile.Occupant != null:
		currentTargetTile.Occupant.HideDamagePreview()
		ctrl.combatHUD.ClearDamagePreviewUI()

	ctrl.movement_preview_sprite.visible = false
	ctrl.movement_tracker.visible = false
	for u in cachedTargetUnits:
		if u != null:
			u.HideDamagePreview()
	cachedTargetUnits.clear()

func ShowPreview():
	if unitUsable.IsDamage():
		ShowDamagePreview()
	elif unitUsable.IsHeal(false):
		ShowHealPreview()

func ShowDamagePreview():
	match targetingData.Type:
		SkillTargetingData.TargetingType.Simple:
			if currentTargetTile != null && currentTargetTile.Occupant != null:
				# Show the damage preview physically on the unit
				# this section is slated for removal if it is deemed to be unnecessary
				var tempTargetData = currentTargetTile.AsTargetData()
				currentTargetTile.Occupant.ShowDamagePreview(source, unitUsable.UsableDamageData, tempTargetData)

				# Ping the CombatHUD to show the damage preview
				ctrl.combatHUD.ShowDamagePreviewUI(source, source.EquippedItem, currentTargetTile.Occupant, tempTargetData)
		SkillTargetingData.TargetingType.ShapedFree:
			for target in shapedTargetingTiles:
				if target != null && target.Tile.Occupant != null:
					target.Tile.Occupant.ShowDamagePreview(source, unitUsable.UsableDamageData, target)
					cachedTargetUnits.append(target.Tile.Occupant)
		SkillTargetingData.TargetingType.ShapedDirectional:
			var filteredTiles = targetingData.FilterByTargettingFlags(source, log.affectedTiles)
			for target in filteredTiles:
				if target != null && target.Tile.Occupant != null:
					target.Tile.Occupant.ShowDamagePreview(source, unitUsable.UsableDamageData, target)
					cachedTargetUnits.append(target.Tile.Occupant)
			pass

func ShowHealPreview():
	match targetingData.Type:
		SkillTargetingData.TargetingType.Simple:
			if currentTargetTile != null && currentTargetTile.Occupant != null:
				# Show the damage preview physically on the unit
				# this section is slated for removal if it is deemed to be unnecessary
				currentTargetTile.Occupant.ShowHealPreview(source, unitUsable.HealData, currentTargetTile.AsTargetData())
		SkillTargetingData.TargetingType.ShapedFree:
			for target in shapedTargetingTiles:
				if target != null && target.Occupant != null:
					target.Occupant.ShowHealPreview(source, unitUsable.HealData, target)
					cachedTargetUnits.append(target.Occupant)
		SkillTargetingData.TargetingType.ShapedDirectional:
			var filteredTiles = targetingData.FilterByTargettingFlags(source, log.affectedTiles)
			for target in filteredTiles:
				if target != null && target.Occupant != null:
					target.Occupant.ShowHealPreview(source, unitUsable.HealData, target)
					cachedTargetUnits.append(target.Occupant)

func ShowAvailableTilesOnGrid():
	currentGrid.ClearActions()

	match targetingData.Type:
		SkillTargetingData.TargetingType.Simple:
			for tileData in log.availableTiles:
				tileData.CanAttack = true
		SkillTargetingData.TargetingType.ShapedFree:
			for tileData in log.availableTiles:
				tileData.InRange = true

			var shapedTargets = shapedTargetingTiles
			for target in shapedTargets:
				target.Tile.CanAttack = true
		SkillTargetingData.TargetingType.ShapedDirectional:
			for tileData in log.affectedTiles:
				tileData.Tile.CanAttack = true


	currentGrid.ShowActions()

func ToString():
	return "TargetingControllerState"

func ShowInspectUI():
	return false
