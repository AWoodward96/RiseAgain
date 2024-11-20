extends PlayerControllerState
class_name ActionExecutionState

var log : ActionLog
var source
var tempTimer : Timer

# Data being passed is of type ActionLog and can be an ItemLog or a AbilityLog
func _Enter(_ctrl : PlayerController, data):
	super(_ctrl, data)

	# clear all of the actions in the grid now that a target's been selected
	currentGrid.ClearActions()
	ctrl.reticle.visible = false
	ctrl.BlockMovementInput = true

	log = data
	source = log.source

	# Ability context at this point should have targets
	if log.affectedTiles.size() == 0:
		push_error("Controller in CombatControllerState without a target. Going back to SelectionState")
		ctrl.EnterSelectionState()
		return


	if log.ability != null:
		log.ability.AbilityActionComplete.connect(PostActionComplete)
		log.actionStackIndex = -1

func _Execute(_delta):
	ctrl.UpdateCameraPosition()

	if log.ability != null:
		log.ability.TryExecute(log, _delta)
	else:
		# log ability is null - is that because the target of this action is dead?
		if log.source == null:
			# okay then default to post action complete
			# If the source of this ability is dead to a player fighting back, then that will be in the response results
			for result in log.responseResults:
				# Check this specific result. If the source is not null, then the source is not the source of this attack
				# If the result is null, then that's refering to the now dead unit
				if result.Source != null && result.Target == null:
					result.Source.QueueExpGain(result.ExpGain)
			PostActionComplete()
	pass


func AffectedUnitsClear():
	var r = true
	for u in log.actionResults:
		if u.Target == null:
			continue

		if !u.Target.IsStackFree:
			r = false

	return r

func PostActionComplete():
	if source != null:
		source.ShowHealthBar(false)
		ctrl.ForceReticlePosition(log.source.CurrentTile.Position)


	for r in log.actionStepResults:
		if r.Target != null:
			r.Target.ShowHealthBar(false)

	if currentMap.currentTurn == GameSettingsTemplate.TeamID.ALLY:
		ctrl.EnterSelectionState()
	else:
		ctrl.EnterOffTurnState()

	if log.actionType == ActionLog.ActionType.Item && log.item != null:
		log.item.OnCombat()

	#ctrl.OnCombatSequenceComplete.emit()

func ToString():
	return "ActionExecutionState"

func ShowInspectUI():
	return false
