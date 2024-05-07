extends PlayerControllerState
class_name CombatControllerState

var abilityContext : AbilityContext
var unitsToTakeDamage : Array[UnitInstance]
var tempTimer : Timer
var waitForAnimToFinish : bool

func _Enter(_ctrl : PlayerController, data):
	super(_ctrl, data)

	# clear all of the actions in the grid now that a target's been selected
	currentGrid.ClearActions()

	waitForAnimToFinish = false
	abilityContext = data

	# Ability context at this point should have targets
	if abilityContext.targetTiles.size() == 0:
		push_error("Controller in CombatControllerState without a target. Going back to SelectionState")
		ctrl.EnterSelectionState()
		return

	unitsToTakeDamage.clear()

	# The target tiles is an array so loop through that and append the units to take damage
	for tile in abilityContext.targetTiles:
		if tile.Occupant != null:
			unitsToTakeDamage.append(tile.Occupant)


func _Execute(_delta):
	var goodToExecute = true
	for u in unitsToTakeDamage:
		if u == null:
			continue

		if !u.IsStackFree:
			goodToExecute = false

	if abilityContext.source != null && !abilityContext.source.IsStackFree:
		goodToExecute = false

	if goodToExecute && !waitForAnimToFinish:
		waitForAnimToFinish = true
		if abilityContext.source != null:
			abilityContext.source.QueueAttackSequence(abilityContext.originTile.Position * currentGrid.CellSize)

		for u in unitsToTakeDamage:
			u.TakeDamage(abilityContext.damageContext, abilityContext.source)
			u.QueueDefenseSequence(abilityContext.source.position)


	if waitForAnimToFinish:
		var finished = true
		if abilityContext.source != null && !abilityContext.source.IsStackFree:
			finished = false

		for u in unitsToTakeDamage:
			if u == null:
				continue

			if !u.IsStackFree:
				finished = false

		if finished:
			ctrl.EnterSelectionState()
			ctrl.OnCombatSequenceComplete.emit()
	pass

func WarmUpDone():
	tempTimer.timeout.disconnect(WarmUpDone)
	tempTimer.timeout.connect(AttackDone)
	tempTimer.wait_time = Juice.combatSequenceTimeBetweenAttackAndDefense
	tempTimer.start()

	if abilityContext.source != null:
		# TODO: This will need to be expanded. Some abilities target a speicic tile, or multiple units
		abilityContext.source.QueueAttackSequence(unitsToTakeDamage[0].position)

func AttackDone():
	tempTimer.timeout.disconnect(AttackDone)

	tempTimer.timeout.connect(Cooloff)
	tempTimer.wait_time = Juice.combatSequenceCooloffTimer
	tempTimer.start()

	for u in unitsToTakeDamage:
		if abilityContext.source != null:
			u.TakeDamage(abilityContext.damageContext, abilityContext.source)
			u.QueueDefenseSequence(abilityContext.source.position)

func Cooloff():
	# For now, we're hiding the health bars in cool off
	# This will most likely want to be handled by the Unit instance's own health bars
	for units in unitsToTakeDamage:
		if units != null:
			units.ShowHealthBar(false)

	if abilityContext.source != null:
		abilityContext.source.ShowHealthBar(false)

	# the sequence should be done, go back to selection state
	# This might not want to be automatic, but we'll see
	ctrl.EnterSelectionState()
	ctrl.OnCombatSequenceComplete.emit()

func _Exit():
	super()
	if tempTimer != null:
		tempTimer.queue_free()
		tempTimer = null

func ToString():
	return "CombatControllerState"
