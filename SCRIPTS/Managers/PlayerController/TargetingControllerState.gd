extends PlayerControllerState
class_name TargetingControllerState

var TargetData
var currentTarget
var currentItem
var source

func _Enter(_ctrl : PlayerController, ItemData):
	super(_ctrl, ItemData)

	# Grid should already be showing the actionable tiles from the Item Selection state
	# That information should be passed here for our selection
	if ItemData is Item:
		currentItem = ItemData
		TargetData = ItemData.TargetingData
		currentTarget = TargetData.TilesInRange[0]
		source = ItemData.ownerUnit
		ctrl.ForceReticlePosition(currentTarget.Position)

		ShowDamagePreview()


func UpdateInput(_delta):
	if TargetData == null:
		return

	match TargetData.Type:
		SkillTargetingData.TargetingType.Simple:
			# Simple is simple. The Initial Targets section of the struct should have all the units already
			if TargetData.TilesInRange[0].Occupant == null:
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

	if InputManager.selectDown && currentTarget.Occupant != null:
		ctrl.OnTileSelected.emit(currentTarget)

	if InputManager.cancelDown:
		ClearDamagePreview()
		ctrl.selectedItem.CancelAbility()
		#ctrl.EnterContextMenuState()
		ctrl.EnterItemSelectionState()

func _Exit():
	ClearDamagePreview()
	pass

func StandartTargetingInput(_delta):
	# Goes through InitialTargets
	if !InputManager.inputAnyDown:
		return

	var filteredList = []
	for t in TargetData.TilesInRange:
		if t.Occupant != null:
			filteredList.append(t)

	if filteredList.size() == 0:
		return

	var curIndex = filteredList.find(currentTarget, 0)
	if InputManager.inputDown[0] || InputManager.inputDown[1]:
		curIndex += 1
		if curIndex >= filteredList.size():
			curIndex = 0

	if InputManager.inputDown[2] || InputManager.inputDown[3]:
		curIndex -= 1
		if curIndex < 0:
			curIndex = filteredList.size() - 1

	ClearDamagePreview()
	currentTarget = filteredList[curIndex]
	ShowDamagePreview()

	ctrl.ForceReticlePosition(currentTarget.Position)

func ClearDamagePreview():
	if currentTarget != null && currentTarget.Occupant != null:
		currentTarget.Occupant.HideDamagePreview()
		ctrl.combatHUD.ClearDamagePreviewUI()

func ShowDamagePreview():
	if currentTarget != null && currentTarget.Occupant != null:
		# Show the damage preview physically on the unit
		# this section is slated for removal if it is deemed to be unnecessary
		currentTarget.Occupant.ShowDamagePreview(source, currentItem.ItemDamageData)

		# Ping the CombatHUD to show the damage preview
		ctrl.combatHUD.ShowDamagePreviewUI(source, source.EquippedItem, currentTarget.Occupant)

func ToString():
	return "TargetingControllerState"

func ShowInspectUI():
	return false
