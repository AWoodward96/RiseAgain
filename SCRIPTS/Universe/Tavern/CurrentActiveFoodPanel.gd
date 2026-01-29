extends Control
class_name CurrentActiveFoodPanel

@export var foodName : Label
@export var foodDesc : Label
@export var foodIcon : TextureRect
@export var foodCost : Label
@export var noActiveMealParent : Control
@export var yesActiveMealParent : Control


func Refresh():
	var meal = PersistDataManager.universeData.bastionData.ActiveMeal
	if noActiveMealParent != null: noActiveMealParent.visible = meal == null
	if yesActiveMealParent != null: yesActiveMealParent.visible = meal != null
	if meal == null:
		return

	if foodName != null: foodName.text = tr(LocSettings.OneX_TEXT).format({"TEXT" = tr(meal.loc_title)})
	if foodDesc != null: foodDesc.text = meal.loc_desc
	if foodIcon != null: foodIcon.texture = meal.loc_icon
	if foodCost != null: foodCost.text = tr(LocSettings.X_Num).format({"NUM" = meal.cost[0].Amount})
