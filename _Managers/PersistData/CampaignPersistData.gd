extends PersistDataBase
class_name CampaignPersistData

const CAMPAIGN_PERSIST_NAME = "Campaign"

var CurrentSquad : Array[UnitInstance]

func GetType():
	return PersistType.Local

func FileName():
	return CAMPAIGN_PERSIST_NAME

func Construct(_roster : Array[UnitInstance]):
	CurrentSquad = _roster
	WriteToFile()
	pass

func ToJSON():
	var squadData : Array[Dictionary]
	for instance in CurrentSquad:
		squadData.append(instance.ToJSON())

	var data = {
			"CurrentSquad" : squadData
		}

	return data
