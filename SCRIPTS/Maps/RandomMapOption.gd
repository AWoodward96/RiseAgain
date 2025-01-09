extends MapOption
class_name RandomMapOption

@export var options : Array[WeightedMapOption]


func GetMap():
	var mapOptions = BuildWeightedList()
	var rng = GameManager.CurrentCampaign.CampaignRng.randi_range(0, mapOptions.size() - 1)
	return mapOptions[rng]

func BuildWeightedList():
	var validMapOptions = options.duplicate()
	for i in range(validMapOptions.size() - 1, -1, -1):
		var option = validMapOptions[i] as WeightedMapOption
		if option == null:
			validMapOptions.remove_at(i)
			continue

		if !option.requirement.CheckRequirement(null):
			validMapOptions.remove_at(i)
			continue

	return validMapOptions
