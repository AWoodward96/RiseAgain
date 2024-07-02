class_name ActionLog

enum ActionType { Item, Ability }

var source : UnitInstance
var availableTiles : Array[Tile] # The working tiles that are available when you select targeting. Updated via the Item or Abilities PollTargets
var actionOriginTile : Tile # The tile that this action is actually centered on. Sort of like the PlayerControllers CurrentTile
							# It's the single tile that the Player selected during targeting

var sourceTile : Tile		# Where this action is coming from. Is usually Source.CurrentTile, but might not be
var affectedTiles : Array[Tile] # This is an array in case of aoe. Here are all of the tiles that were hit by this action. Could be one, could be many

var actionResults : Array[ActionResult]

# for units defending or responding to the initial attack
var responseResults : Array[ActionResult]

var actionType : ActionType
var item : Item
var ability : Ability
var abilityStackIndex : int

var damageData : DamageData

var canRetaliate : bool = true

static func Construct(_unitSource : UnitInstance, _itemOrAbility):
	var new = ActionLog.new()
	new.source = _unitSource
	if _itemOrAbility is Item:
		new.item = _itemOrAbility
		new.actionType = ActionLog.ActionType.Item
	elif _itemOrAbility is Ability:
		new.ability = _itemOrAbility
		new.actionType = ActionLog.ActionType.Ability
	new.sourceTile = _unitSource.CurrentTile
	new.damageData = _itemOrAbility.UsableDamageData
	return new


func QueueExpGains():
	var expGains = {}
	# Go through all the action results and hide the targets health bars. Also, if the source of the result is an ally, tally up their exp gain
	for result in actionResults:
		if result.Target != null:
			result.Target.ShowHealthBar(false)

		# if the source of this result is an ally, tally up the exp gain
		if result.Source != null && result.Source.UnitAllegiance == GameSettingsTemplate.TeamID.ALLY:
			if expGains.has(result.Source):
				expGains[result.Source] += result.ExpGain
			else:
				expGains[result.Source] = result.ExpGain

	# Do the same thing for response reults
	for result in responseResults:
		if result.Source != null && result.Source.UnitAllegiance == GameSettingsTemplate.TeamID.ALLY:
			if expGains.has(result.Source):
				expGains[result.Source] += result.ExpGain
			else:
				expGains[result.Source] = result.ExpGain

	# Now that we know the total exp gained, give it
	for keypair in expGains:
		keypair.QueueExpGain(expGains[keypair])
