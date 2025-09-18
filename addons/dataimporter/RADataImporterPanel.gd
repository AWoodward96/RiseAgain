@tool
extends Panel
class_name RADataImporterPanel

const Units_Dir = "res://RESOURCES/Units"
const Items_Dir = "res://RESOURCES/Items"
const Unlocks_DIR = "res://RESOURCES/Unlocks"
const Ability_Dir = "res://RESOURCES/Ability"
const AbilityWeapon_Dir = "res://RESOURCES/Ability/Equippable"
const AbilityTactial_Dir = "res://RESOURCES/Ability/Tactical"
const AbilityStandard_Dir = "res://RESOURCES/Ability/Standard"
const Descriptors_Dir = "res://RESOURCES/Descriptors"
const VulnerableDescriptors_Dir = "res://RESOURCES/Descriptors/Vulnerabilities"
const LootTable_Dir = "res://RESOURCES/LootTable"
const TargetingShapes_Dir = "res://RESOURCES/TargetingShapes"
const stat_dict = {
	"Vitality" : "res://RESOURCES/Stats/STAT_Vitality.tres",
	"Attack" : "res://RESOURCES/Stats/STAT_Attack.tres",
	"Defense" : "res://RESOURCES/Stats/STAT_Defense.tres",
	"SpAttack" : "res://RESOURCES/Stats/STAT_SpAttack.tres",
	"SpDefense" : "res://RESOURCES/Stats/STAT_SpDefense.tres",
	"Movement" : "res://RESOURCES/Stats/STAT_Movement.tres",
	"Skill" : "res://RESOURCES/Stats/STAT_Skill.tres",
	"Mind" : "res://RESOURCES/Stats/STAT_Mind.tres",
	"Luck" : "res://RESOURCES/Stats/STAT_Luck.tres",
	"Health" : "res://RESOURCES/Stats/STAT_Health.tres",
	"Dexterity" : "res://RESOURCES/Stats/STAT_Dexterity.tres",
	"Wisdom" : "res://RESOURCES/Stats/STAT_Wisdom.tres"
}

const affinity_dict = {
	"Water" : "res://RESOURCES/Affinity/Water_Affinity.tres",
	"Fire" : "res://RESOURCES/Affinity/Fire_Affinity.tres",
	"Grass" : "res://RESOURCES/Affinity/Grass_Affinity.tres",
	"Metal" : "res://RESOURCES/Affinity/Metal_Affinity.tres",
	"Earth" : "res://RESOURCES/Affinity/Earth_Affinity.tres",
	"Light" : "res://RESOURCES/Affinity/Light_Affinity.tres",
	"Dark" : "res://RESOURCES/Affinity/Dark_Affinity.tres",
	"Maggai" : "res://RESOURCES/Affinity/Maggai_Affinity.tres"
}


@export var sheetID : LineEdit
@export var sheetName : LineEdit
@export var previewText : TextEdit
@export var errorPanel : RichTextLabel

var Parent : RADataImporterEditor
var HTTPRequester : HTTPRequest
var modifiedStack : Array[String]


var itemNameArray : Array[String]
var itemPathArray : Array[String]

var lootTableArray : Array[String]
var lootTablePathArray : Array[String]

var unitNameArray : Array[String]
var unitPathArray : Array[String]

var weaponNameArray : Array[String]
var weaponPathArray : Array[String]

var tacticalNameArray : Array[String]
var tacticalPathArray : Array[String]

var abilityNameArray : Array[String]
var abilityPathArray : Array[String]

var descriptorNameArray : Array[String]
var descriptorPathArray : Array[String]

var vulnerabilityNameArray : Array[String]
var vulnerabilityPathArray : Array[String]

var shapedPrefabNameArray : Array[String]
var shapedPrefabPathArray : Array[String]

var unlockableNameArray : Array[String]
var unlockablePathArray : Array[String]

var log
var cachedJSON
var apiFileLocation = "C:/Users/Sage/import_api.txt"
var apiURL : String = ""


