class_name ActionLog

var source : UnitInstance
var cachedSourceStats : Dictionary = {}
var grid : Grid
var availableTiles : Array[Tile] # The working tiles that are available when you select targeting. Updated via the Item or Abilities PollTargets
var actionOriginTile : Tile # The tile that this action is actually centered on. Sort of like the PlayerControllers CurrentTile
							# It's the single tile that the Player selected during targeting

var actionDirection : GameSettingsTemplate.Direction
var sourceTile : Tile		# Where this action is coming from. Is usually Source.CurrentTile, but might not be
var affectedTiles : Array[TileTargetedData] # This is an array in case of aoe. Here are all of the tiles that were hit by this action. Could be one, could be many

var actionStepResults : Array[ActionStepResult]

# for units defending or responding to the initial attack
var responseResults : Array[ActionStepResult]

var ability : Ability
var actionStackIndex : int
var subActionStackIndex : int

var damageData : DamageData

var canRetaliate : bool = true

static func Construct(_grid : Grid, _unitSource : UnitInstance, _itemOrAbility):
	var new = ActionLog.new()
	new.grid = _grid
	new.source = _unitSource
	new.ability = _itemOrAbility
	new.sourceTile = _unitSource.CurrentTile
	new.damageData = _itemOrAbility.UsableDamageData
	new.ConstructCachedStats()
	return new


func ConstructCachedStats():
	if source == null:
		return

	for pair in source.baseStats:
		cachedSourceStats[pair] = source.GetWorkingStat(pair)

func BuildStepResults():
	if ability == null:
		return

	actionStepResults.clear()
	for tile in affectedTiles:
		var index = 0
		for step in ability.executionStack:
			var result = step.GetResult(self, tile)
			if result != null:
				if result is ActionStepResult:
					result.StepIndex = index
					actionStepResults.append(result)
				else:
					push_error("Ability Step: " + str(step.get_script()) + " - attached to ability " + ability.name + " has an improper ActionStepResult and cannot be previewed.")
			index += 1

func GetResultsFromActionIndex(_index : int):
	return actionStepResults.filter(func(_res) : return _res.StepIndex == _index)

func ContainsPush():
	for targetedTiles in affectedTiles:
		if targetedTiles.willPush:
			return true

	return false

func QueueExpGains():
	# Define a dictionary that is [UnitInstance]-[ExpGainedFromAction]
	var expGains = {}
	var expTotal = 0

	# Go through all the action results and hide the targets health bars. Also, if the source of the result is an ally, tally up their exp gain
	for result in actionStepResults:
		if result.Target != null:
			result.Target.ShowHealthBar(false)

		# if the source of this result is an ally, tally up the exp gain
		if result.Source != null && result.Source.UnitAllegiance == GameSettingsTemplate.TeamID.ALLY:
			if expGains.has(result.Source):
				expGains[result.Source] += result.ExpGain
			else:
				expGains[result.Source] = result.ExpGain
			expTotal += result.ExpGain

	# Do the same thing for response reults
	for result in responseResults:
		if result.Source != null && result.Source.UnitAllegiance == GameSettingsTemplate.TeamID.ALLY:
			if expGains.has(result.Source):
				expGains[result.Source] += result.ExpGain
			else:
				expGains[result.Source] = result.ExpGain
		expTotal += result.ExpGain

	# Now that we know the total exp gained, give it
	if expTotal != 0:
		for unitInstance in expGains:
			unitInstance.QueueExpGain(expGains[unitInstance])
