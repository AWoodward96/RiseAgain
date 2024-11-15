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
var createdTileDamagePreview : Array[DamageIndicator]
var unitsWithModifiedVisuals : Array[UnitInstance]

func _Enter(_ctrl : PlayerController, ItemOrAbility):
	super(_ctrl, ItemOrAbility)
	ctrl.reticle.visible = true
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

		log = ActionLog.Construct(currentGrid, source, ItemOrAbility)
		if ItemOrAbility.TargetingData != null:
			targetingData = ItemOrAbility.TargetingData

			match targetingData.Type:
				SkillTargetingData.TargetingType.SelfOnly:
					log.availableTiles = targetingData.GetTilesInRange(source, currentGrid)
					currentTargetTile = source.CurrentTile

				SkillTargetingData.TargetingType.Simple:
					log.availableTiles = targetingData.GetTilesInRange(source, currentGrid)

					var filteredList = []
					for t in log.availableTiles:
						if t.Occupant != null || (t.Occupant == null && t.MaxHealth > 0):
							filteredList.append(t)

					filteredList.sort_custom(func(a : Tile, b : Tile):
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

						return a.Occupant.currentHealth < b.Occupant.currentHealth)

					if filteredList.size() > 0:
						currentTargetTile = filteredList[0]

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
			ShowAffinityRelations(source.Template.Affinity)
			ShowPreview()

func UpdateInput(_delta):
	if targetingData == null:
		return

	match targetingData.Type:
		SkillTargetingData.TargetingType.Simple:
			## Simple is simple. The Initial Targets section of the struct should have all the units already
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
		ShowAffinityRelations(null)
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

	var validSimple = (currentTargetTile.Occupant != null || currentTargetTile.MaxHealth > 0) && targetingData.Type == SkillTargetingData.TargetingType.Simple
	var validShapedFree = targetingData.Type == SkillTargetingData.TargetingType.ShapedFree
	if validSimple || validShapedFree || targetingData.Type == SkillTargetingData.TargetingType.SelfOnly:
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
	ShowAffinityRelations(null)
	ClearPreview()
	pass

func StandardTargetingInput(_delta):
	# Goes through InitialTargets
	if !InputManager.inputAnyDown:
		return

	var filteredList = []
	for t in log.availableTiles:
		if t.Occupant != null || (t.Occupant == null && t.MaxHealth > 0):
			filteredList.append(t)

	if filteredList.size() == 0:
		ctrl.combatHUD.ShowNoTargets(true)
		return

	# The sorting from SkillTargetingComponent is still throwing errors - this line was to get around that - delete if you've fixed the problem
	#filteredList.sort_custom(func(a, b): return (a.Occupant != null && b.Occupant == null))

	ctrl.combatHUD.ShowNoTargets(false)
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

	# Has to come after clear preview
	if log.ContainsPush():
		UpdatePushData(_delta)

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

	if log.ContainsPush():
		UpdatePushData(_delta)
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

func UpdatePushData(_delta):
	for affectedTiles in log.affectedTiles:
		if !affectedTiles.willPush:
			continue

		for stack in affectedTiles.pushStack:
			if stack.Subject == log.source:
				ctrl.movement_tracker.visible = true
				ctrl.movement_preview_sprite.visible = true
				ctrl.movement_tracker.clear_points()
				var positionalOffset = Vector2(currentGrid.CellSize / 2, currentGrid.CellSize / 2)
				var points = PackedVector2Array()
				points.append(stack.Subject.CurrentTile.GlobalPosition + positionalOffset)
				points.append(stack.ResultingTile.GlobalPosition + positionalOffset)
				ctrl.movement_tracker.points = points
				ctrl.movement_preview_sprite.texture = source.Template.icon
				ctrl.movement_preview_sprite.position = points[points.size() - 1]
			else:
				stack.Subject.PreviewModifiedTile(stack.ResultingTile)
				unitsWithModifiedVisuals.append(stack.Subject)

	pass

func ShapedDirectionalTargetingInput(_delta):
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

	var targetTilePosition = source.CurrentTile.Position + GameSettingsTemplate.GetVectorFromDirection(newShaped)
	var newTargetTile = currentGrid.GetTile(targetTilePosition)
	if newTargetTile != null:
		currentTargetTile = currentGrid.GetTile(targetTilePosition)
		shapedDirection = newShaped

	log.affectedTiles = targetingData.GetDirectionalAttack(source, currentGrid, shapedDirection)

	ctrl.ForceReticlePosition(currentTargetTile.Position)

	ShowAvailableTilesOnGrid()
	ShowPreview()

	if log.ContainsPush():
		UpdatePushData(_delta)
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

	for ind in createdTileDamagePreview:
		var parent = ind.get_parent()
		parent.remove_child(ind)
		ind.queue_free()
	createdTileDamagePreview.clear()

	for unit in unitsWithModifiedVisuals:
		unit.ResetVisualToTile()
	unitsWithModifiedVisuals.clear()

