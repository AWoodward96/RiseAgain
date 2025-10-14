extends Node2D
class_name UnitPersistBase

@export var Template : UnitTemplate

@export var Alive : bool
@export var Unlocked : bool
@export var Injured : bool
@export var NameKnown : bool

@export var PrestiegeEXP : int
@export var PrestiegeLevel : int

@export var PrestiegeStatMods : Array[StatDef]
@export var UnallocatedPrestiege : int

@export var EquippedStartingWeapon : AbilityUnlockable
@export var EquippedStartingTactical : AbilityUnlockable

var PrestiegeDisplayLevel : int :
	get():
		return PrestiegeLevel + 1


func InitializeNew(_unitTemplate : UnitTemplate):
	Template = _unitTemplate
	Alive = true
	Unlocked = _unitTemplate.startUnlocked
	NameKnown = _unitTemplate.startNameKnown
	PrestiegeEXP = 0
	PrestiegeLevel = 0
	UnallocatedPrestiege = 0
	PrestiegeStatMods = []

	EquippedStartingWeapon = _unitTemplate.StartingEquippedWeapon
	EquippedStartingTactical = _unitTemplate.StartingTactical


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

	var cap = 0
	for statCap in Template.PrestiegeCaps:
		if statCap.Template == _statTemplate:
			cap = statCap.Value
			break

	var needNew = true
	for s in PrestiegeStatMods:
		if s.Template == _statTemplate:
			needNew = false
			if s.Value < cap:
				UnallocatedPrestiege -= 1
				s.Value += 1
			return

	if needNew && cap > 0:
		var newStatDef = StatDef.new()
		UnallocatedPrestiege -= 1
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

func ChangeEquippedStartingWeapon(_abilityUnlockable : AbilityUnlockable):
	var ulkPersist = PersistDataManager.universeData.GetUnlockablePersist(_abilityUnlockable)
	if !ulkPersist.Unlocked:
		return

	if !_abilityUnlockable.Descriptors.has(GameManager.GameSettings.WeaponDescriptor):
		push_error("Trying to equip a weapon via an AbilityUnlockable that does not have a DES_Weapon decriptor. This is not allowed. Blocked.")
		return
	EquippedStartingWeapon = _abilityUnlockable
	Save()
	pass

func ChangeEquippedStartingTactical(_abilityUnlockable : AbilityUnlockable):
	var ulkPersist = PersistDataManager.universeData.GetUnlockablePersist(_abilityUnlockable)
	if !ulkPersist.Unlocked:
		return

	if !_abilityUnlockable.Descriptors.has(GameManager.GameSettings.TacticalDescriptor):
		push_error("Trying to equip a weapon via an AbilityUnlockable that does not have a DES_Weapon decriptor. This is not allowed. Blocked.")
		return
	EquippedStartingTactical = _abilityUnlockable
	Save()
	pass

func UnEquipStartingWeapon():
	EquippedStartingWeapon = null
	Save()
	pass

func UnEquipStartingTactical():
	EquippedStartingTactical = null
	Save()

func ToJSON():
	var returnDict = {
			"template" = Template.resource_path,
			"alive" = Alive,
			"unlocked" = Unlocked,
			"injured" = Injured,
			"nameKnown" = NameKnown,
			"prestiegeEXP" = PrestiegeEXP,
			"prestiegeLevel" = PrestiegeLevel,
			"unallocatedPrestiege" = UnallocatedPrestiege,
			"prestiegeStatMods" = PersistDataManager.ArrayToJSON(PrestiegeStatMods)
		}

	returnDict["equippedStartingTactical"] = EquippedStartingTactical.resource_path if EquippedStartingTactical != null else PersistDataManager.NULLSTRING
	returnDict["equippedStartingWeapon"] = EquippedStartingWeapon.resource_path if EquippedStartingWeapon != null else PersistDataManager.NULLSTRING
	return returnDict

# This is a seperate method than usual because this script can be inherrited
func InitFromJSON(_dict : Dictionary):
	Alive = PersistDataManager.LoadFromJSON("alive", _dict) as bool
	Unlocked = PersistDataManager.LoadFromJSON("unlocked", _dict) as bool
	NameKnown = PersistDataManager.LoadFromJSON("nameKnown", _dict) as bool
	PrestiegeEXP = PersistDataManager.LoadFromJSON("prestiegeEXP", _dict) as int
	PrestiegeLevel = PersistDataManager.LoadFromJSON("prestiegeLevel", _dict) as int
	UnallocatedPrestiege = PersistDataManager.LoadFromJSON("unallocatedPrestiege", _dict) as int
	Injured = PersistDataManager.LoadFromJSON("injured", _dict) as bool

	if _dict["equippedStartingWeapon"] == PersistDataManager.NULLSTRING:
		EquippedStartingWeapon = null
	else:
		var weap  = load(_dict["equippedStartingWeapon"]) as AbilityUnlockable
		if weap != null:
			EquippedStartingWeapon = weap
		else:
			push_error("Failed to load starting tactical at path: ", _dict["equippedStartingWeapon"])
			EquippedStartingWeapon = null

	if _dict["equippedStartingTactical"] == PersistDataManager.NULLSTRING:
		EquippedStartingWeapon = null
	else:
		var tact = load(_dict["equippedStartingTactical"]) as AbilityUnlockable
		if tact != null:
			EquippedStartingTactical = tact
		else:
			push_error("Failed to load starting tactical at path: ", _dict["equippedStartingTactical"])
			EquippedStartingTactical = null


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
		if ut == null:
			return null

		var persistType = ut.persistDataScript
		if persistType == null:
			persistType = UnitPersistBase

		var persist = persistType.new()
		persist.Template = ut
		persist.InitFromJSON(_dict)

		return persist
	return null
