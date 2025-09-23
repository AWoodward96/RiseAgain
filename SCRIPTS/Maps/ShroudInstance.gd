extends Object
class_name ShroudInstance

var Tiles : Array[Tile]
var Exposed : Dictionary
var CurrentMap : Map

func UnitEntered(_tile : Tile, _unit : UnitInstance):
	var newAlert = false
	if !Exposed[_unit.UnitAllegiance]:
		Exposed[_unit.UnitAllegiance] = true
		newAlert = true
		# TODO: Remove when a better idea is found
		for tile in Tiles:
			# if there's a unit in these tiles, congrats you just got movement locked
			if tile.Occupant != null && tile.Occupant.UnitAllegiance != _unit.UnitAllegiance:
				if CurrentMap.playercontroller != null:
					CurrentMap.playercontroller.UnitMovedIntoShroud = true


	for tile in Tiles:
		if tile.Occupant != null:
			tile.Occupant.visual.UpdateShrouded()
			if tile.Occupant.UnitAllegiance != _unit.UnitAllegiance && newAlert:
				tile.Occupant.PlayAlertEmote()

	pass

func UnitExited(_unit : UnitInstance):
	if _unit == null:
		return

	var hasAllyInShroud = false
	for tile in Tiles:
		if tile.Occupant != null && tile.Occupant.UnitAllegiance == _unit.UnitAllegiance:
			hasAllyInShroud = true
			break

	if !hasAllyInShroud:
		Exposed[_unit.UnitAllegiance] = false

	for tile in Tiles:
		if tile.Occupant != null:
			tile.Occupant.visual.UpdateShrouded()

	# Because this is slow, it's best to handle the units own visual in the individual actions they do
	_unit.visual.UpdateShrouded()
	pass


static func Construct(_tiles : Array[Tile], _map : Map, _exposedAlly : bool = false, _exposedEnemy : bool = false, _exposedNeutral = false):
	var newShroud = ShroudInstance.new()
	newShroud.CurrentMap = _map
	newShroud.Tiles = _tiles
	for tile in newShroud.Tiles:
		tile.Shroud = newShroud
		if tile.Occupant != null:
			newShroud.UnitEntered(tile, tile.Occupant)

	newShroud.Exposed[GameSettingsTemplate.TeamID.ALLY] = _exposedAlly
	newShroud.Exposed[GameSettingsTemplate.TeamID.ENEMY] = _exposedEnemy
	newShroud.Exposed[GameSettingsTemplate.TeamID.NEUTRAL] = _exposedNeutral
	return newShroud
