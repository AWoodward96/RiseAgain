extends MapStateBase
class_name EventState


func Enter(_map : Map, _ctrl : PlayerController):
	super(_map, _ctrl)
	pass


func Exit():
	pass

func Update(_delta):
	pass

func InitializeFromPersistence(_map : Map, _ctrl : PlayerController):
	pass

func ToJSON():
	return "Base"
