extends AISmartTarget
class_name AIMalice

enum EMaliceBossState { PlayWithFood, Lacerate, Decimate }

@export var LacerateRef : String = "lacerate"
@export var DecimateRef : String = "decimatus"

var lacerateAbility : Ability
var decimateAbility : Ability
var allAlliedUnits : Array[UnitInstance]

var state : EMaliceBossState = EMaliceBossState.PlayWithFood
var lacerateTarget : EnemyAIOption
var decimateTarget : EnemyAIOption

func StartTurn(_map : Map, _unit : UnitInstance):
	CommonStartTurn()
	GetReferences()
	lacerateTarget = null
	decimateTarget = null
	allAlliedUnits = _map.GetUnitsOnTeam(GameSettingsTemplate.TeamID.ALLY)

	# If we can't decimate, play with them - and use lacerate if possible
	if !Decision_Decimate():
		Decision_PlayWithFood()

func Check_Decimate():
	return false

func Decision_PlayWithFood():
	state = EMaliceBossState.PlayWithFood
	var malicesMovement = unit.GetUnitMovement()
	if malicesMovement == 0:
		unit.QueueEndTurn()
		return

	##NOTE:
	# Alright here's what we're going to do
	# 1: Average the player units positions. This is so I have one point to work with instead of N points
	# 2: Get the threat range of the Allied Units. I can use grid.GetWorkingThreatList to do so
	# 3: Loop through every node on the map
	#	- If it's in the threat range, bail.
	#	- If it's not, get the angle between the point and the averaged unit positions from #1
	#	- If it's close to a 90 degree angle in any of the cardinal directions then it passes
	# 4: Loop through the available tiles in the list from #3. Pick the closest one. Move there.

	# This implementaiton actually contains a bug where sometimes Malice wont perfectly run away to a safe spot
	# 	They'll be within range of someone - but only sometimes.
	#	I'm actually fine with this. I'm not fixing it. She miscalculated, not me.
	var accumulatedPositions = Vector2.ZERO
	for u in allAlliedUnits:
		accumulatedPositions += Vector2(u.GridPosition)
	accumulatedPositions = Vector2(floori(accumulatedPositions.x / allAlliedUnits.size()),floori(accumulatedPositions.y / allAlliedUnits.size()))

	var threatRange = grid.GetWorkingThreatList(allAlliedUnits)
	if threatRange.has(unit.CurrentTile):
		# We're in range time to play
		var validTiles : Array[Tile] = []
		for tile in grid.GridArr:
			# Can't occupy a tile that another unit is on
			if tile.Occupant != null:
				continue

			if threatRange.has(tile):
				continue

			# Get the angle of the position relative to the averaged unit positions
			var angle = rad_to_deg((Vector2(tile.Position) - accumulatedPositions).angle_to(Vector2.RIGHT))

			if angle < 0:
				# stop it. Get some help
				angle += 360

			# I'm hard coding this angle threshold but it could be bigger
			var angleThreshold = 15
			if (angle > 360 - angleThreshold || angle < angleThreshold) || (angle > 90 - angleThreshold && angle < 90 + angleThreshold) || (angle > 180 - angleThreshold && angle < 180 + angleThreshold) || (angle > 270 - angleThreshold && angle < 270 + angleThreshold):
				validTiles.append(tile)

		if validTiles.size() > 0:
			# loop through all valid tiles, find the one that's you're closest to, that you're not actively standing on.
			# move there
			var closestDST = grid.Width * grid.Height
			var moveToMe : Tile = null
			for tile in validTiles:
				if tile == unit.CurrentTile:
					continue

				var manhattan = grid.GetManhattanDistance(unit.CurrentTile.Position, tile.Position)
				if manhattan < closestDST:
					moveToMe = tile
					closestDST = manhattan

			var data = MovementData.Construct([unit.CurrentTile, moveToMe], moveToMe)
			unit.MoveCharacterToNode(data)

	# don't over think it. Lacerate.
	Decision_Lacerate()


