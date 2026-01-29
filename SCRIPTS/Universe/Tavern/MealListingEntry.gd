extends Control
class_name MealListingEntry

signal TryPurchase(_template : MealListingEntry)

@export var Template : MealTemplate
@export var MealTitle : Label
@export var MealDesc : Label
@export var MealIcon : TextureRect
@export var Cost : Label
@export var MyButton : Button
@export var LockedParent : Control
@export var Disabled : bool = false
@export var Animator : AnimationPlayer

@export var CostCanPay : Color
@export var CostCantPay : Color

func _ready():
	MyButton.disabled = Disabled
	if Disabled:
		MyButton.focus_mode = Control.FOCUS_NONE

	if Template != null:
		MealTitle.text = Template.loc_title
		MealDesc.text = Template.loc_desc
		MealIcon.texture = Template.loc_icon
		Cost.text = tr(LocSettings.X_Num).format({"NUM" = Template.cost[0].Amount})
		Cost.label_settings.font_color = CostCanPay if PersistDataManager.universeData.HasResourceCost(Template.cost) else CostCantPay

		var unlocked = CheckUnlocked()
		LockedParent.visible = !unlocked
		MyButton.disabled = !unlocked || Disabled # covers edge case where template is null and button is disabled


func CheckUnlocked():
	var tavernData = GameManager.GameSettings.TavernData
	for i in range(0, tavernData.Levels.size()):
		for meal in tavernData.Levels[i].UnlockedMeals:
			if meal == Template && i <= PersistDataManager.universeData.bastionData.CurrentTavernLevel:
				return true
	return false


func GrabFocus():
	MyButton.grab_focus()

# Called from signals
func OnButtonPressed():
	TryPurchase.emit(self)

func OnPurchaseFailed():
	Animator.play("PurchaseFailed")
	pass

func OnLockedAttempt():
	Animator.play("Locked")
