extends UnitPersistBase
class_name ArcherPersistBase

@export var testVariable : bool


func InitializeNew(_unitTemplate : UnitTemplate):
	super(_unitTemplate)
	testVariable = true

func ToJSON():
	var returnedSuper = super()
	returnedSuper["testVariable"] = testVariable
	return returnedSuper

func InitFromJSON(_dict :Dictionary):
	super(_dict)
	testVariable = PersistDataManager.LoadFromJSON("testVariable", _dict) as bool
