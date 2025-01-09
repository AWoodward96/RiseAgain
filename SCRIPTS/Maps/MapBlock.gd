extends Resource
class_name MapBlock

@export var priorityMapOptions : Array[PriorityMapOption]
@export var generalMapOptions : Array[WeightedMapOption]

var totalWeight : int = 0


func GetMapFromBlock():
	var filteredPriorityMaps = CheckPriorityMaps()
	if filteredPriorityMaps.size() > 0:
		var highestPriority = -10000
		var selectedMap : MapOption = null
		for m in filteredPriorityMaps:
			if m.Priority > highestPriority:
				selectedMap = m
				highestPriority = m.Priority

		return selectedMap

	var mapOptions = BuildWeightedList()
	var rng = GameManager.CurrentCampaign.CampaignRng.randi_range(0, totalWeight)
	for opt in mapOptions:
		if rng <= opt.accumulatedWeight:
			return opt

	# Not sure how we got here - but hey this is just asking to break the game plz
	push_error("Could not get valid map option from list -name- ", resource_name, " -path- " , resource_path)
	return null

func CheckPriorityMaps():
	if priorityMapOptions.size() <= 0:
		return []

	var validPriorityMaps = priorityMapOptions.duplicate()
	for i in range(validPriorityMaps.size() - 1, -1, -1):
		var option = validPriorityMaps[i]
		if option == null:
			validPriorityMaps.remove_at(i)
			continue

		if !option.requirement.CheckRequirement(null):
			validPriorityMaps.remove_at(i)
			continue


	return validPriorityMaps

func BuildWeightedList():
	var validMapOptions : Array[MapOption] = []
	var accumulatedWeight = 0
	totalWeight = 0
	for i in range(0, generalMapOptions.size()):
		var option = generalMapOptions[i] as WeightedMapOption
		if option == null:
			continue

		if option.requirement != null && !option.requirement.CheckRequirement(null):
			continue

		accumulatedWeight += option.weight
		totalWeight += option.weight
		option.accumulatedWeight = accumulatedWeight
		validMapOptions.append(option)

	return validMapOptions
