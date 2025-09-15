extends Object
class_name UnlockablePersistData

var Content : UnlockableContentTemplate # This information is duplicated just in case I do need to know this information from the dictionary
var Unlocked : bool = false


func ToJSON():
	var dict = {
		"Content" = Content.resource_path,
		"Unlocked" = Unlocked
	}
	return dict

static func FromJSON(_dict):
	var newPersit = UnlockablePersistData.new()
	newPersit.Content = load(_dict["Content"])
	newPersit.Unlocked = _dict["Unlocked"]
	return newPersit
