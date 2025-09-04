extends Node2D

var BlockUniverseSave : bool = false
var BlockCampaignSave : bool = false
var BlockMapSave : bool = false

static var IN_RUN_DIRECTORY = "user://_RUN/"
static var GLOBAL_DIRECTORY = "user://_GLOBAL/"
static var SETTINGS_DIRECTORY = "user://_SETTINGS/"
static var UNITS_DIRECTORY = "user://_GLOBAL/Units/"

static var GLOBAL_FILE = "user://_GLOBAL/Universe.json"
static var CAMPAIGN_FILE = "user://_RUN/Campaign.json"
static var CAMPAIGN_CONVOY_DIRECTORY = "user://_RUN/Convoy/"
static var MAP_FILE = "user://_RUN/Map.json"
static var MAP_GRID_FILE = "user://_RUN/Grid.json"
static var PERSIST_DATA_SUFFIX = "PersistData"


static var UNLOCKS_DIRECTORY = "res://RESOURCES/Unlocks/"

signal Initialized

var universeData : UniversePersistence
var campaign : Campaign
var mapData : MapPersistence


func _ready():
	ValidateDirectories()
	LoadPersistData()
	Initialized.emit()

func ValidateDirectories():
	var dir = DirAccess.open("user://")
	if !dir.dir_exists(IN_RUN_DIRECTORY):
		DirAccess.make_dir_absolute(IN_RUN_DIRECTORY)

	if !dir.dir_exists(GLOBAL_DIRECTORY):
		DirAccess.make_dir_absolute(GLOBAL_DIRECTORY)

	if !dir.dir_exists(SETTINGS_DIRECTORY):
		DirAccess.make_dir_absolute(SETTINGS_DIRECTORY)

	if !dir.dir_exists(UNITS_DIRECTORY):
		DirAccess.make_dir_absolute(UNITS_DIRECTORY)


func LoadFromJSON(_key : String, _dict : Dictionary):
	if _dict.has(_key):
		return _dict[_key]
	return null

func LoadPersistData():
	LoadUniverse()

	# Campaign Should be loaded by game manager if there is a campaign active
	#TryLoadCampaign()
	pass

func LoadUniverse():
	if !FileAccess.file_exists(GLOBAL_FILE):
		universeData = UniversePersistence.CreateNewUniversePersist()
		universeData.bastionData.GenerateTavernOccupants(3, [] as Array[UnitTemplate])
	else:
		var parsedString = GetJSONTextFromFile(GLOBAL_FILE)
		universeData = UniversePersistence.new()
		universeData.name = UniversePersistence.NODENAME
		add_child(universeData)
		universeData.FromJSON(parsedString)
		universeData.LoadUnitPersistence()

func TryLoadCampaign():
	if FileAccess.file_exists(CAMPAIGN_FILE):
		# If file is null - there's no campaign being run. Null is fine
		var parsedString = GetJSONTextFromFile(CAMPAIGN_FILE)
		if parsedString == null:
			return null

		campaign = Campaign.FromJSON(parsedString)
		campaign.name = "LoadedCampaign"

		return campaign

	return null

func GetJSONTextFromFile(_path : String):
	# Validate this before hand - or don't I'm not your mom
	var save_file = FileAccess.open(_path, FileAccess.READ)
	# It should only be one line, but we'll see
	var fileText = save_file.get_as_text()
	return JSON.parse_string(fileText)

func ResourcePathToJSON(_array : Array):
	var arrayAsJSONString : Array[String]
	for resource in _array:
		if resource == null:
			continue

		arrayAsJSONString.append(resource.resource_path)
	return arrayAsJSONString

func JSONtoResourceFromPath(_array, _assignedArrayType : Array):
	_assignedArrayType.clear()
	var temp = []
	for path in _array:
		temp.append(load(path))

	_assignedArrayType.assign(temp)

func ArrayToJSON(_array : Array[Variant]):
	var arrayAsJSONString : Array[String]
	for element in _array:
		if element == null:
			arrayAsJSONString.append("NULL")
			continue

		if element.has_method("ToJSON"):
			var elementAfterToJSON = element.ToJSON()
			if elementAfterToJSON is Dictionary:
				arrayAsJSONString.append(JSON.stringify(elementAfterToJSON, "\t"))
			elif elementAfterToJSON is String:
				arrayAsJSONString.append(elementAfterToJSON)
			else:
				print("Could not figure out what the element after ToJSON was called. You should fix this. " + str(element))
	return arrayAsJSONString

