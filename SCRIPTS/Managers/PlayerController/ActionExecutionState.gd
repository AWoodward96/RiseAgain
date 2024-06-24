extends PlayerControllerState
class_name ActionExecutionState

var log : ActionLog
var source
var unitsAffected : Array[UnitInstance]
var tempTimer : Timer
var waitForAnimToFinish : bool

# Data being passed is of type ActionLog and can be an ItemLog or a AbilityLog
func _Enter(_ctrl : PlayerController, data):
	super(_ctrl, data)

	# clear all of the actions in the grid now that a target's been selected
	currentGrid.ClearActions()
	ctrl.reticle.visible = false
	ctrl.BlockMovementInput = true

	waitForAnimToFinish = false
	log = data
	source = log.source

	# Ability context at this point should have targets
	if log.affectedTiles.size() == 0:
		push_error("Controller in CombatControllerState without a target. Going back to SelectionState")
		ctrl.EnterSelectionState()
		return

	unitsAffected.clear()

	# The target tiles is an array so loop through that and append the units to take damage
	for tile in log.affectedTiles:
		if tile.Occupant != null:
			unitsAffected.append(tile.Occupant)

	if log.item != null:
		var item = log.item
		if item.IsDamage():
			# This is an item or ability that does damage, and should queue up the attack sequences
			if source != null:
				# If the ability has a source, then the source is in charge of setting off the sequence
				ctrl.ForceReticlePosition(log.actionOriginTile.Position)
				source.QueueAttackSequence(log.actionOriginTile.Position * currentGrid.CellSize, log, unitsAffected)
			else:
				# if the ability has no source, then the targets all take damage on their own
				for u in unitsAffected:
					u.QueueDefenseSequence(log.actionOriginTile.Position * currentGrid.CellSize, log, source)
		elif item.IsHeal(false):
			source.QueueHealAction(item.HealData, unitsAffected)

func _Execute(_delta):
	ctrl.UpdateCameraPosition()
	if source != null:
		# If abillity has a source, wait until the source's stack is clear
		if source.IsStackFree && AffectedUnitsClear():
			ActionComplete()
	else:
		if AffectedUnitsClear():
			ActionComplete()
	pass

func AffectedUnitsClear():
	var r = true
	for u in unitsAffected:
		if u == null:
			continue
		if !u.IsStackFree:
			r = false

	return r

func ActionComplete():
	await ctrl.get_tree().create_timer(Juice.combatSequenceCooloffTimer).timeout
	if source != null:
		source.ShowHealthBar(false)
		ctrl.ForceReticlePosition(log.source.CurrentTile.Position)
		log.source.QueueEndTurn()

	for u in unitsAffected:
		if u == null:
			continue
		u.ShowHealthBar(false)

	if currentMap.currentTurn == GameSettings.TeamID.ALLY:
		ctrl.EnterSelectionState()
	else:
		ctrl.EnterOffTurnState()

	ctrl.OnCombatSequenceComplete.emit()

func ToString():
	return "ActionExecutionState"

func ShowInspectUI():
	return false
