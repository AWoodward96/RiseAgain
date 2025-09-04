extends FullscreenUI
class_name TavernMenuUI

@export var First : MealListingEntry
@export var ReciptAnimator : AnimationPlayer
@export var TavernLevelLabel : Label
@export var ReciptMealTitleLabel : Label
@export var ReciptMealDescLabel : Label
@export var ReciptMealCostLabel : Label
@export var ReciptMealIcon : TextureRect

func _ready():
	ReturnFocus()
	GameManager.GlobalUI.ShowResources()
	TavernLevelLabel.text = tr(LocSettings.Level_Num).format({"NUM" = PersistDataManager.universeData.bastionData.CurrentTavernLevel + 1})

	if PersistDataManager.universeData.bastionData.ActiveMeal != null:
		UpdateRecipt()
		ReciptAnimator.play("show")
		pass


func UpdateRecipt():
	var meal = PersistDataManager.universeData.bastionData.ActiveMeal
	if meal == null:
		return

	ReciptMealTitleLabel.text = tr(LocSettings.OneX_TEXT).format({"TEXT" = tr(meal.loc_title)})
	ReciptMealDescLabel.text = meal.loc_desc
	ReciptMealIcon.texture = meal.loc_icon
	ReciptMealCostLabel.text = tr(LocSettings.X_Num).format({"NUM" = meal.cost[0].Amount})


func TryPurchaseMeal(_mealEntry : MealListingEntry):
	if _mealEntry == null || _mealEntry.Template == null:
		return

	if !_mealEntry.CheckUnlocked():
		_mealEntry.OnLockedAttempt()
		return

	if PersistDataManager.universeData.HasResourceCost(_mealEntry.Template.cost):
		ConfirmPurchaseUI.OpenUI(_mealEntry.Template.cost,
			func() :
				PersistDataManager.universeData.TryPayResourceCost(_mealEntry.Template.cost, PurchaseSucess.bind(_mealEntry), PurchaseFailed.bind(_mealEntry)),
			func():
				pass)
	else:
		PurchaseFailed(_mealEntry)
		pass
	pass

func PurchaseSucess(_mealEntry : MealListingEntry):
	PersistDataManager.universeData.bastionData.ActiveMeal = _mealEntry.Template
	UpdateRecipt()
	ReciptAnimator.play("show")

	pass

func PurchaseFailed(_mealEntry : MealListingEntry):
	_mealEntry.OnPurchaseFailed()
	pass

func ReturnFocus():
	First.GrabFocus()


func _exit_tree() -> void:
	super()
	GameManager.GlobalUI.HideResources()
