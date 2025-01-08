extends Node2D
class_name UnitPersistBase

@export var Template : UnitTemplate

@export var Alive : bool
@export var Unlocked : bool
@export var NameKnown : bool

@export var PrestiegeEXP : int
@export var PrestiegeLevel : int

@export var PrestiegeStatMods : Array[StatDef]



func InitializeNew(_unitTemplate : UnitTemplate):
	Template = _unitTemplate
	Alive = true
	Unlocked = false
	NameKnown = false
	PrestiegeEXP = 0
	PrestiegeLevel = 0
	PrestiegeStatMods = []

	var testMod = StatDef.new()
	testMod.Template = GameManager.GameSettings.AttackStat
	testMod.Value = 1
	PrestiegeStatMods.append(testMod)

func ToJSON():
	var returnDict = {
			"template" = Template.resource_path,
			"alive" = Alive,
			"unlocked" = Unlocked,
			"nameKnown" = NameKnown,
			"prestiegeEXP" = PrestiegeEXP,
			"prestiegeLevel" = PrestiegeLevel,
			"prestiegeStatMods" = PersistDataManager.ArrayToJSON(PrestiegeStatMods)
		}
	return returnDict

# This is a seperate method than usual because this script can be inherrited
func InitFromJSON(_dict : Dictionary):
	Alive = PersistDataManager.LoadFromJSON("alive", _dict) as bool
	Unlocked = PersistDataManager.LoadFromJSON("unlocked", _dict) as bool
	NameKnown = PersistDataManager.LoadFromJSON("nameKnown", _dict) as bool
	PrestiegeEXP = PersistDataManager.LoadFromJSON("prestiegeEXP", _dict) as int
	PrestiegeLevel = PersistDataManager.LoadFromJSON("prestiegeLevel", _dict) as int

	# The load from JSON gives an array of string, which is coincidentally what we need to feed into JSONToArray
	var statModString = PersistDataManager.LoadFromJSON("prestiegeStatMods", _dict)
	var data = PersistDataManager.JSONToArray(statModString, Callable.create(StatDef, "FromJSON"))
	PrestiegeStatMods.assign(data)


static func FromJSON(_dict : Dictionary):
	var templateSTR = PersistDataManager.LoadFromJSON("template", _dict)
	if templateSTR != null:
		var ut = load(templateSTR) as UnitTemplate
		var persistType = ut.persistDataScript
		if persistType == null:
			persistType = UnitPersistBase

		var persist = persistType.new()
		persist.Template = ut
		persist.InitFromJSON(_dict)

		return persist
	return null
