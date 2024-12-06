extends AIBehaviorBase
class_name AIDemiKestrel

# ----------------------------------------------------------------
# Here's how the demikestrel ai works
# They have three locations on the map - Up Right and Left
# At the start of the map, put these three options in a list
# Then select one at random and remove it from the list.
# Perform the selected action at that location, and then end turn
# When the list is empty, restart the list, but empty out the current location
# This way the Boss is always moving and you always have to keep up
# If the Boss is at Up:
# 	- Create 1 to 2 Gales
#	- The amount created alternates between one and two, one straight down the middle, two scrapping the sides
# If the Boss is at Left or Right:
#	- Push All Player Units in a direction
# ----------------------------------------------------------------

@export var locationCoordinates : Array[Vector2i] = [Vector2i(8,2), Vector2i(3,5), Vector2i(13,5)]
@export var unitSpeedOverride : int = 1000
@export var galeAbilityRef : String
@export var howlingWindsAbilityRef : String

var availableLocations : Array[int]
var currentLocation : int = -1
var nextLocation : int = -1
var galeSpawnStyle : bool = false # Alternates between true and false. If true, summon 2, if false, summon 1

var gale : Ability
var howlingWinds : Ability
var waitForMove

func StartTurn(_map : Map, _unit : UnitInstance):
	super(_map, _unit)
	GetReferences()
	if availableLocations.size() == 0:
		InitializeLocations()

	# First queue movement
	nextLocation = availableLocations.pop_front()

	MoveToNextLocation()
	waitForMove = true
	pass

func GetReferences():
	for ability in unit.Abilities:
		if ability.internalName == galeAbilityRef:
			gale = ability

		if ability.internalName == howlingWindsAbilityRef:
			howlingWinds = ability

func MoveToNextLocation():
	var route : Array[Tile] = []
	route.append(unit.CurrentTile)
	var tile = map.grid.GetTile(locationCoordinates[nextLocation])
	route.append(tile)
	unit.MoveCharacterToNode(route, tile, unitSpeedOverride)


func PerformActionAtLocation():
	match(nextLocation):
		0:
			# Summon one or two gales depending on the state
			if galeSpawnStyle:
				var newLog : ActionLog = ActionLog.Construct(map.grid, unit, gale)
				newLog.actionDirection = GameSettingsTemplate.Direction.Down
				newLog.actionOriginTile = map.grid.GetTile(Vector2i(7,5)) # TODO: Expose this
				newLog.BuildStepResults()
				unit.QueueDelayedCombatAction(newLog)

				var secondLog : ActionLog = ActionLog.Construct(map.grid, unit, gale)
				secondLog.actionDirection = GameSettingsTemplate.Direction.Down
				secondLog.actionOriginTile = map.grid.GetTile(Vector2i(13,5)) # TODO: Expose this
				secondLog.BuildStepResults()
				unit.QueueDelayedCombatAction(secondLog)
				pass
			else:
				# summon one
				var newLog : ActionLog = ActionLog.Construct(map.grid, unit, gale)
				newLog.actionDirection = GameSettingsTemplate.Direction.Down
				newLog.actionOriginTile = map.grid.GetTile(Vector2i(10,5)) # TODO: Expose this
				newLog.BuildStepResults()
				unit.QueueDelayedCombatAction(newLog)
				pass

			galeSpawnStyle = !galeSpawnStyle
			pass
		1:
			# On the left
			var newLog : ActionLog = ActionLog.Construct(map.grid, unit, howlingWinds)
			newLog.actionDirection = GameSettingsTemplate.Direction.Right
			newLog.affectedTiles = howlingWinds.TargetingData.GetGlobalAttack(unit, map, newLog.actionDirection)
			newLog.actionOriginTile = unit.CurrentTile
			newLog.BuildStepResults()
			unit.QueueDelayedCombatAction(newLog)
			pass
		2:
			# on the right
			var newLog : ActionLog = ActionLog.Construct(map.grid, unit, howlingWinds)
			newLog.actionDirection = GameSettingsTemplate.Direction.Left
			newLog.affectedTiles = howlingWinds.TargetingData.GetGlobalAttack(unit, map, newLog.actionDirection)
			newLog.actionOriginTile = unit.CurrentTile
			newLog.BuildStepResults()
			unit.QueueDelayedCombatAction(newLog)
			pass
	pass

func InitializeLocations():
	availableLocations = [0,1,2]
	var indexOfCurrentLocation = availableLocations.find(currentLocation)
	if indexOfCurrentLocation != -1:
		availableLocations.remove_at(indexOfCurrentLocation)

	# this is predictable, so setting a seed will return the same value every time
	availableLocations.shuffle()

func RunTurn():
	if waitForMove:
		if unit.IsStackFree:
			PerformActionAtLocation()
			currentLocation = nextLocation
			unit.QueueEndTurn()
			waitForMove = false
