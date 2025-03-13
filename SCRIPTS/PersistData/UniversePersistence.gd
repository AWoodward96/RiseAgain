extends Node2D
class_name UniversePersistence

static var NODENAME = "UniversePersistData"

var resourceData : Array[ResourcePersistence]
var bastionData : BastionPersistData
var unitPersistData : Array[UnitPersistBase]

var completedCutscenes : Array[CutsceneTemplate]

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


func IsStartingCutsceneCompleted():
	return completedCutscenes.has(CutsceneManager.FTUE)

func ToJSON():
	var saveData = {
		"resourceData" = PersistDataManager.ArrayToJSON(resourceData),
		"bastionData" = bastionData.ToJSON()
	}

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

	universePersist.bastionData = BastionPersistData.new()
	universePersist.bastionData.name = "BastionPersistData"
	universePersist.add_child(universePersist.bastionData)
	return universePersist
