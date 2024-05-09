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
	ctrl.reticle.visible = false
	ctrl.BlockMovementInput = true

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

	if abilityContext.source != null:
		# If the ability has a source, then the source is in charge of setting off the sequence
		abilityContext.source.QueueAttackSequence(abilityContext.originTile.Position * currentGrid.CellSize, abilityContext, unitsToTakeDamage)
	else:
		# if the ability has no source, then the targets all take damage on their own
		for u in unitsToTakeDamage:
			u.QueueDefenseSequence(abilityContext.originTile.Position * currentGrid.CellSize, abilityContext.damageContext, abilityContext.source)

func _Execute(_delta):
	if abilityContext.source != null:
		# If abillity has a source, wait until the source's stack is clear
		if abilityContext.source.IsStackFree && DamagedUnitsClear():
			CombatComplete()
	else:
		if DamagedUnitsClear():
			CombatComplete()
	pass

func DamagedUnitsClear():
	var r = true
	for u in unitsToTakeDamage:
		if u == null:
			continue
		if !u.IsStackFree:
			r = false

	return r

func CombatComplete():
	await ctrl.get_tree().create_timer(Juice.combatSequenceCooloffTimer).timeout
	if abilityContext.source != null:
		abilityContext.source.ShowHealthBar(false)

	for u in unitsToTakeDamage:
		if u == null:
			continue
		u.ShowHealthBar(false)

	ctrl.EnterSelectionState()
	ctrl.OnCombatSequenceComplete.emit()

func ToString():
	return "CombatControllerState"


func ShowInspectUI():
	return false
