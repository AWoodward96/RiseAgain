extends PlayerControllerState
class_name TargetingControllerState

var targetingData : SkillTargetingData
var source

var log : ActionLog
var currentAbility : Ability
var targetSelected : bool # To lock out double-attacks

func _Enter(_ctrl : PlayerController, _ability):
	super(_ctrl, _ability)
	ctrl.reticle.visible = true
	targetSelected = false

	currentAbility = _ability as Ability

	if currentAbility != null:
		source = currentAbility.ownerUnit

		log = ActionLog.Construct(currentGrid, source, currentAbility)
		if currentAbility.TargetingData != null:
			targetingData = currentAbility.TargetingData

			match targetingData.Type:
				SkillTargetingData.TargetingType.SelfOnly:
					log.availableTiles = targetingData.GetTilesInRange(source, currentGrid)
					log.actionOriginTile = source.CurrentTile
					log.affectedTiles.append(log.actionOriginTile.AsTargetData())

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
						log.actionOriginTile = filteredList[0]
						log.affectedTiles.append(log.actionOriginTile.AsTargetData())

				SkillTargetingData.TargetingType.ShapedFree:
					# we do it like this, because technically for a shaped free targeting, allegiance does not come into play
					# until it comes to dealing damage
					log.availableTiles = currentGrid.GetCharacterAttackOptions(source, [source.CurrentTile], targetingData.TargetRange)
					log.availableTiles.push_front(source.CurrentTile)
					log.affectedTiles.append_array(targetingData.GetAdditionalTileTargets(source, currentGrid, log.availableTiles[0]))
				SkillTargetingData.TargetingType.ShapedDirectional:
					# Shaped directional just uses the dict from the targeting data as the available tiles
					log.actionDirection = GameSettingsTemplate.GetValidDirectional(source.CurrentTile, currentGrid, log.source.facingDirection)
					log.availableTiles = currentGrid.GetAdjacentTiles(source.CurrentTile)
					log.affectedTiles = targetingData.GetDirectionalAttack(source, source.CurrentTile, currentGrid, log.actionDirection)

					# try and get the proper targeted tile based on the facing direction
					var tile = currentGrid.GetTile(log.source.CurrentTile.Position + GameSettingsTemplate.GetVectorFromDirection(log.actionDirection))
					if tile != null:
						log.actionOriginTile = tile
				SkillTargetingData.TargetingType.Global:
					# This attack hits everyone on a specific team
					log.actionDirection = GameSettingsTemplate.GetValidDirectional(source.CurrentTile, currentGrid, log.source.facingDirection)
					var tile = currentGrid.GetTile(log.source.CurrentTile.Position + GameSettingsTemplate.GetVectorFromDirection(log.actionDirection))
					if tile != null:
						log.actionOriginTile = currentGrid.GetTile(tile.Position + GameSettingsTemplate.GetVectorFromDirection(log.actionDirection))

					log.affectedTiles = targetingData.GetGlobalAttack(source, currentMap, log.actionDirection)
					for t in log.affectedTiles:
						log.availableTiles.append(t.Tile)
					#for team in currentMap.teams:
						#for unit : UnitInstance in currentMap.teams[team]:
							#if unit == null:
								#continue
#
							#if targetingData.OnCorrectTeam(source, unit):
								#log.availableTiles.append(unit.CurrentTile)
								#log.affectedTiles.append(unit.CurrentTile.AsTargetData())
					pass

			if log.availableTiles.size() == 0:
				push_error("TargetingControllerState: No available tiles for selected action. Is your targeting script set up properly?")
				return

			if log.actionOriginTile == null:
				log.actionOriginTile = log.availableTiles[0]

			if log.actionOriginTile.Occupant != null:
				ctrl.FocusReticleOnUnit(log.actionOriginTile.Occupant)
			else:
				ctrl.ForceReticlePosition(log.actionOriginTile.Position)
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
		SkillTargetingData.TargetingType.ShapedDirectional, SkillTargetingData.TargetingType.Global:
			# Note that global also uses the shaped directional targeting inpu, so that it contains a direction
			ShapedDirectionalTargetingInput(_delta)
			pass

	if InputManager.selectDown && !targetSelected:
		TileSelected()

	if InputManager.cancelDown:
		ClearPreview()
		ShowAffinityRelations(null)
		ctrl.EnterContextMenuState()

func TileSelected():
	var validSimple = (log.actionOriginTile.Occupant != null || log.actionOriginTile.MaxHealth > 0) && targetingData.Type == SkillTargetingData.TargetingType.Simple
	var validShapedFree = targetingData.Type == SkillTargetingData.TargetingType.ShapedFree
	if validSimple || validShapedFree || targetingData.Type == SkillTargetingData.TargetingType.SelfOnly:
		targetSelected = true
		# This will wait for the previous actions to be complete, and then do the stuff
		source.QueueDelayedCombatAction(log)
	elif targetingData.Type == SkillTargetingData.TargetingType.ShapedDirectional || targetingData.Type == SkillTargetingData.TargetingType.Global:
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

	var filteredList : Array[Tile] = []
	var unitsFound = []
	for t in log.availableTiles:
		if (t.Occupant != null && !unitsFound.has(t.Occupant)) || (t.Occupant == null && t.MaxHealth > 0):
			filteredList.append(t)

			# only allow one unit per target
			if t.Occupant != null:
				unitsFound.append(t.Occupant)

	if filteredList.size() == 0:
		ctrl.combatHUD.ShowNoTargets(true)
		return

	# The sorting from SkillTargetingComponent is still throwing errors - this line was to get around that - delete if you've fixed the problem
	#filteredList.sort_custom(func(a, b): return (a.Occupant != null && b.Occupant == null))

	ctrl.combatHUD.ShowNoTargets(false)
	var curIndex = filteredList.find(log.actionOriginTile, 0)
	#if InputManager.inputDown[0] || InputManager.inputDown[1]:
		#curIndex += 1
		#if curIndex >= filteredList.size():
			#curIndex = 0