func JSONToArray(_array, _callable : Callable):
	var arrayAsVariant : Array[Variant]
	for element in _array:
		if element == "NULL":
			arrayAsVariant.append(null)
			continue

		var elementAsDict = JSON.parse_string(element)
		arrayAsVariant.append(_callable.call(elementAsDict))
	return arrayAsVariant

func SaveNodeAsResource(_nodeObject : Node2D, _path : String):
	var scene = PackedScene.new()
	scene.pack(_nodeObject)
	ResourceSaver.save(scene, _path)

func SaveArrayOfNodesAsResource(_array : Array, _pathFolder : String, _fileNameBase : String):
	# be careful about this
	DirAccess.make_dir_absolute(_pathFolder)

	# Clear out this directory so we don't have duplicates
	for file in DirAccess.get_files_at(_pathFolder):
		DirAccess.remove_absolute(file)

	var index = 0
	for ar in _array:
		SaveNodeAsResource(ar, _pathFolder + _fileNameBase + "_" + str(index) + ".tscn")

func LoadArrayOfResourcesAsNodes(_pathFolder : String, _assignedArrayType : Array[Variant], _autoAssignedParent : Node = null):
	var tempArray : Array[Variant]
	var dir = DirAccess.open(_pathFolder)

	# These are the names of the files though, and I hate this officially
	var files = dir.get_files()
	for fileName in files:
		var filePath = _pathFolder + fileName
		var loadedResource = load(filePath) # This should be a packed scene but it could be anything really
		if loadedResource == null:
			continue

		var instance = loadedResource.instantiate()
		if _autoAssignedParent != null:
			_autoAssignedParent.add_child(instance)

		tempArray.append(instance)

	# once everything is loaded, assign it to the array
	_assignedArrayType.resize(tempArray.size())
	_assignedArrayType.assign(tempArray)

func ClearCampaign():
	campaign = null

	universeData.bastionData.ActiveMeal = null
	DirAccess.remove_absolute(CAMPAIGN_FILE)

	# when we clear the campaign, we should also clear the map
	DirAccess.remove_absolute(MAP_FILE)
	DirAccess.remove_absolute(MAP_GRID_FILE)


func GetMapPersistData(_map : Map):
	if _map == null:
		return {}

	var objectPersist = str(ResourceLoader.get_resource_uid(_map.scene_file_path))
	if universeData != null && universeData.mapPersistData.has(objectPersist):
		return universeData.mapPersistData[objectPersist]

	return {}


func SaveMapPersistData(_map : Map, _dict : Dictionary, _autoSave : bool):
	if _map == null:
		return

	var resourceUID = str(ResourceLoader.get_resource_uid(_map.scene_file_path))
	if universeData != null:
		universeData.mapPersistData[resourceUID] = _dict

	# be careful with autosave, if a player can exploit it by saving and reloading
	if !BlockUniverseSave && _autoSave:
		universeData.Save()


func SaveGame():
	# First save the universe file
	if universeData != null:
		if !BlockUniverseSave:
			print("Saving universe")
			universeData.Save()
	else:
		push_error("Universe Data is null when trying to save. Something went horribly wrong!")

	SaveCampaign()
	pass

func SaveCampaign():
	if GameManager.CurrentCampaign != null:
		if !BlockCampaignSave:
			print("Saving campaign")
			GameManager.CurrentCampaign.Save()
	else:
		ClearCampaign()

func SaveMap():
	if Map.Current != null:
		if !BlockMapSave:
			print("Map Saved")
			Map.Current.Save()
	pass


static func String_To_Vector2i(_string : String):
	if _string.is_empty():
		return Vector2i.ZERO

	var copy = _string
	# This gets rid of the ()
	copy.erase(0, 1)
	copy.erase(copy.length() - 1, 1)
	var valuesArray = copy.split(", ") # space included bc of formatting
	return Vector2i(int(valuesArray[0]), int(valuesArray[1]))

static func String_To_Vector2(_string : String):
	if _string.is_empty():
		return Vector2i.ZERO

	var copy = _string
	# This gets rid of the ()
	copy.erase(0, 1)
	copy.erase(copy.length() - 1, 1)
	var valuesArray = copy.split(", ") # space included bc of formatting
	return Vector2(int(valuesArray[0]), int(valuesArray[1]))
