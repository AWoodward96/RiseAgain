extends Node2D
class_name BastionPersistData

var TavernRoomNumbers : Array[int] = [101, 102, 103, 201, 202, 203, 204, 205, 206]
var DayComplete : bool

# TODO: Figure out persist data for bastion stuff
# There are upgrades for each building - so maybe a base class could see usage
# Or to keep things simple maybe this would have everything in it? Ionno

var UnitsInTavern : Array[UnitTemplate]		# Which units are in the tavern
var UnitsInCampsite : Array[UnitTemplate]		# Which units are staying at the campsite. These are always equal to the last units you played with
var SelectedRoster : Array[UnitTemplate]		# Wich units are you taking with you
var TavernLevel : int = 0
var MaxUnitsInRosterAllowed : int = 2

func GenerateTavernOccupants(_availableSlots : int, _garunteedUnits : Array[UnitTemplate]):
	# NOTE: At some point this is going to change - based on a bunch of conditions I don't know about yet
	# So keep this method in mind and update accordingly

	# In order for a unit to show up at the tavern, they need to be unlocked, and alive.
	# If they aren't, then a 'husk' version of them will show up, that has no face, and no story, and has a worse stat growth then they usually do
	# That way players can still use the content I have set up in the early game, and have something to look forward to later

	var allUnits = GameManager.UnitSettings.AllyUnitManifest.duplicate()
	var garunteedCopy = _garunteedUnits.duplicate()

	# this isn't seeded but we could seed it if we wanted to.... Up to you
	allUnits.shuffle()

	UnitsInTavern.clear()
	for i in _availableSlots:
		if garunteedCopy.size() == 0:
			UnitsInTavern.append(allUnits.pop_front())
		else:
			UnitsInTavern.append(garunteedCopy.pop_front())

	PersistDataManager.SaveGame()
	pass

func TryAddUnitToRoster(_unitTemplate : UnitTemplate):
	if SelectedRoster.size() < MaxUnitsInRosterAllowed && !SelectedRoster.has(_unitTemplate):
		SelectedRoster.append(_unitTemplate)
		return true
	return false

func TryRemoveUnitFromRoster(_unitTemplate : UnitTemplate):
	if SelectedRoster.has(_unitTemplate):
		var indexOf = SelectedRoster.find(_unitTemplate)
		SelectedRoster.remove_at(indexOf)
		return true
	return false

func ToJSON():
	var returnDict = {
		"UnitsInTavern" = PersistDataManager.ResourcePathToJSON(UnitsInTavern),
		"SelectedRoster" = PersistDataManager.ResourcePathToJSON(SelectedRoster),
		"UnitsInCampsite" = PersistDataManager.ResourcePathToJSON(UnitsInCampsite),
		"DayComplete" = DayComplete
	}
	return returnDict

func FromJSON(_dict : Dictionary):
	PersistDataManager.JSONtoResourceFromPath(_dict["UnitsInTavern"], UnitsInTavern)
	PersistDataManager.JSONtoResourceFromPath(_dict["SelectedRoster"], SelectedRoster)
	PersistDataManager.JSONtoResourceFromPath(_dict["UnitsInCampsite"], UnitsInCampsite)
	if _dict.has("DayComplete"): DayComplete = _dict["DayComplete"]
	pass
