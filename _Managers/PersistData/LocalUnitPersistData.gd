class_name LocalUnitPersistData

var Template : UnitTemplate
var InstancedData : Dictionary

func Construct(_unitTemplate : UnitTemplate):
	Template = _unitTemplate

func UpdateFromInstance(_dict : Dictionary):
	InstancedData = _dict


func ToJSON():
	var dict = {
		"Template" : Template.resource_path,
		"InstancedData" : InstancedData
	}
	return dict