func BuildResultsArray():
	log.actionResults.clear()
	# The target tiles is an array so loop through that and append the units to take damage
	for tileData in log.affectedTiles:
		var target = tileData.Tile.Occupant

		if target != null:
			# If we have a target - don't damage allies, only damage who they are supposed to hit
			if log.actionType == ActionLog.ActionType.Item && !log.item.TargetingData.OnCorrectTeam(log.source, target):
				continue

			if log.actionType == ActionLog.ActionType.Ability && !log.ability.TargetingData.OnCorrectTeam(log.source, target):
				continue

		var actionResult = ActionResult.Construct(log.Ability, tileData, log.source, tileData.Tile.Occupant)
		actionResult.PreCalculate()
		log.actionResults.append(actionResult)


func ShowPreview():
	BuildResultsArray()
	ShowCombatPreview()

func ShowCombatPreview():


	pass
	#match targetingData.Type:
		#SkillTargetingData.TargetingType.Simple, SkillTargetingData.TargetingType.SelfOnly:
			#if currentTargetTile != null:
				#var tempTargetData = currentTargetTile.AsTargetData()
				#if currentTargetTile.Occupant != null:
					## Show the damage preview physically on the unit
					## this section is slated for removal if it is deemed to be unnecessary
					#currentTargetTile.Occupant.ShowDamagePreview(source, unitUsable, tempTargetData)
#
					## Ping the CombatHUD to show the damage preview
					#if currentTargetTile.Occupant != null && currentTargetTile.Occupant.Template != null && currentTargetTile.Occupant.Template.Affinity != null:
						#source.ShowAffinityRelation(currentTargetTile.Occupant.Template.Affinity)
#
					#ctrl.combatHUD.ShowDamagePreviewUI(source, unitUsable, currentTargetTile.Occupant, tempTargetData)
				#else:
					## We are targeting a tile without an occupant
					## create a new preview for the tile
					#var preview = Juice.CreateDamageIndicator(currentTargetTile) as DamageIndicator
					#createdTileDamagePreview.append(preview)
					#preview.PreviewDamage(unitUsable, source, tempTargetData, null, currentTargetTile.Health, currentTargetTile.MaxHealth)
#
		#SkillTargetingData.TargetingType.ShapedFree:
			#for targetTileData in shapedTargetingTiles:
				#if targetTileData != null:
					#if targetTileData.Tile.Occupant != null:
						#targetTileData.Tile.Occupant.ShowDamagePreview(source, unitUsable, targetTileData)
						#cachedTargetUnits.append(targetTileData.Tile.Occupant)
					#elif targetTileData.Tile.MaxHealth > 0:
						#var preview = Juice.CreateDamageIndicator(targetTileData.Tile) as DamageIndicator
						#createdTileDamagePreview.append(preview)
						#preview.PreviewDamage(unitUsable, source, targetTileData, null, targetTileData.Tile.Health, targetTileData.Tile.MaxHealth)
#
		#SkillTargetingData.TargetingType.ShapedDirectional:
			#var filteredTiles = targetingData.FilterByTargettingFlags(source, log.affectedTiles)
			#for targetTileData in filteredTiles:
				#if targetTileData.Tile.Occupant != null:
					#targetTileData.Tile.Occupant.ShowDamagePreview(source, unitUsable, targetTileData)
					#cachedTargetUnits.append(targetTileData.Tile.Occupant)
				#elif targetTileData.Tile.MaxHealth > 0:
					#var preview = Juice.CreateDamageIndicator(targetTileData.Tile) as DamageIndicator
					#createdTileDamagePreview.append(preview)
					#preview.PreviewDamage(unitUsable, source, targetTileData, null, targetTileData.Tile.Health, targetTileData.Tile.MaxHealth)
#
			#pass

func ShowHealPreview():
	match targetingData.Type:
		SkillTargetingData.TargetingType.Simple, SkillTargetingData.TargetingType.SelfOnly:
			if currentTargetTile != null && currentTargetTile.Occupant != null:
				# Show the damage preview physically on the unit
				# this section is slated for removal if it is deemed to be unnecessary
				currentTargetTile.Occupant.ShowHealPreview(source, unitUsable, currentTargetTile.AsTargetData())
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

func ShowAffinityRelations(_affinityTemplate : AffinityTemplate):
	if _affinityTemplate == null:
		source.ShowAffinityRelation(null)

	var enemyUnits = currentMap.GetUnitsOnTeam(GameSettingsTemplate.TeamID.ENEMY)
	for units in enemyUnits:
		units.ShowAffinityRelation(_affinityTemplate)

func ToString():
	return "TargetingControllerState"

func ShowInspectUI():
	return false
