extends ActionStep
class_name PushStep


func Enter(_actionLog : ActionLog):
	super(_actionLog)

	var results = _actionLog.GetResultsFromActionIndex(_actionLog.actionStackIndex)
	for res : PushStepResult in results:
		var tileData = res.TileTargetData
		var pushData = tileData.pushStack


		for stack in pushData:
			# Unit died sometime before this
			if stack.Subject == null:
				continue

			var unit = stack.Subject as UnitInstance
			if unit == null:
				continue

			#var halfTile = Vector2(_actionLog.grid.CellSize / 2, _actionLog.grid.CellSize / 2)
			var movement : Array[Tile]
			movement.append(unit.CurrentTile)
			movement.append(stack.ResultingTile)
			if unit == _actionLog.source:
				unit.MoveCharacterToNode(movement, stack.ResultingTile, _actionLog, -1, true, false, true, UnitSettingsTemplate.MovementAnimationStyle.Pushed)
				unit.TurnStartTile = stack.ResultingTile
				if res.willCollide && res.canDamageUser:
					unit.QueueDefenseSequence(_actionLog.actionOriginTile.GlobalPosition, res)
			else:
				unit.MoveCharacterToNode(movement, stack.ResultingTile, _actionLog, -1, true, false, true, UnitSettingsTemplate.MovementAnimationStyle.Pushed)
				if res.willCollide:
					unit.QueueDefenseSequence(_actionLog.actionOriginTile.GlobalPosition, res)

			pass

		if res.willCollide:
			if tileData.pushCollision.Occupant != null:
				tileData.pushCollision.Occupant.QueueDefenseSequence(_actionLog.actionOriginTile.GlobalPosition, res)
			else:
				_actionLog.grid.ModifyTileHealth(res.HealthDelta, res.TileTargetData.pushCollision, true)
		pass



func GetResults(_actionLog : ActionLog, _allTargetedTiles : Array[TileTargetedData]):
	var returnArray : Array[PushStepResult]

	for tile in _allTargetedTiles:
		var result = PushStepResult.new()
		result.Source = _actionLog.source
		result.TileTargetData = tile
		result.canDamageUser = tile.pushCanDamageUser
		result.PreCalc()
		returnArray.append(result)

	return returnArray
