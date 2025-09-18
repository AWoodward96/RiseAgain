extends Control
class_name ResourceCostEntry

@export var icon : TextureRect
@export var label : Label
@export var detailEntry : DetailEntry

func Initialize(_cost : ResourceDef, _colorCanAfford : Color = Color.WHITE, _colorCantAfford : Color = Color.WHITE):
	icon.texture = _cost.ItemResource.loc_icon
	label.text = tr(LocSettings.X_Num).format({"NUM" = _cost.Amount})

	# For some reason writing this as [_cost] throws an error on the HasResourceCost call
	# can't figure out why, so we're going to be explicit
	var costArray : Array[ResourceDef]
	costArray.append(_cost)
	if PersistDataManager.universeData.HasResourceCost(costArray):
		label.label_settings.font_color = _colorCanAfford
	else:
		label.label_settings.font_color = _colorCantAfford

	detailEntry.tooltip = _cost.ItemResource.loc_desc
