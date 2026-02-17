extends PlayerControllerState
class_name TargetingControllerState

var source
var log : ActionLog
var currentAbility : Ability
var targetingTemplate : TargetingDataBase
var targetSelected : bool # To lock out double-attacks

#--var shapedDirectionalRange : int = 0
#--var prevShapedDirection : int


func _Enter(_ctrl : PlayerController, _ability):
	super(_ctrl, _ability)
	ctrl.reticle.visible = true
	targetSelected = false
	currentAbility = _ability as Ability
	source = currentAbility.ownerUnit
	log = ActionLog.Construct(currentGrid, source, _ability)

	if currentAbility.TargetingTemplate != null:
		targetingTemplate = currentAbility.TargetingTemplate
		targetingTemplate.BeginTargeting(log, ctrl)

func UpdateInput(_delta):
	if targetingTemplate != null:
		targetingTemplate.HandleInput(_delta)


	if (InputManager.selectDown || InputManager.startDown) && !targetSelected:
		if targetingTemplate != null:
			if targetingTemplate.OnTileSelected():
				TileSelected()


	if InputManager.cancelDown:
		if CutsceneManager.BlockCancelInput:
			return

		if targetingTemplate != null:
			if targetingTemplate.OnCancel():
				ctrl.EnterContextMenuState()
		else:
			ctrl.EnterContextMenuState()

func TileSelected():
	if log.actionOriginTile == null:
		push_error("Targeting failed to define an ActionOriginTile")
		return

	targetSelected = true
	# This will wait for the previous actions to be complete, and then do the stuff
	source.QueueDelayedCombatAction(log)
	AudioManager.RaiseIntensity(3)

	ctrl.OnTileSelected.emit(log.actionOriginTile)

func _Exit():
	if targetingTemplate != null:
		targetingTemplate.EndTargeting()

	pass

#func StandardTargetingInput(_delta):
	## Goes through InitialTargets
	#if !InputManager.inputAnyDown:
		#return
#
	#var filteredList : Array[Tile] = []
	#var unitsFound = []
	#for t in log.availableTiles:
		#if (t.Occupant != null && !unitsFound.has(t.Occupant) && !t.Occupant.ShroudedFromPlayer) || (t.Occupant == null && t.MaxHealth > 0):
			#filteredList.append(t)
#
			## only allow one unit per target
			#if t.Occupant != null:
				#unitsFound.append(t.Occupant)
#
	#if filteredList.size() == 0:
		#ctrl.combatHUD.ShowNoTargets(true)
		#return
#
	## The sorting from SkillTargetingComponent is still throwing errors - this line was to get around that - delete if you've fixed the problem
	##filteredList.sort_custom(func(a, b): return (a.Occupant != null && b.Occupant == null))
#
	#ctrl.combatHUD.ShowNoTargets(false)
	#var curIndex = filteredList.find(log.actionOriginTile, 0)
	#if InputManager.inputAnyDown:
		#var currentTile = filteredList[curIndex]
		#var direction : GameSettingsTemplate.Direction
#
		#if InputManager.inputDown[0]:
			#direction = GameSettingsTemplate.Direction.Up
		#elif InputManager.inputDown[1]:
			#direction = GameSettingsTemplate.Direction.Right
		#elif InputManager.inputDown[2]:
			#direction = GameSettingsTemplate.Direction.Down
		#elif InputManager.inputDown[3]:
			#direction = GameSettingsTemplate.Direction.Left
#
		#var newTile = currentGrid.GetBestTileFromDirection(currentTile, direction, filteredList)
		#if newTile != null:
			#var newTileIndex = filteredList.find(newTile)
			#if newTileIndex != -1:
				#curIndex = newTileIndex
#
#
	#ClearPreview()
	#log.actionOriginTile = filteredList[curIndex]
	## Standard targeting means it's just one tile being targeted
	## so make the affected tiles the current target tile
	#log.affectedTiles.clear()
	#log.affectedTiles.append(log.actionOriginTile.AsTargetData())
	#ShowPreview()
#
	#if log.actionOriginTile.Occupant != null:
		#ctrl.FocusReticleOnUnit(log.actionOriginTile.Occupant)
	#else:
		#ctrl.ForceReticlePosition(log.actionOriginTile.Position)
#
#func ShapedFreeTargetingInput(_delta):
	## only update when there's input
	#if !InputManager.inputAnyDown:
		#return
#
	#var tileSize = ctrl.tileSize
	#movementThisFrame = Vector2.ZERO
	#if InputManager.inputHeldTimer < InputManager.inputHeldThreshold:
		#if InputManager.inputDown[0] : movementThisFrame.y -= 1
		#if InputManager.inputDown[1] : movementThisFrame.x += 1
		#if InputManager.inputDown[2] : movementThisFrame.y += 1
		#if InputManager.inputDown[3] : movementThisFrame.x -= 1
#
		#var newLocation = reticle.global_position + (movementThisFrame * tileSize)
		#var tile = currentGrid.GetTile(newLocation / tileSize)
		#if log.availableTiles.has(tile):
			#reticle.global_position += movementThisFrame * tileSize
			#log.actionOriginTile = tile
	#else:
		#if InputManager.inputHeld[0] : movementThisFrame.y -= 1
		#if InputManager.inputHeld[1] : movementThisFrame.x += 1
		#if InputManager.inputHeld[2] : movementThisFrame.y += 1
		#if InputManager.inputHeld[3] : movementThisFrame.x -= 1
#
		#if lastMoveTimer > InputManager.inputHeldMoveTick:
			#var newLocation = reticle.global_position + (movementThisFrame * tileSize)
			#var tile = currentGrid.GetTile(newLocation / tileSize)
			#if log.availableTiles.has(tile):
				#reticle.global_position += movementThisFrame * tileSize
				#log.actionOriginTile = tile
			#lastMoveTimer = 0
