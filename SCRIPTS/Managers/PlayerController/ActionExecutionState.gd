extends PlayerControllerState
class_name ActionExecutionState

var log : ActionLog
var source
var tempTimer : Timer
var waitForActionToFinish : bool
var waitForPostActionToFinish : bool

var waitForAbilityToFinish : bool

# Data being passed is of type ActionLog and can be an ItemLog or a AbilityLog
func _Enter(_ctrl : PlayerController, data):
	super(_ctrl, data)

	# clear all of the actions in the grid now that a target's been selected
	currentGrid.ClearActions()
	ctrl.reticle.visible = false
	ctrl.BlockMovementInput = true

	log = data
	source = log.source
	waitForActionToFinish = true

	# Ability context at this point should have targets
	if log.affectedTiles.size() == 0:
		push_error("Controller in CombatControllerState without a target. Going back to SelectionState")
		ctrl.EnterSelectionState()
		return

	log.actionResults.clear()
	# The target tiles is an array so loop through that and append the units to take damage
	for tileData in log.affectedTiles:
		if tileData.Tile.Occupant != null:
			var actionResult = ActionResult.new()
			actionResult.Source = log.source
			actionResult.Target = tileData.Tile.Occupant
			actionResult.TileTargetData = tileData
			log.actionResults.append(actionResult)

	if log.item != null:
		# If for some reason the item has movement --- god help you son
		if log.moveSelf && log.item.MovementData != null:
			log.item.MovementData.Move(currentGrid, source, log.actionOriginTile, log.actionDirection)

		# calculate the damage and the miss chance right here
		for results in log.actionResults:
			results.Item_CalculateResult(currentMap.rng, log.item)

		var item = log.item
		if item.IsDamage():
			# This is an item or ability that does damage, and should queue up the attack sequences
			if source != null:
				# If the ability has a source, then the source is in charge of setting off the sequence
				ctrl.ForceReticlePosition(log.actionOriginTile.Position)
				source.QueueAttackSequence(log.actionOriginTile.Position * currentGrid.CellSize, log)

			# Then, queue up the defense sequence for everything being hit
			for result in log.actionResults:
				result.Target.QueueDefenseSequence(log.sourceTile.Position * currentGrid.CellSize, result)
				CheckForRetaliation(result)

			#CheckForRetaliation()
		elif item.IsHeal(false):
			source.QueueHealAction(log)

	if log.ability != null:
		log.ability.AbilityActionComplete.connect(PostActionComplete)
		log.abilityStackIndex = -1


func CheckForRetaliation(_result : ActionResult):
	if log.source == null:
		return

	var defendingUnit = _result.Target
	if log.canRetaliate && !_result.Kill: # && defendingUnit.IsDefending:
		if defendingUnit.EquippedItem == null:
			return

		var retaliationItem = defendingUnit.EquippedItem
		if retaliationItem.UsableDamageData == null:
			return

		var range = defendingUnit.EquippedItem.GetRange()
		if range == Vector2i.ZERO:
			return

		var combatDistance = defendingUnit.map.grid.GetManhattanDistance(log.sourceTile.Position, defendingUnit.GridPosition)
		# so basically, if the weapon this unit is holding, has a max range
		if range.x <= combatDistance && range.y >= combatDistance:
			# okay at this point retaliation is possible
			# oh boy time to make a brand new combat data
			var newData = ActionLog.Construct(defendingUnit, defendingUnit.EquippedItem)
			newData.affectedTiles.append(log.source.CurrentTile.AsTargetData())
			# turn off retaliation or else these units will be fighting forever
			newData.canRetaliate = false
			newData.item = retaliationItem

			# Tick the usage here because idk just do it
			retaliationItem.OnCombat()


			var retaliationResult = ActionResult.new()
			retaliationResult.Source = defendingUnit
			retaliationResult.Target = log.source
			retaliationResult.TileTargetData = log.source.CurrentTile.AsTargetData()
			retaliationResult.Item_CalculateResult(defendingUnit.map.rng, retaliationItem)

			newData.actionResults.append(retaliationResult)
			log.responseResults.append(retaliationResult)

			defendingUnit.QueueAttackSequence(log.source.global_position, newData)
			log.source.QueueDefenseSequence(defendingUnit.global_position, retaliationResult)
			pass

func _Execute(_delta):
	ctrl.UpdateCameraPosition()

	if log.actionType == ActionLog.ActionType.Item:
		if waitForActionToFinish:
			if ((source != null && source.IsStackFree) || source == null) && AffectedUnitsClear():
				ActionComplete()

		if waitForPostActionToFinish:
			if ((source != null && source.IsStackFree) || source == null) && AffectedUnitsClear():
				PostActionComplete()

	if log.ability != null:
		log.ability.TryExecute(log)

	pass


func AffectedUnitsClear():
	var r = true
	for u in log.actionResults:
		if u.Target == null:
			continue

		if !u.Target.IsStackFree:
			r = false

	return r

func ActionComplete():
	waitForActionToFinish = false
	await ctrl.get_tree().create_timer(Juice.combatSequenceCooloffTimer).timeout
	waitForPostActionToFinish = true
	log.QueueExpGains()

func PostActionComplete():
	if source != null:
		source.ShowHealthBar(false)
		ctrl.ForceReticlePosition(log.source.CurrentTile.Position)
		log.source.QueueEndTurn()

	for r in log.actionResults:
		if r.Target != null:
			r.Target.ShowHealthBar(false)

	waitForPostActionToFinish = false
	if currentMap.currentTurn == GameSettingsTemplate.TeamID.ALLY:
		ctrl.EnterSelectionState()
	else:
		ctrl.EnterOffTurnState()

	if log.actionType == ActionLog.ActionType.Item && log.item != null:
		log.item.OnCombat()

	ctrl.OnCombatSequenceComplete.emit()

func ToString():
	return "ActionExecutionState"

func ShowInspectUI():
	return false
