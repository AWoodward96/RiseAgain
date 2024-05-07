extends PlayerControllerState
class_name TargetingControllerState

var TargetData
var currentTarget

func _Enter(_ctrl : PlayerController, data):
	super(_ctrl, data)

	currentGrid.ShowActions()
	if data is SkillTargetingData:
		TargetData = data
		currentTarget = TargetData.TilesInRange[0]
		ctrl.ForceReticlePosition(currentTarget.Position)


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

	if InputManager.selectDown:
		ctrl.OnTileSelected.emit(currentTarget)

	if InputManager.cancelDown:
		ctrl.selectedAbility.CancelAbility()
		ctrl.EnterContextMenuState()

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

	currentTarget = filteredList[curIndex]
	ctrl.ForceReticlePosition(currentTarget.Position)

func ToString():
	return "TargetingControllerState"