#
		#lastMoveTimer += _delta
#
	#ClearPreview()
	#log.affectedTiles.clear()
	#log.affectedTiles = targetingData.GetAdditionalTileTargets(source, currentGrid, log.actionOriginTile)
	#ShowAvailableTilesOnGrid()
	#ShowPreview()
	#pass
#
#
#func ShapedDirectionalTargetingInput(_delta):
	## only update when there's input
	#if !InputManager.inputAnyDown:
		#return
#
	#ClearPreview()
	#var newShaped
	#if InputManager.inputDown[0] :
		#newShaped = 0
	#if InputManager.inputDown[1] :
		#newShaped = 1
	#if InputManager.inputDown[2] :
		#newShaped = 2
	#if InputManager.inputDown[3] :
		#newShaped = 3
#
	#var range = log.ability.GetRange()
	#if newShaped == prevShapedDirection:
		#shapedDirectionalRange += 1
		#if shapedDirectionalRange > range.y:
			#shapedDirectionalRange = range.x
#
	#log.atRange = shapedDirectionalRange
	#var targetTilePosition = source.CurrentTile.Position + (GameSettingsTemplate.GetVectorFromDirection(newShaped) * shapedDirectionalRange)
	#var newTargetTile = currentGrid.GetTile(targetTilePosition)
	#if newTargetTile != null:
		#log.actionOriginTile = currentGrid.GetTile(targetTilePosition)
		#log.actionDirection = newShaped
#
	#if targetingData.Type == SkillTargetingData.TargetingType.ShapedDirectional:
		#log.affectedTiles = targetingData.GetDirectionalAttack(source, log.ability, source.CurrentTile, shapedDirectionalRange, currentGrid, log.actionDirection)
	#elif targetingData.Type == SkillTargetingData.TargetingType.Global:
		#log.affectedTiles = targetingData.GetGlobalAttack(source, currentMap, log.actionDirection)
		##TBD actually if this does anything special. We already actually have the targeted tiles
		#pass
#
#
	#var adjacentTile =  currentGrid.GetTile(source.CurrentTile.Position + (GameSettingsTemplate.GetVectorFromDirection(newShaped)))
	#ctrl.ForceReticlePosition(log.actionOriginTile.Position)
	#ctrl.ShowShapedDirectionalHelper(adjacentTile, range, newShaped)
	#ShowAvailableTilesOnGrid()
	#ShowPreview()
	#prevShapedDirection = newShaped
	#pass

## TODO: Remove - duped in TargetingDataBase
#func ClearPreview():
	#if log.actionOriginTile != null && log.actionOriginTile.Occupant != null:
		#log.actionOriginTile.Occupant.HideDamagePreview()
#
	#ctrl.ClearShapedDirectionalHelper()
#
	#for res in log.actionStepResults:
		#res.CancelPreview()
#
	#var allPreviews = currentMap.get_tree().get_nodes_in_group("DamageIndicators")
	#for preview in allPreviews:
		#var previewAsDamageIndicator = preview as DamageIndicator
		#if previewAsDamageIndicator != null:
			#previewAsDamageIndicator.PreviewCanceled()
#
#
## TODO: Remove - Duped in TargetingDataBase
#func ShowPreview():
	## Filter out the tiles that have incorrect targeting on them
	## The hard removal of specific tiles may not be what we want here - but we'll seeeeeeeeeeeeee
	#log.affectedTiles = SkillTargetingData.FilterByTargettingFlags(targetingData.Type, targetingData.TeamTargeting, targetingData.CanTargetSelf, source, log.affectedTiles)
	#log.BuildStepResults()
#
	## Preview the results
	#for result in log.actionStepResults:
		#result.PreviewResult(currentMap)
#
	#ShowCombatPreview()
#
#
## TODO: Remove - Duped in TargetingDataBase
#func ShowCombatPreview():
	#var allPreviews = currentMap.get_tree().get_nodes_in_group("DamageIndicators")
	#for preview in allPreviews:
		#var previewAsDamageIndicator = preview as DamageIndicator
		#if previewAsDamageIndicator != null:
			## Hide any unit that is currently shrouded from the player
			#if previewAsDamageIndicator.assignedUnit != null && previewAsDamageIndicator.assignedUnit.ShroudedFromPlayer:
				#continue
#
			#previewAsDamageIndicator.ShowPreview()
	#pass
#
#func ShowAvailableTilesOnGrid():
	#if targetingTemplate != null:
		## not really necessary because preview does this already!
		##targetingTemplate.ShowAvailableTilesOnGrid()
		#pass
	#else:
		#currentGrid.ClearActions()
		#var isAttack = currentAbility.IsDamage()
#
		#match targetingData.Type:
			#SkillTargetingData.TargetingType.Simple:
				#for tileData in log.availableTiles:
					#if isAttack:
						#tileData.CanAttack = true
					#else:
						#tileData.CanBuff = true
#
			#SkillTargetingData.TargetingType.ShapedFree:
				#for tileData in log.availableTiles:
					#tileData.InRange = true
#
				#for target in log.affectedTiles:
					#if isAttack:
						#target.Tile.CanAttack = true
					#else:
						#target.Tile.CanBuff = true
			#SkillTargetingData.TargetingType.ShapedDirectional:
				#for targetData in log.affectedTiles:
					#if isAttack:
						#targetData.Tile.CanAttack = true
					#else:
						#targetData.Tile.CanBuff = true
#
#
		#currentGrid.ShowActions()

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
