extends FullscreenUI
class_name TavernMenuUI

@export var First : MealListingEntry
@export var ReciptAnimator : AnimationPlayer
@export var TavernLevelLabel : Label
@export var ReciptPanel : CurrentActiveFoodPanel

func _ready():
	super()
	ReturnFocus()
	TavernLevelLabel.text = tr(LocSettings.Level_Num).format({"NUM" = PersistDataManager.universeData.bastionData.CurrentTavernLevel + 1})

	if PersistDataManager.universeData.bastionData.ActiveMeal != null:
		ReciptPanel.Refresh()
		ReciptAnimator.play("show")
		pass

func _exit_tree() -> void:
	super()
	UIManager.HideResources()

func _enter_tree() -> void:
	super()
	UIManager.ShowResources()


func _process(_delta: float) -> void:
	if !IsInDetailState:
		if InputManager.cancelDown:
			InputManager.ReleaseCancel()
			queue_free()



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
	ReciptPanel.Refresh()
	ReciptAnimator.play("show")

	pass

func PurchaseFailed(_mealEntry : MealListingEntry):
	_mealEntry.OnPurchaseFailed()
	pass

func ReturnFocus():
	First.GrabFocus()
