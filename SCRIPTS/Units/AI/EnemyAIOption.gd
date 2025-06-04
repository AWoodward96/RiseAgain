class_name EnemyAIOption

const TIER_AMOUNT = 100
const KILL_TIER_AMOUNT = 101 # Weighed only 1 higher than other tiers - just so it can stick out as the best option more oftan than not
const ABILITY_TIER_AMOUNT = 1000

var weight : int

var killCount : int
var unitWillRetaliate : bool
var canDealDamage : bool
var damageAmount : int

var flagIndex : int
var totalFlags : int

var roughPath : Array[Tile] # Rough path is the direct path to the target unit, without taking into account other units
var path : Array[Tile]		# The actual path, taking other units into consideration. This is what the enemy should use to move to a target
var tilesHitByAttack : Array[TileTargetedData]
var direction : GameSettingsTemplate.Direction

var targetUnit : UnitInstance
var sourceUnit : UnitInstance

# not always equal to targetUnit.CurrentTile
var tileToMoveTo : Tile
var tileToAttack : Tile
var manhattanDistance : int

var ability : Ability
var valid : bool = false
var map : Map
var grid : Grid

static func Construct(_source : UnitInstance, _target : UnitInstance, _map : Map, _ability : Ability):
	var option = EnemyAIOption.new()
	option.map = _map
	option.grid = _map.grid
	option.sourceUnit = _source
	option.targetUnit = _target
	option.ability = _ability
	return option

func Update():
	CheckIfMovementNeeded(sourceUnit.CurrentTile, [sourceUnit.CurrentTile])
	if valid:
		# If Valid is true at the moment, then our target is within range to attack at the tile we're currently standing on
		# At this point in time, just return. There's no additional information we need to attach to this option
		return
	else:
		# If Valid isn't true, then we need to move to attack this target.
		# We need to get all of the possible options for attacking this target
		# Greedy Tile Path is used here because 1: It's fast and 2: It can get us closer to a target thats's out of reach - where-as A* would simply fail
		roughPath = map.grid.GetGreedyTilePath(sourceUnit, sourceUnit.CurrentTile, targetUnit.CurrentTile)
		if roughPath.size() == 0:
			# If it's 0, there is no path between these two units that is valid.
			# If the MovementNeeded check fails, then this unit option is invalid and won't be used
			return

		# Okay so we think we can get to the target unit right now.
		# Issue is, that doesn't mean that we can ACTUALLY hit them. There could be units in the way, or other nonsense that we don't know how to deal with
		# How this actually works is we take the Target Units position, and get the tiles from that position based on the range of the attack
		# It's sort of reverse engineering places where we can attack the unit before seeing if we can move there as opposed to checking every movement tile
		var actionableTiles = GetActionableTiles(ability.GetRange())
		if actionableTiles == null || actionableTiles.size() == 0:
			# This might happen if a melee unit only has one valid tile they can path through, and there's a unit on that spot
			# In that case, truncate to a closer position.
			valid = true
			TruncatePathToMovement(roughPath)
			return

		# Okay so we have a list of actionableTiles - check which one is the closest
		var lowest = 1000000
		var selectedPath
		for tile in actionableTiles:
			var workingPath = map.grid.GetTilePath(sourceUnit, sourceUnit.CurrentTile, tile)
			if workingPath.size() < lowest && workingPath.size() != 0: # Check 0 path size, because that indicates that there is no path to that tile
				selectedPath = workingPath
				selectedPath.remove_at(0) # Remove the first entry, because that is the current tile this unit is on
				lowest = workingPath.size()

		# If selected path isn't null, then there is a path to the player
		if selectedPath != null && selectedPath.size() != 0:
			valid = true
			path = selectedPath
			TruncatePathToMovement(path)
			CheckIfMovementNeeded(path[path.size() - 1], path)
		else:
			valid = true
			TruncatePathToMovement(roughPath)

			# If we've reached here then there is no path that puts us within range to hit the target
			# Exceeeeept we never really checked the ShapedDirectionals
			# What we're going to do now is to check to see if the target is within range based on this current tile
			if ability.TargetingData.Type == SkillTargetingData.TargetingType.ShapedDirectional:
				# So basically, always move towards the player AND if you can hit them - well then do so!
				CheckIfMovementNeeded(path[path.size() - 1], path)
	pass


