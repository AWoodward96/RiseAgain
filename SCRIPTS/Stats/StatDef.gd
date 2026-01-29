extends Resource
class_name StatDef

@export var Template : StatTemplate
@export var Value : int


func GetStat(_allOtherStats : Array[StatDef]):
	return Value


func ToJSON():
	var returnDict = {
		"Template" = Template.resource_path,
		"Value" = Value
	}
	return returnDict

static func FromJSON(_dict : Dictionary):
	var newDef = StatDef.new()
	var templateSTR = PersistDataManager.LoadFromJSON("Template", _dict)
	if templateSTR != null:
		newDef.Template = load(templateSTR) as StatTemplate

	newDef.Value = PersistDataManager.LoadFromJSON("Value", _dict) as int
	return newDef
