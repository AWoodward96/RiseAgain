extends PlayerControllerState
class_name TargetingControllerState

var targetingData : SkillTargetingData
var source

var log : ActionLog
var currentItem : Item
var currentTargetTile : Tile

func _Enter(_ctrl : PlayerController, ItemOrAbility):
	super(_ctrl, ItemOrAbility)

	# Grid should already be showing the actionable tiles from the Item Selection state
	# That information should be passed here for our selection
	if ItemOrAbility is Item:
		currentItem = ItemOrAbility as Item
		targetingData = currentItem.TargetingData
		source = ItemOrAbility.ownerUnit

		log = ActionLog.Construct(source, currentItem)
		log.availableTiles = targetingData.GetTilesInRange(source, currentGrid)
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
				StandartTargetingInput(_delta)
			pass
		SkillTargetingData.TargetingType.ShapedFree:
			pass
		SkillTargetingData.TargetingType.ShapedDirectional:
			pass

	if InputManager.selectDown && currentTargetTile.Occupant != null:
		log.actionOriginTile = currentTargetTile
		log.affectedTiles = targetingData.GetAdditionalTileTargets(currentTargetTile)
		if currentItem != null:
			log.damageData = currentItem.ItemDamageData

		ctrl.EnterActionExecutionState(log)
		ctrl.OnTileSelected.emit(currentTargetTile)

	if InputManager.cancelDown:
		ClearPreview()
		ctrl.EnterItemSelectionState(ctrl.lastItemFilter)

func _Exit():
	ClearPreview()
	pass

func StandartTargetingInput(_delta):
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

func ClearPreview():
	if currentTargetTile != null && currentTargetTile.Occupant != null:
		currentTargetTile.Occupant.HideDamagePreview()
		ctrl.combatHUD.ClearDamagePreviewUI()

func ShowPreview():
	if currentItem.IsDamage():
		ShowDamagePreview()
	elif currentItem.IsHeal(false):
		ShowHealPreview()

func ShowDamagePreview():
	if currentTargetTile != null && currentTargetTile.Occupant != null:
		# Show the damage preview physically on the unit
		# this section is slated for removal if it is deemed to be unnecessary
		currentTargetTile.Occupant.ShowDamagePreview(source, currentItem.ItemDamageData)

		# Ping the CombatHUD to show the damage preview
		ctrl.combatHUD.ShowDamagePreviewUI(source, source.EquippedItem, currentTargetTile.Occupant)

func ShowHealPreview():
	if currentTargetTile != null && currentTargetTile.Occupant != null:
		# Show the damage preview physically on the unit
		# this section is slated for removal if it is deemed to be unnecessary
		currentTargetTile.Occupant.ShowHealPreview(source, currentItem.HealData)

func ShowAvailableTilesOnGrid():
	currentGrid.ClearActions()
	for tile in log.availableTiles:
		tile.CanAttack = true

	currentGrid.ShowActions()

func ToString():
	return "TargetingControllerState"

func ShowInspectUI():
	return false
