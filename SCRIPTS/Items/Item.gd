extends Ability
class_name Item

@export_category("Item Data")
@export var conditionalStatModifiers : ConditionalStatModComponent
@export var growthModifierData : HeldItemStatGrowthModifier


func GetStatDelta(_statTemplate : StatTemplate):
	var delta = 0
	# Get the stats granted by the HeldItemComponent
	if StatData != null:
		for stats in StatData.GrantedStats:
			if stats.Template == _statTemplate:
				delta += stats.Value

	if conditionalStatModifiers != null:
		delta += conditionalStatModifiers.GetStatChange(_statTemplate, null)

	return delta

func ToJSON():
	var dict = super()

	if growthModifierData != null:
		dict["ModifierSucceedCount"] = growthModifierData.SuccessCount
	return dict

func FromJSON(_dict : Dictionary):
	super(_dict)
	if _dict.has("ModifierSucceededCount"):
		growthModifierData.SuccessCount = _dict["ModifierSucceededCount"]
