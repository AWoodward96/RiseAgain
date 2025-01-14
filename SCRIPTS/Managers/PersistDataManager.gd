extends Node2D


static var IN_RUN_DIRECTORY = "user://_RUN/"
static var GLOBAL_DIRECTORY = "user://_GLOBAL/"
static var SETTINGS_DIRECTORY = "user://_SETTINGS/"
static var UNITS_DIRECTORY = "user://_GLOBAL/Units/"


static var GLOBAL_FILE = "user://_GLOBAL/Universe.json"
static var CAMPAIGN_FILE = "user://_RUN/Campaign.json"
static var MAP_FILE = "user://_RUN/Map.json"
static var PERSIST_DATA_SUFFIX = "PersistData"
signal Initialized

var universeData : UniversePersistence
var campaignData : CampaignPersistence
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
	LoadCampaign()
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

func LoadCampaign():
	if FileAccess.file_exists(CAMPAIGN_FILE):
		# If file is null - there's no campaign being run. Null is fine
		var parsedString = GetJSONTextFromFile(CAMPAIGN_FILE)


	pass

func GetJSONTextFromFile(_path : String):
	# Validate this before hand - or don't I'm not your mom
	var save_file = FileAccess.open(_path, FileAccess.READ)
	# It should only be one line, but we'll see
	var fileText = save_file.get_as_text()
	return JSON.parse_string(fileText)

func ResourcePathToJSON(_array : Array):
	var arrayAsJSONString : Array[String]
	for resource in _array:
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
		var elementAsDict = JSON.parse_string(element)
		arrayAsVariant.append(_callable.call(elementAsDict))
	return arrayAsVariant

func SaveGame():
	print("Saving the game")
	# First save the universe file
	if universeData != null:
		universeData.Save()
	else:
		push_error("Universe Data is null when trying to save. Something went horribly wrong!")

	pass
