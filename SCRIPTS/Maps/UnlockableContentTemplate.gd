extends Resource
class_name UnlockableContentTemplate


@export var StartUnlocked : bool = false
@export var Descriptors : Array[DescriptorTemplate]


func CreatePersistData():
	var persistData = UnlockablePersistData.new()
	persistData.Unlocked = StartUnlocked
	persistData.Content = self
	return persistData
