extends Object
class_name PersistDataBase

const DEFAULT_PERSIST_NAME = "Default"

## Explanation for each type:
# Local: Local to a run. This is where Unit HP, Unit Items, etc might be stored. Should be discarded when a new campaign is started
# Global: Persists between runs. Should hold story beats and other information that persists outside of a run
# Settings: A seperate category specifically for user settings
enum PersistType { Local, Global, Settings}

func GetType():
	return PersistType.Local

func FileName():
	return DEFAULT_PERSIST_NAME

func ConstructFileString():
	return GetDirectory() + FileName() + ".save"

func GetDirectory():
	return "user://" + PersistType.keys()[GetType()] + "/"

func ToJSON():
	return {}


func WriteToFile():
	if !FileAccess.file_exists(GetDirectory()):
		var dir = DirAccess.open("user://")
		var error = dir.make_dir_recursive(GetDirectory())
		if error != OK:
			push_error(error)

	var save_game = FileAccess.open(ConstructFileString(), FileAccess.WRITE)
	if save_game != null:
		var dict = ToJSON()
		var dictToJSON = JSON.stringify(dict)

		save_game.store_line(dictToJSON)