func Decision_Lacerate():
	# I'm expecting there might be more than one target here so i'm gonna keep track of it
	var highestHealthTargets : Array[UnitInstance]
	var healthValue = 0

	for teamID in map.teams:
		for unitInTeam : UnitInstance in map.teams[teamID]:
			if unitInTeam.currentHealth == unitInTeam.maxHealth || unitInTeam == unit:
				continue

			if unitInTeam.currentHealth == healthValue:
				highestHealthTargets.append(unitInTeam)
			elif unitInTeam.currentHealth > healthValue:
				highestHealthTargets.clear()
				highestHealthTargets.append(unitInTeam)
				healthValue = unitInTeam.currentHealth

	# Sort them by if they're on the player team or not
	if highestHealthTargets.size() == 0:
		unit.QueueEndTurn()
		return

	if highestHealthTargets.size() >= 1:
		state = EMaliceBossState.Lacerate
		lacerateTarget = EnemyAIOption.Construct(unit, highestHealthTargets[0], map, lacerateAbility)
		lacerateTarget.canAttack = true
		lacerateTarget.valid = true
		lacerateTarget.tileToAttack = highestHealthTargets[0].CurrentTile
		lacerateTarget.tilesHitByAttack = [highestHealthTargets[0].CurrentTile.AsTargetData()]

	pass

func Decision_Decimate():
	if decimateAbility == null || (decimateAbility != null && decimateAbility.remainingCooldown > 0):
		return false

	var lowestHealthUnit = 1000000
	var bestTarget : UnitInstance = null
	for u in allAlliedUnits:
		if u.currentHealth / u.maxHealth < 0.5:
			if u.currentHealth < lowestHealthUnit:
				# One last check - is there an adjacent tile
				var adjacent = grid.GetAdjacentTiles(u.CurrentTile)
				var hasAdjacent = false
				for adj in adjacent:
					if adj.Occupant == null:
						hasAdjacent = true
						break

				if hasAdjacent:
					bestTarget = u
					lowestHealthUnit = u.currentHealth

	if bestTarget != null:
		# Teleports behind you
		# The best implementation of this would calculate which orientation would deal the most damage to the most targets
		# but like. does it matter? most of the time it'll be fine
		# do it randomly
		var moveTo : Array[Tile] = []
		var adjacent = grid.GetAdjacentTiles(bestTarget.CurrentTile)
		for adj in adjacent:
			if adj.Occupant == null:
				moveTo.append(adj)

		# holy shit I'm actually gonna burn an RNG?
		if moveTo.size() == 0:
			push_error("MALICE Behavior tried to decimate, but couldn't find a proper tile to move to. This should be theoretically impossible, so good luck.")
			return false

		var rng = map.mapRNG.NextInt(0, moveTo.size() - 1)
		var tileToMoveTo = moveTo[rng]
		var movementData = MovementData.Construct([unit.CurrentTile, tileToMoveTo], tileToMoveTo)
		unit.MoveCharacterToNode(movementData)

		# Time to slam jam
		decimateTarget = EnemyAIOption.Construct(unit, bestTarget, map, decimateAbility)
		decimateTarget.valid = true
		decimateTarget.canAttack = true
		decimateTarget.tileToAttack = bestTarget.CurrentTile
		decimateTarget.tilesHitByAttack = [bestTarget.CurrentTile.AsTargetData()]
		decimateTarget.direction = GameSettingsTemplate.GetDirectionFromVector(bestTarget.CurrentTile.Position - tileToMoveTo.Position)
		decimateTarget.tileToMoveTo = tileToMoveTo
		state = EMaliceBossState.Decimate
		return true

	return false

# Not the prettiest way to do this every turn but
func GetReferences():
	for ability in unit.Abilities:
		if ability.internalName == LacerateRef:
			lacerateAbility = ability

		if ability.internalName == DecimateRef:
			decimateAbility = ability


func RunTurn():
	if unit.IsStackFree:
		match state:
			EMaliceBossState.PlayWithFood:
				# this shouldn't ever be hit? but just in case it does queue the end of the turn
				unit.QueueEndTurn()
				pass
			EMaliceBossState.Lacerate:
				if lacerateTarget != null:
					selectedOption = lacerateTarget
					TryCombat()

				unit.QueueEndTurn()
				pass
			EMaliceBossState.Decimate:
				if decimateTarget != null:
					selectedOption = decimateTarget
					TryCombat()
				unit.QueueEndTurn()
				pass
