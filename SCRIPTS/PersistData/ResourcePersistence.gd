extends Node2D
class_name ResourcePersistence


@export var template : ResourceTemplate
@export var amount : int


func ToJSON():
	var dict = {
		"template" : template.resource_path,
		"amount" : amount
	}
	return dict

static func FromJSON(_dict : Dictionary):
	var persist = ResourcePersistence.new()
	var templateSTR = PersistDataManager.LoadFromJSON("template", _dict)
	if templateSTR != null:
		persist.template = load(templateSTR) as ResourceTemplate

	persist.amount = PersistDataManager.LoadFromJSON("amount", _dict) as int
	return persist
