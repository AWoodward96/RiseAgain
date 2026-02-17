extends Resource
class_name AIBehaviorBase

var map : Map
var unit : UnitInstance

var grid : Grid

var attacked : bool = false
var selectedPath : Array[Tile]
var selectedTile : Tile

var tauntedBy : UnitInstance


func StartTurn(_map : Map, _unit : UnitInstance):
	pass

func CommonStartTurn(_map : Map, _unit : UnitInstance):
	# Because Behaviors are Resources, and because common Behaviors are shared between units
	# It's really important to manually set these at the start of each turn, or else you'll get some wonkyness

	unit = _unit
	map = _map
	grid = _map.grid

	attacked = false
	unit.QueueTurnStartDelay()
	TauntCheck(unit)

func RunTurn():
	pass

func TauntCheck(_affectedUnit : UnitInstance):
	tauntedBy = null
	for ce in _affectedUnit.CombatEffects:
		# We don't check is-expired here because on turn start it'll be at 0.
		if ce is TauntEffectInstance:
			tauntedBy = ce.SourceUnit
			return


func TruncatePathBasedOnMovement(_path, _currentMovement):
	selectedPath = _path
	selectedPath = selectedPath.slice(0, _currentMovement)

	var indexedSize = selectedPath.size() - 1
	if indexedSize == -1:
		return true
	selectedTile = selectedPath[indexedSize]

	if selectedTile.Occupant != null:
		while selectedTile.Occupant != null:
			# Well shit now we're in trouble
			# walk backwards from the current index
			indexedSize -= 1
			if indexedSize < 0:
				# if we've hit 0, then there are a whole bunch of units all in the way of this unit, so just end turn
				#unit.QueueEndTurn()
				return false

			selectedTile = selectedPath[indexedSize]
			selectedPath.remove_at(selectedPath.size() - 1)
	return true
