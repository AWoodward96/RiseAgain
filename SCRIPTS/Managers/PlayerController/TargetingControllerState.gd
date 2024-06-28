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
var shapedTargetingTiles : Array[Tile]

func _Enter(_ctrl : PlayerController, ItemOrAbility):
	super(_ctrl, ItemOrAbility)

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
		log.availableTiles = targetingData.GetTilesInRange(source, currentGrid)

		# If the targeting type is shaped free, include the players current tile as an available tile
		if targetingData.Type == SkillTargetingData.TargetingType.ShapedFree:
			log.availableTiles.append(source.CurrentTile)

		currentTargetTile = log.availableTiles[0]
		shapedTargetingTiles = targetingData.GetAdditionalTileTargets(source, currentGrid, currentTargetTile)
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
			pass

	if InputManager.selectDown:
		var validSimple = currentTargetTile.Occupant != null && targetingData.Type == SkillTargetingData.TargetingType.Simple
		var validShapedFree = targetingData.Type == SkillTargetingData.TargetingType.ShapedFree
		if validSimple || validShapedFree:
			log.actionOriginTile = currentTargetTile
			log.affectedTiles = targetingData.GetAdditionalTileTargets(source, currentGrid, currentTargetTile)
			if currentItem != null:
				log.damageData = currentItem.UsableDamageData

			# This will wait for the previous actions to be complete, and then do the stuff
			source.QueueDelayedCombatAction(log)


	if InputManager.cancelDown:
		ClearPreview()
		ctrl.EnterItemSelectionState(ctrl.lastItemFilter)

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

func ClearPreview():
	if currentTargetTile != null && currentTargetTile.Occupant != null:
		currentTargetTile.Occupant.HideDamagePreview()
		ctrl.combatHUD.ClearDamagePreviewUI()

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
				currentTargetTile.Occupant.ShowDamagePreview(source, unitUsable.UsableDamageData)

				# Ping the CombatHUD to show the damage preview
				ctrl.combatHUD.ShowDamagePreviewUI(source, source.EquippedItem, currentTargetTile.Occupant)
		SkillTargetingData.TargetingType.ShapedFree:
			for target in shapedTargetingTiles:
				if target != null && target.Occupant != null:
					target.Occupant.ShowDamagePreview(source, unitUsable.UsableDamageData)
					cachedTargetUnits.append(target.Occupant)
			pass

func ShowHealPreview():
	if currentTargetTile != null && currentTargetTile.Occupant != null:
		# Show the damage preview physically on the unit
		# this section is slated for removal if it is deemed to be unnecessary
		currentTargetTile.Occupant.ShowHealPreview(source, unitUsable.HealData)

func ShowAvailableTilesOnGrid():
	currentGrid.ClearActions()

	match targetingData.Type:
		SkillTargetingData.TargetingType.Simple:
			for tile in log.availableTiles:
				tile.CanAttack = true
		SkillTargetingData.TargetingType.ShapedFree:
			for tile in log.availableTiles:
				tile.InRange = true

			var shapedTargets = shapedTargetingTiles
			for target in shapedTargets:
				target.CanAttack = true

	currentGrid.ShowActions()

func ToString():
	return "TargetingControllerState"

func ShowInspectUI():
	return false
