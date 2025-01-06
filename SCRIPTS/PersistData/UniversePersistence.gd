extends Node2D
class_name UniversePersistence

static var NODENAME = "UniversePersistData"

var resourceData : Array[ResourcePersistence]
var bastionData : BastionPersistData

var resourcePersistParent : Node2D

func CreateParents():
	resourcePersistParent = Node2D.new()
	resourcePersistParent.name = "Resources"
	add_child(resourcePersistParent)

func ToJSON():
	var saveData = {
		"resourceData" = PersistDataManager.ArrayToJSON(resourceData)
	}
	return saveData

func FromJSON(_dict : Dictionary):
	CreateParents()
	var returnedArray = PersistDataManager.JSONToArray(_dict["resourceData"], Callable.create(ResourcePersistence, "FromJSON"))
	resourceData.assign(returnedArray)
	for r in resourceData:
		r.name = r.template.internalName + PersistDataManager.PERSIST_DATA_SUFFIX
		resourcePersistParent.add_child(r)
	pass

func Save():
	var save_file = FileAccess.open(PersistDataManager.GLOBAL_FILE, FileAccess.WRITE)
	var toJSON = ToJSON()
	var stringify = JSON.stringify(toJSON, "\t")
	save_file.store_line(stringify)

static func CreateNewUniversePersist():
	var universePersist = UniversePersistence.new()
	universePersist.CreateParents()
	universePersist.name = NODENAME
	PersistDataManager.add_child(universePersist)

	for resource in GameManager.GameSettings.GlobalResources:
		var newResourcePersist = ResourcePersistence.new()
		newResourcePersist.template = resource
		newResourcePersist.amount = 0
		newResourcePersist.name = resource.internalName + PersistDataManager.PERSIST_DATA_SUFFIX
		universePersist.resourceData.append(newResourcePersist)
		universePersist.resourcePersistParent.add_child(newResourcePersist)

	return universePersist
