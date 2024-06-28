extends UnitUsable
class_name Item

@export var UsageLimit : int = -1
var currentUsages = 1


func Initialize(_unitOwner : UnitInstance, _map : Map):
	super(_unitOwner, _map)
	currentUsages = UsageLimit


func OnUse():
	# It's a bit unclear how this will actually work, but for now use items are just
	# healing items. They're applied to yourself, and nothing else
	var isUsed = false
	# for now, assume that the owner of this item is also the target of this item
	if HealData != null:
		# Okay then this is a heal, pass the heal amount to ourselfs
		var log = ActionLog.Construct(ownerUnit, self)
		var result = ActionResult.new()
		result.Target = ownerUnit
		result.Source = ownerUnit
		result.HealthDelta = ownerUnit.CalculateHeal(HealData, ownerUnit)
		log.actionResults.append(result)

		ownerUnit.QueueHealAction(log)
		isUsed = true

	if StatConsumableData != null:
		for statDef in StatConsumableData.StatsToGrant:
			ownerUnit.ApplyStatModifier(statDef)
			isUsed = true


	if UsageLimit != -1 && isUsed:
		currentUsages -= 1
		if currentUsages <= 0:
			ownerUnit.TrashItem(self)

	if isUsed:
		ownerUnit.QueueEndTurn()
		playerController.EnterUnitStackClearState(ownerUnit)
	pass


func ToJSON():
	return {
		"Item" : scene_file_path,
		"currentUsages" : currentUsages
	}
