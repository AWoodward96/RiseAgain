extends ActionStep
class_name AbilityMoveStep



#@export var WaitForStackFree : bool = true
@export var SpeedOverride : int = -1
@export var AnimationStyle : UnitSettingsTemplate.MovementAnimationStyle = UnitSettingsTemplate.MovementAnimationStyle.Normal

func Enter(_actionLog : ActionLog):
	super(_actionLog)

	if ability.MovementData == null:
		return true

	ability.MovementData.Move(log.grid, source, log.actionOriginTile, source.CurrentTile, log.actionDirection, _actionLog, SpeedOverride, AnimationStyle)
	return true

func Execute(_delta):
	#if !WaitForStackFree:
		#return true

	if log.source.IsStackFree:
		# force the turnstart tile to be where they end up because that's the breaks
		log.source.TurnStartTile = ability.MovementData.destinationTile
		return true

	return false

# The movement that you've done was not allowed (typically fog of war bullshit.) Bonk the Unit to an adjacent tile that makes sense
# ... and recalculate the results of all of the actions after this step
func Bonked(_invalidatedTile : Tile, _actionLog : ActionLog):
	if _invalidatedTile == null:
		return

	if _invalidatedTile.Occupant != null && _invalidatedTile.Occupant.Shrouded:
		_invalidatedTile.Occupant.visual.PlayAlertedFromShroudAnimation()

	# TODO: Make a method in grid to find the closest valid tile
	var bestTile = _actionLog.grid.FindNearbyValidTile(_invalidatedTile, _actionLog.actionOriginTile)

	# okay we should have the best tile after being bonked
	if bestTile == null:
		push_error("Bonk could not be resolved.")
		return

	# Okay the new best tile is
	_actionLog.actionOriginTile = bestTile
	_actionLog.actionDirection = GameSettingsTemplate.GetDirectionFromVector(bestTile.Position - _invalidatedTile.Position)

	# Re-evaluate the affected tiles
	var targetingData = _actionLog.ability.TargetingData
	if targetingData != null:
		if targetingData.Type == SkillTargetingData.TargetingType.Simple || targetingData.Type == SkillTargetingData.TargetingType.ShapedFree:
			_actionLog.affectedTiles = targetingData.GetAffectedTiles(_actionLog.source, _actionLog.grid, bestTile)
			_actionLog.affectedTiles = targetingData.FilterByTargettingFlags(source, log.affectedTiles)
			_actionLog.BuildStepResults()

		# Shaped directionals lock in the damage/affected tiles before the movement
		# - it'd be weird to bonk someone with a shaped directional attack and then
		# - all of a sudden you're unit is one block displaced than they're supposed to be



	ability.MovementData.Move(_actionLog.grid, source, _actionLog.actionOriginTile, _invalidatedTile, _actionLog.actionDirection, _actionLog, SpeedOverride, AnimationStyle)
	pass

func GetResult(_actionLog : ActionLog, _specificTile : TileTargetedData):
	var result = AbilityMoveResult.new()
	result.unitUsable = _actionLog.ability
	result.shapedDirection = _actionLog.actionDirection
	result.TileTargetData = _actionLog.actionOriginTile.AsTargetData()
	result.Source = _actionLog.source
	return result