#
	#if InputManager.inputDown[2] || InputManager.inputDown[3]:
		#curIndex -= 1
		#if curIndex < 0:
			#curIndex = filteredList.size() - 1
	if InputManager.inputAnyDown:
		var currentTile = filteredList[curIndex]
		var direction : GameSettingsTemplate.Direction

		if InputManager.inputDown[0]:
			direction = GameSettingsTemplate.Direction.Up
		elif InputManager.inputDown[1]:
			direction = GameSettingsTemplate.Direction.Right
		elif InputManager.inputDown[2]:
			direction = GameSettingsTemplate.Direction.Down
		elif InputManager.inputDown[3]:
			direction = GameSettingsTemplate.Direction.Left

		var newTile = currentGrid.GetBestTileFromDirection(currentTile, direction, filteredList)
		if newTile != null:
			var newTileIndex = filteredList.find(newTile)
			if newTileIndex != -1:
				curIndex = newTileIndex



	ClearPreview()
	log.actionOriginTile = filteredList[curIndex]
	# Standard targeting means it's just one tile being targeted
	# so make the affected tiles the current target tile
	log.affectedTiles.clear()
	log.affectedTiles.append(log.actionOriginTile.AsTargetData())
	ShowPreview()

	if log.actionOriginTile.Occupant != null:
		ctrl.FocusReticleOnUnit(log.actionOriginTile.Occupant)
	else:
		ctrl.ForceReticlePosition(log.actionOriginTile.Position)

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

	ClearPreview()
	log.affectedTiles.clear()
	log.affectedTiles = targetingData.GetAdditionalTileTargets(source, currentGrid, log.actionOriginTile)
	ShowAvailableTilesOnGrid()
	ShowPreview()
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
		log.actionOriginTile = currentGrid.GetTile(targetTilePosition)
		log.actionDirection = newShaped

	if targetingData.Type == SkillTargetingData.TargetingType.ShapedDirectional:
		log.affectedTiles = targetingData.GetDirectionalAttack(source, source.CurrentTile, currentGrid, log.actionDirection)
	elif targetingData.Type == SkillTargetingData.TargetingType.Global:
		log.affectedTiles = targetingData.GetGlobalAttack(source, currentMap, log.actionDirection)
		#TBD actually if this does anything special. We already actually have the targeted tiles
		pass

	ctrl.ForceReticlePosition(log.actionOriginTile.Position)

	ShowAvailableTilesOnGrid()
	ShowPreview()
	pass

func ClearPreview():
	if log.actionOriginTile != null && log.actionOriginTile.Occupant != null:
		log.actionOriginTile.Occupant.HideDamagePreview()
		ctrl.combatHUD.ClearDamagePreviewUI()

	for res in log.actionStepResults:
		res.CancelPreview()

	var allPreviews = currentMap.get_tree().get_nodes_in_group("DamageIndicators")
	for preview in allPreviews:
		var previewAsDamageIndicator = preview as DamageIndicator
		if previewAsDamageIndicator != null:
			previewAsDamageIndicator.PreviewCanceled()

func ShowPreview():
	# Filter out the tiles that have incorrect targeting on them
	# The hard removal of specific tiles may not be what we want here - but we'll seeeeeeeeeeeeee
	log.affectedTiles = targetingData.FilterByTargettingFlags(source, log.affectedTiles)
	log.BuildStepResults()

	# TODO: Figure out how this will be displayed via ui
	for result in log.actionStepResults:
		result.PreviewResult(currentMap)

	ShowCombatPreview()


func ShowCombatPreview():
	var allPreviews = currentMap.get_tree().get_nodes_in_group("DamageIndicators")
	for preview in allPreviews:
		var previewAsDamageIndicator = preview as DamageIndicator
		if previewAsDamageIndicator != null:
			previewAsDamageIndicator.SetDisplayStyle(log.ability)
			previewAsDamageIndicator.ShowPreview()
	pass

func ShowAvailableTilesOnGrid():
	currentGrid.ClearActions()
	var isAttack = currentAbility.IsDamage()

	match targetingData.Type:
		SkillTargetingData.TargetingType.Simple:
			for tileData in log.availableTiles:
				if isAttack:
					tileData.CanAttack = true
				else:
					tileData.CanBuff = true

		SkillTargetingData.TargetingType.ShapedFree:
			for tileData in log.availableTiles:
				tileData.InRange = true

			for target in log.affectedTiles:
				if isAttack:
					target.Tile.CanAttack = true
				else:
					target.Tile.CanBuff = true
		SkillTargetingData.TargetingType.ShapedDirectional:
			for targetData in log.affectedTiles:
				if isAttack:
					targetData.Tile.CanAttack = true
				else:
					targetData.Tile.CanBuff = true


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
