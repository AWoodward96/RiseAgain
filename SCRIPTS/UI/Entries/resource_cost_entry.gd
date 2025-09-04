extends Control
class_name ResourceCostEntry

@export var icon : TextureRect
@export var label : Label

func Initialize(_cost : ResourceDef, _colorCanAfford : Color = Color.WHITE, _colorCantAfford : Color = Color.WHITE):
	icon.texture = _cost.ItemResource.loc_icon
	label.text = tr(LocSettings.X_Num).format({"NUM" = _cost.Amount})

	if PersistDataManager.universeData.HasResourceCost([_cost]):
		label.label_settings.font_color = _colorCanAfford
	else:
		label.label_settings.font_color = _colorCantAfford
