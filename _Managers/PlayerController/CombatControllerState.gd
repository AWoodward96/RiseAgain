extends PlayerControllerState
class_name CombatControllerState

var abilityContext : AbilityContext
var unitsToTakeDamage : Array[UnitInstance]
var tempTimer : Timer

func _Enter(_ctrl : PlayerController, data):
	super(_ctrl, data)

	# clear all of the actions in the grid now that a target's been selected
	currentGrid.ClearActions()

	abilityContext = data

	# Ability context at this point should have targets
	if abilityContext.target == null:
		push_error("Controller in CombatControllerState without a target. Going back to SelectionState")
		ctrl.EnterSelectionState()
		return

	unitsToTakeDamage.clear()
	if abilityContext.target is Array:
		# I need to check if this 'if' statement works, but for now, each target here will be taking damage
		for u in abilityContext.target:
			unitsToTakeDamage.append(u)
	elif abilityContext.target is UnitInstance:
		# if it's a single target, append the array
		unitsToTakeDamage.append(abilityContext.target)

	# Create a timer to help track these combat events
	if tempTimer == null:
		tempTimer = Timer.new()
		tempTimer.name = "CombatCutsceneTimer"
		ctrl.add_child(tempTimer)
		tempTimer.timeout.connect(WarmUpDone)
		tempTimer.wait_time = Juice.combatSequenceWarmupTimer
		tempTimer.start()

	# Okay now that we have all the data, show all of the units' health bars and hide all uis
	if abilityContext.source != null:
		# The source actually isn't necessary
		# The DamageContext has a value that can be used to deal flat damage to units
		abilityContext.source.ShowHealthBar(true)

	for units in unitsToTakeDamage:
		units.ShowHealthBar(true)


func WarmUpDone():
	tempTimer.timeout.disconnect(WarmUpDone)
	tempTimer.timeout.connect(AttackDone)
	tempTimer.wait_time = Juice.combatSequenceTimeBetweenAttackAndDefense
	tempTimer.start()

	if abilityContext.source != null:
		# TODO: This will need to be expanded. Some abilities target a speicic tile, or multiple units
		abilityContext.source.PlayAttackSequence(unitsToTakeDamage[0].position)

func AttackDone():
	tempTimer.timeout.disconnect(AttackDone)

	tempTimer.timeout.connect(Cooloff)
	tempTimer.wait_time = Juice.combatSequenceCooloffTimer
	tempTimer.start()

	for u in unitsToTakeDamage:
		if abilityContext.source != null:
			u.TakeDamage(abilityContext.damageContext, abilityContext.source)
			u.PlayDefenseSequence(abilityContext.source.position)

		# TODO : The actual damage call

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