func CheckIfMovementNeeded(_origin : Tile, _fullPath : Array[Tile]):
	# First, check if we even need to move in order to hit the target
	if sourceUnit.currentFocus >= ability.focusCost && ability.TargetingData != null:
		var abilityRange = ability.GetRange()
		match ability.TargetingData.Type:
			SkillTargetingData.TargetingType.Simple, SkillTargetingData.TargetingType.ShapedFree:
				# Teeeechnically for shaped free, the attacks can hit units outside of the range of the ability (since it's aoe)
				# But that would require a butload of calculation on a per-tile basis and that's just gonna slow the turn down
				# So we'll just take the manhattan calculation instead
				if manhattanDistance >= abilityRange.x && manhattanDistance <= abilityRange.y:
					# Congrats we have a valid attack strategy
					valid = true
					SetValidAttack(_origin, targetUnit.CurrentTile)
					return
			SkillTargetingData.TargetingType.Global:
				# So the deal with global, is that we don't know which direction does the most damage
				# We'll ignore this until it comes up later and hate ourselves for not putting the work in now

				valid = true
				SetValidAttack(_origin, targetUnit.CurrentTile)
			SkillTargetingData.TargetingType.SelfOnly:
				# Self only first needs to check if the target will even be hit by the attack
				var targetTiles = ability.TargetingData.GetAffectedTiles(sourceUnit, grid, sourceUnit.CurrentTile)
				for t in targetTiles:
					if t.Tile.Occupant == targetUnit:
						valid = true
						SetValidAttack(_origin, targetUnit.CurrentTile)
						return
			SkillTargetingData.TargetingType.ShapedDirectional:
				# Go through all 4 directions and check to see if this directional attack will hit them
				# This is... poorly optmized, and for bigger AOE's will prioritize the directional order over how many units are actually hit by the attack
				# but wtf ever

				# oh and also it has to backtrack through the entire full path in order to determine which tile actually hits the player and
				# god why did I do this? which fucking idiot thought this was a good idea (it was me it works shut up)
				for potentialTile in _fullPath:
					for i in range(0,4):
						var directionalTiles = ability.TargetingData.GetDirectionalAttack(sourceUnit, ability, potentialTile, grid, i)
						for t in directionalTiles:
							if t.Tile.Occupant == targetUnit:
								if ability.MovementData != null:
									var evaluatedDestinationTile = ability.MovementData.PreviewMove(grid, sourceUnit, potentialTile, potentialTile, i)
									if evaluatedDestinationTile == []:
										continue
									else:
										pass

								valid = true
								direction = i as GameSettingsTemplate.Direction
								SetValidAttack(potentialTile, targetUnit.CurrentTile)
								return
						pass
				pass


func SetValidAttack(_tileToMoveTo : Tile, _tileToAttack : Tile):
	tileToMoveTo = _tileToMoveTo
	tileToAttack = _tileToAttack
	var targetUnitRange = Vector2i.ONE

	if ability != null:
		targetUnitRange = ability.GetRange()

	if ability.type == Ability.AbilityType.Weapon:
		if manhattanDistance >= targetUnitRange.x && manhattanDistance <= targetUnitRange.y:
			unitWillRetaliate = true

	if ability.TargetingData.Type == SkillTargetingData.TargetingType.ShapedDirectional:
		tilesHitByAttack = ability.TargetingData.GetDirectionalAttack(sourceUnit, ability, tileToMoveTo, grid, direction)
	elif ability.TargetingData.Type == SkillTargetingData.TargetingType.Global:
		tilesHitByAttack = ability.TargetingData.GetGlobalAttack(sourceUnit, map, direction)
	else:
		tilesHitByAttack = ability.TargetingData.GetAffectedTiles(sourceUnit, grid, tileToAttack)

	for targetTile in tilesHitByAttack:
		if targetTile.Tile.Occupant != null && ability.TargetingData.OnCorrectTeam(sourceUnit, targetTile.Tile.Occupant):
			var thisDamage = GameManager.GameSettings.DamageCalculation(sourceUnit, targetTile.Tile.Occupant, ability.UsableDamageData, targetTile)
			damageAmount += thisDamage
			if targetTile.Tile.Occupant.currentHealth <= thisDamage:
				killCount += 1

	damageAmount = GameManager.GameSettings.DamageCalculation(sourceUnit, targetUnit, ability.UsableDamageData, null)
	canDealDamage = damageAmount > 0 # This could cause some fuckyness with 'no damage' attacks but we'll see


func UpdateWeight():
	weight = 0

	# This means, the further away the unit is, the lower the priority it is.
	# IE: Closer = better
	if ability.type == Ability.AbilityType.Standard:
		weight += ABILITY_TIER_AMOUNT

	weight += TIER_AMOUNT - path.size()
	weight += KILL_TIER_AMOUNT * killCount

	# Commenting this out because it's making units ignore units that they can't hurt. They should still try imo
	if canDealDamage : weight += TIER_AMOUNT
	if !unitWillRetaliate && canDealDamage : weight += TIER_AMOUNT

	weight += damageAmount
	weight += (TIER_AMOUNT * ((totalFlags - 1) - flagIndex))

func TruncatePathToMovement(_path : Array[Tile]):
	# Saying <= 1 because we cant truncate a path with just 1 tile
	if _path.size() <= 1:
		if _path.size() == 1:
			tileToMoveTo = _path[0]
		return

	# Take the rough path, and start truncating it. Bring it down to the movement of the source Unit, and move backwards if there are tiles you can't stand on
	path = _path.slice(0, sourceUnit.GetUnitMovement())

	var indexedSize = path.size() - 1
	var selectedTile =  path[indexedSize]

	if selectedTile.Occupant != null:
		while selectedTile.Occupant != null && selectedTile.Occupant != sourceUnit:
			# Well shit now we're in trouble
			# walk backwards from the current index
			indexedSize -= 1
			if indexedSize < 0:
				# if we've hit 0, then there are a whole bunch of units all in the way of this unit
				path.clear()
				selectedTile = sourceUnit.CurrentTile
				return

			selectedTile = path[indexedSize]
			path.remove_at(path.size() - 1)

	tileToMoveTo = selectedTile
	pass

func GetActionableTiles(_range : Vector2i):
	var tilesWithinRange = map.grid.GetTilesWithinRange(targetUnit.GridPosition, _range)
	tilesWithinRange = tilesWithinRange.filter(func(tile) : return tile.Occupant == null || tile.Occupant == sourceUnit)
	tilesWithinRange = tilesWithinRange.filter(func(tile) : return !tile.IsWall)
	return tilesWithinRange
