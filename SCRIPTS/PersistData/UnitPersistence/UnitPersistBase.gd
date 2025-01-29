extends Node2D
class_name UnitPersistBase

@export var Template : UnitTemplate

@export var Alive : bool
@export var Unlocked : bool
@export var NameKnown : bool

@export var PrestiegeEXP : int
@export var PrestiegeLevel : int

@export var PrestiegeStatMods : Array[StatDef]
@export var UnallocatedPrestiege : int


func InitializeNew(_unitTemplate : UnitTemplate):
	Template = _unitTemplate
	Alive = true
	Unlocked = false
	NameKnown = false
	PrestiegeEXP = 0
	PrestiegeLevel = 0
	UnallocatedPrestiege = 0
	PrestiegeStatMods = []

	# we moddin this
	var testMod = StatDef.new()
	testMod.Template = GameManager.GameSettings.AttackStat
	testMod.Value = 1
	PrestiegeStatMods.append(testMod)

func GrantPrestiegeExp(_amount : int):
	PrestiegeEXP += _amount
	var prestiegeBreakpoint = GameManager.UnitSettings.GetPrestiegeBreakpoint(PrestiegeLevel)

	if PrestiegeEXP >= prestiegeBreakpoint:
		PrestiegeEXP -= prestiegeBreakpoint
		PrestiegeLevel += 1
		UnallocatedPrestiege += 1

	Save()

func AddPrestiegePoint(_statTemplate : StatTemplate):
	if UnallocatedPrestiege <= 0:
		return

	UnallocatedPrestiege -= 1
	for s in PrestiegeStatMods:
		if s.Template == _statTemplate:
			s.Value += 1
			return

	var newStatDef = StatDef.new()
	newStatDef.Template = _statTemplate
	newStatDef.Value = 1
	PrestiegeStatMods.append(newStatDef)
	Save()

func RemovePrestiegePoint(_statTemplate : StatTemplate):
	for s in PrestiegeStatMods:
		if s.Template == _statTemplate:
			if s.Value > 0:
				UnallocatedPrestiege += 1
				s.Value -= 1
	Save()


func GetPrestiegeStatMod(_statTemplate : StatTemplate):
	for stat in PrestiegeStatMods:
		if stat.Template == _statTemplate:
			return stat.Value
	return 0

func ToJSON():
	var returnDict = {
			"template" = Template.resource_path,
			"alive" = Alive,
			"unlocked" = Unlocked,
			"nameKnown" = NameKnown,
			"prestiegeEXP" = PrestiegeEXP,
			"prestiegeLevel" = PrestiegeLevel,
			"unallocatedPrestiege" = UnallocatedPrestiege,
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
	UnallocatedPrestiege = PersistDataManager.LoadFromJSON("unallocatedPrestiege", _dict) as int

	# The load from JSON gives an array of string, which is coincidentally what we need to feed into JSONToArray
	var statModString = PersistDataManager.LoadFromJSON("prestiegeStatMods", _dict)
	var data = PersistDataManager.JSONToArray(statModString, Callable.create(StatDef, "FromJSON"))
	PrestiegeStatMods.assign(data)

func Save():
	var unit_save_file = FileAccess.open(PersistDataManager.UNITS_DIRECTORY + Template.DebugName + ".json", FileAccess.WRITE)
	var unitSaveToJson = ToJSON()
	var stringifiedUnit = JSON.stringify(unitSaveToJson, "\t")
	unit_save_file.store_line(stringifiedUnit)

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