func BuildGetURL(_sheetName : String, _sheetID : String):
	return apiURL + "?sheetname=" + _sheetName + "&sheetid=" + _sheetID

func Initialize(_parent : RADataImporterEditor, _httpRequester : HTTPRequest):
	Parent = _parent
	HTTPRequester = _httpRequester

	# Store the api string as an actual file on your computer because version control is public :)
	var file = FileAccess.open(apiFileLocation, FileAccess.READ)
	apiURL = file.get_as_text()

func OnPollButtton():
	print("Poll Button Pressed")
	Parent.OnJSONParsed.connect(PreviewDataFromJSON)
	HTTPRequester.request(BuildGetURL(sheetName.text, sheetID.text))
	previewText.text = "Waiting for Response..."

func OnImportButton():
	log = ""
	import_data_from_json(cachedJSON)

func PreviewDataFromJSON(_data):
	Parent.OnJSONParsed.disconnect(PreviewDataFromJSON)

	print("Data recieved")
	previewText.text = JSON.stringify(_data, "\t")
	cachedJSON = _data

func import_data_from_json(_data):
	pass

func GetAllFilesFromPath(path):
	var file_paths: Array[String] = []
	var dir = DirAccess.open(path)
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		var file_path = path + "/" + file_name
		if dir.current_is_dir():
			file_paths += GetAllFilesFromPath(file_path)
		else:
			file_paths.append(file_path)
		file_name = dir.get_next()
	return file_paths

func ConstructItemMapping():
	ConstructMapping(Items_Dir, itemPathArray, itemNameArray)

func ConstructAbilityMapping():
	ConstructMapping(AbilityWeapon_Dir, weaponPathArray, weaponNameArray)
	ConstructMapping(AbilityTactial_Dir, tacticalPathArray, tacticalNameArray)
	ConstructMapping(AbilityStandard_Dir, abilityPathArray, abilityNameArray)
	ConstructMapping(TargetingShapes_Dir, shapedPrefabPathArray, shapedPrefabNameArray)

func ConstructLootTableMapping():
	ConstructMapping(LootTable_Dir, lootTablePathArray, lootTableArray)

func ConstructDescriptorMapping():
	ConstructMapping(Descriptors_Dir, descriptorPathArray, descriptorNameArray)

func ConstructVulnerabilityMapping():
	ConstructMapping(VulnerableDescriptors_Dir, vulnerabilityPathArray, vulnerabilityNameArray)

func ConstructUnlockableMapping():
	ConstructMapping(Unlocks_DIR, unlockablePathArray, unlockableNameArray)


func ConstructUnitTableMapping():
	# Has to be different to filter out the VIs
	unitPathArray = GetAllFilesFromPath(Units_Dir)
	unitPathArray = unitPathArray.filter(FilterOutVIS)

	unitNameArray.clear()
	for path in unitPathArray:
		var split = path.split("/")
		var splitName = split[split.size() - 1]
		splitName = splitName.split(".")[0]
		unitNameArray.append(splitName)

func ConstructMapping(_directory, _pathArray : Array[String], _nameArray : Array[String]):
	# first construct a mapping of all the items in the items directory
	# and then make a parallel array to look for the item listed in the units' spreadsheet
	_pathArray.clear()
	_pathArray.append_array(GetAllFilesFromPath(_directory))

	_nameArray.clear()
	for path in _pathArray:
		var split = path.split("/")
		var splitName = split[split.size() - 1]
		splitName = splitName.split(".")[0]
		_nameArray.append(splitName)

# Used when constructing the unit name mappings to filter out the Unit Visual prefabs
func FilterOutVIS(path : String):
	var split = path.split("/")
	var last = split[split.size() - 1]
	return last.begins_with("UT_")

func ConstructAllDataMappings():
	ConstructItemMapping()
	ConstructLootTableMapping()
	ConstructUnitTableMapping()
	ConstructDescriptorMapping()
	ConstructAbilityMapping()
	ConstructVulnerabilityMapping()
	ConstructUnlockableMapping()
