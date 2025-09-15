extends Node2D
class_name UniversePersistence

static var NODENAME = "UniversePersistData"

var resourceData : Array[ResourcePersistence]
var bastionData : BastionPersistData
var unitPersistData : Array[UnitPersistBase]

var completedCutscenes : Array[CutsceneTemplate]
var unlockPersistData : Dictionary = {}


# map persistence is a dictionary of a dictionary, where the key is the maps resource_path and the value is a dictionary
var mapPersistData : Dictionary = {}

var resourcePersistParent : Node2D
var unitPersistParent : Node2D

func CreateParents():
	resourcePersistParent = Node2D.new()
	resourcePersistParent.name = "Resources"
	add_child(resourcePersistParent)

	unitPersistParent = Node2D.new()
	unitPersistParent.name = "Units"
	add_child(unitPersistParent)

func GrantPrestiegeExp(_unitTemplate : UnitTemplate, _amount : int):
	var persist = GetUnitPersistence(_unitTemplate) as UnitPersistBase
	if persist != null:
		if persist.Alive:
			persist.GrantPrestiegeExp(_amount)
	Save()

func GetUnitPersistence(_unitTemplate : UnitTemplate):
	for u in unitPersistData:
		if u.Template == _unitTemplate:
			return u

	return null

func GetListOfUnlockData(_reqUnlocked : bool = false, _filters : Array[DescriptorTemplate] = []):
	var returnPersist : Array[UnlockableContentTemplate]
	for keypair : UnlockableContentTemplate in unlockPersistData:
		if !unlockPersistData[keypair].Unlocked && _reqUnlocked:
			continue

		# keypair should in and of itself be a UnlockableTemplate
		var passesFilter = true
		for f in _filters:
			if f == null:
				continue

			if !keypair.Descriptors.has(f):
				passesFilter = false
				break

		if passesFilter:
			returnPersist.append(keypair)

	return returnPersist

func IsStartingCutsceneCompleted():
	return completedCutscenes.has(CutsceneManager.FTUE)

func AddResource(_resourceDef : ResourceDef, _sourcePosition : Vector2, _autoPlayAquisitionAnimation : bool = true):
	for res in resourceData:
		if res.template == _resourceDef.ItemResource:
			res.amount += _resourceDef.Amount

	if _autoPlayAquisitionAnimation:
		UIManager.GlobalUIInstance.ShowResourceAcquisition(_sourcePosition)

func AddResources(_arrayOfResources : Array[ResourceDef], _sourcePosition : Vector2, _autoPlayAquisitionAnimation : bool = true):
	for res in _arrayOfResources:
		AddResource(res, _sourcePosition, false)

	if _autoPlayAquisitionAnimation:
		UIManager.GlobalUIInstance.ShowResourceAcquisition(_sourcePosition)

func AddPackedResources(_packedResource : PackedResourceDef, _sourcePosition : Vector2, _autoPlayAquisitionAnimation : bool = true):
	AddResources(_packedResource.cost, _sourcePosition, _autoPlayAquisitionAnimation)

func GetResourceData(_resourceTemplate : ResourceTemplate):
	for r in resourceData:
		if r.template == _resourceTemplate:
			return r

	# debating this - I think if I have a strict set of resources then I should block adding new definitions
	# This
	push_error("Could not find resource: [", _resourceTemplate.resource_path, "] is this in error?")
	return null

func TryPayResourceCost(_cost : Array[ResourceDef], _success : Callable, _failure : Callable):
	if HasResourceCost(_cost):
		for c in _cost:
			var persist = GetResourceData(c.ItemResource)
			if persist != null:
				persist.amount -= c.Amount

		UIManager.GlobalUIInstance.ShowResourcePayment(_cost)
		_success.call()

		# AutoSave if paid
		Save()
	else:
		if _failure != null:
			_failure.call()

func TryPayPackedResourceCost(_packedResource : PackedResourceDef, _success : Callable, _failure : Callable):
	return TryPayResourceCost(_packedResource.cost, _success, _failure)

func HasResourceCost(_cost : Array[ResourceDef]):
	for cost in _cost:
		if cost == null || cost.ItemResource == null || cost.Amount <= 0:
			continue

		for res in resourceData:
			if res.template == cost.ItemResource:
				if res.amount < cost.Amount:
					return false
	return true

func HasPackedResourceCost(_packedResource : PackedResourceDef):
	return HasResourceCost(_packedResource.cost)

func GetUnlockablePersist(_unlockable : UnlockableContentTemplate):
	if unlockPersistData.has(_unlockable):
		return unlockPersistData[_unlockable]
	else:
		var newPersit = _unlockable.CreatePersistData()
		unlockPersistData[_unlockable] = newPersit
		return newPersit

func UnlockUnlockable(_unlockable : UnlockableContentTemplate):
	var persit = GetUnlockablePersist(_unlockable)
	persit.Unlocked = true

func ToJSON():
	var saveData = {
		"resourceData" = PersistDataManager.ArrayToJSON(resourceData),
		"bastionData" = bastionData.ToJSON(),
		"mapPersistData" = JSON.stringify(mapPersistData)
	}

	var contentDict = {}
	for keypair in unlockPersistData:
		# So I need to convert this keypair into a stringified json
		contentDict[keypair.resource_path] = unlockPersistData[keypair].ToJSON()
		pass

	saveData["unlockPersistData"] = JSON.stringify(contentDict)

	var ar : Array[String] = []
	for c in completedCutscenes:
		ar.append(c.resource_path)

	saveData["completedCutscenes"] = ar
	return saveData

func FromJSON(_dict : Dictionary):
	CreateParents()

	# initialize the resources
	var returnedArray = PersistDataManager.JSONToArray(_dict["resourceData"], Callable.create(ResourcePersistence, "FromJSON"))
	resourceData.assign(returnedArray)
	for r in resourceData:
		r.name = r.template.internalName + PersistDataManager.PERSIST_DATA_SUFFIX
		resourcePersistParent.add_child(r)

	if _dict.has("bastionData"):
		bastionData = BastionPersistData.new()
		bastionData.FromJSON(_dict["bastionData"])
		bastionData.name = "BastionPersistData"
		add_child(bastionData)

	if _dict.has("completedCutscenes"):
		for res in _dict["completedCutscenes"]:
			var loadedCutscene = load(res) as CutsceneTemplate
			if loadedCutscene != null:
				completedCutscenes.append(loadedCutscene)

	if _dict.has("mapPersistData"):
		mapPersistData = JSON.parse_string(_dict["mapPersistData"])

	if _dict.has("unlockPersistData"):
		var str = JSON.parse_string(_dict["unlockPersistData"])
		for key in str:
			var load = load(key)
			unlockPersistData[load] = UnlockablePersistData.FromJSON(str[key])


	# just in case I add a new resource - players don't have to delete their universe data
	ValidateGlobalResource()
	ValidateULKs() # same with ulks
	pass

func LoadUnitPersistence():
	var dir = DirAccess.open(PersistDataManager.UNITS_DIRECTORY)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while(file_name != ""):
			if !dir.current_is_dir():
				var path = dir.get_current_dir() + "/" + file_name
				var save_file = FileAccess.open(path, FileAccess.READ)

				# It should only be one line, but we'll see
				var fileText = save_file.get_as_text()
				var parsedString = JSON.parse_string(fileText)
				var persist = UnitPersistBase.FromJSON(parsedString)
				if persist == null:
					push_error("Could not load Unit Persistence for dict: " + parsedString["template"])
					file_name = dir.get_next()
					continue

				persist.name = persist.Template.DebugName + PersistDataManager.PERSIST_DATA_SUFFIX
				unitPersistParent.add_child(persist)
				unitPersistData.append(persist)
			file_name = dir.get_next()

	pass

func ValidateGlobalResource():
	for resource in GameManager.GameSettings.GlobalResources:
		var persist = GetResourceData(resource)
		if persist == null:
			var newResourcePersist = ResourcePersistence.new()
			newResourcePersist.template = resource
			newResourcePersist.amount = 0
			newResourcePersist.name = resource.internalName + PersistDataManager.PERSIST_DATA_SUFFIX
			resourceData.append(newResourcePersist)
			resourcePersistParent.add_child(newResourcePersist)

func ValidateULKs():
	var dir = ResourceLoader.list_directory(PersistDataManager.UNLOCKS_DIRECTORY)
	for resourcestring in dir:
		var concat = str(PersistDataManager.UNLOCKS_DIRECTORY, resourcestring)
		var load = load(concat) as UnlockableContentTemplate
		if !unlockPersistData.has(load):
			unlockPersistData[load] = load.CreatePersistData()
		else:
			# If I decide at some point to make an unlockable start unlocked then I shouldn't have
			# to delete my save file in order to obtain it
			if load.StartUnlocked && !unlockPersistData[load].Unlocked:
				unlockPersistData[load].Unlocked = true

func Save():
	var save_file = FileAccess.open(PersistDataManager.GLOBAL_FILE, FileAccess.WRITE)
	var toJSON = ToJSON()
	var stringify = JSON.stringify(toJSON, "\t")
	save_file.store_line(stringify)

	for unitPersist in unitPersistData:
		unitPersist.Save()

static func CreateNewUniversePersist():
	var universePersist = UniversePersistence.new()
	universePersist.CreateParents()
	universePersist.name = NODENAME
	PersistDataManager.add_child(universePersist)

	# Create all of the resource persist data
	for resource in GameManager.GameSettings.GlobalResources:
		var newResourcePersist = ResourcePersistence.new()
		newResourcePersist.template = resource
		newResourcePersist.amount = 0
		newResourcePersist.name = resource.internalName + PersistDataManager.PERSIST_DATA_SUFFIX
		universePersist.resourceData.append(newResourcePersist)
		universePersist.resourcePersistParent.add_child(newResourcePersist)

	# Create all of the unit persist data
	for ut in GameManager.UnitSettings.AllyUnitManifest:
		var scriptType = ut.persistDataScript
		if scriptType == null:
			scriptType = UnitPersistBase

		var persistData = scriptType.new()
		persistData.InitializeNew(ut)
		persistData.name = ut.DebugName + PersistDataManager.PERSIST_DATA_SUFFIX
		universePersist.unitPersistData.append(persistData)
		universePersist.unitPersistParent.add_child(persistData)

		pass

	# Create all the unlockable content data
	var dir = ResourceLoader.list_directory(PersistDataManager.UNLOCKS_DIRECTORY)
	for resourcestring in dir:
		var concat = str(PersistDataManager.UNLOCKS_DIRECTORY, resourcestring)
		var load = load(concat)
		universePersist.unlockPersistData[load] = load.CreatePersistData()


	universePersist.bastionData = BastionPersistData.new()
	universePersist.bastionData.name = "BastionPersistData"
	universePersist.add_child(universePersist.bastionData)
	return universePersist
