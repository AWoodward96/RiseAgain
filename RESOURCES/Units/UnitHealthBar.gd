extends Control
class_name UnitHealthBar

@export var HealthBar : ProgressBar
@export var ArmorBar : ProgressBar
@export var ExperienceBar : ProgressBar
@export var HealthText : Label
@export var FocusBarEntryList : EntryList
@export var FocusBarPrefab : PackedScene

var Unit : UnitInstance
var UnitMaxHealth : int
var UpdateOverTime : bool
var DeltaValueChange : int		# How much damage or healing is being dealt
var DeltaHealth : int			# How much is our Health changing - signed
var DeltaArmor : int			# How much is our Armor changing - will always be negative because positives happen instantly
var DesiredHealthValue : int
var StartingArmor : int

var UpdateBarTween : Tween

signal HealthBarTweenCallback

func SetUnit(_unit : UnitInstance):
	Unit = _unit
	Refresh()

func _process(delta: float):
	if UpdateOverTime:
		pass

func ModifyHealthOverTime(_deltaHealthChange : int):
	if Unit == null:
		return

	DeltaValueChange = _deltaHealthChange
	if DeltaValueChange == 0:
		return # Nothing occurs early exit

	UnitMaxHealth = Unit.maxHealth
	DeltaArmor = 0
	DeltaHealth = 0
	var remainingDelta = DeltaValueChange
	StartingArmor = Unit.GetArmorAmount()
	var unitHealth = Unit.currentHealth
	if DeltaValueChange < 0:
		# We're taking damage. If Armor is over 0, then the armor needs to take damage first
		if StartingArmor > 0:
			DeltaArmor = clamp(remainingDelta, -StartingArmor, 0)
			remainingDelta += StartingArmor

		if remainingDelta < 0:
			DeltaHealth = remainingDelta

		if DeltaHealth + DeltaArmor != DeltaValueChange:
			push_error("UnitHealthBar - Delta Health and Delta Armor don't equal the value changed. There's been a miscalculation")

		var totalDelta = DeltaArmor + DeltaHealth
		if totalDelta == 0:
			push_error("UnitHealthBar - I don't know how you did it but your total health delta (DeltaArmor + DeltaHealth) is 0, and you're about to divide by zero so I'm erroring you out.")
			return

		UpdateBarTween = create_tween()
		if DeltaArmor != 0:
			var armorBarMoveTime = Juice.HealthBarLossTime * abs(DeltaArmor as float / totalDelta as float)
			UpdateBarTween.tween_method(UpdateArmorBarTween, StartingArmor, StartingArmor + DeltaArmor, armorBarMoveTime)

		if DeltaHealth != 0:
			var healthBarMoveTime = Juice.HealthBarLossTime * abs(DeltaHealth as float / totalDelta as float)
			UpdateBarTween.tween_method(UpdateHealthBarTween, unitHealth, unitHealth + DeltaHealth, healthBarMoveTime)

		UpdateBarTween.tween_callback(UpdateBarTweenComplete)
	else:
		UpdateBarTween = create_tween()
		DeltaHealth = min(UnitMaxHealth - unitHealth, DeltaValueChange) # Either use the delta value change, or bring us up to full hp
		UpdateBarTween.tween_method(UpdateHealthBarTween, unitHealth, unitHealth + DeltaHealth, Juice.HealthBarLossTime)
		UpdateBarTween.tween_callback(UpdateBarTweenComplete)


func UpdateArmorBarTween(value):
	HealthText.text = str("%02d/%02d" % [clamp(Unit.currentHealth, 0, UnitMaxHealth), UnitMaxHealth])
	HealthText.text += str(" + %02d" % value)
	HealthBar.value = clampf(Unit.currentHealth, 0, UnitMaxHealth) / UnitMaxHealth as float
	ArmorBar.value = clampf(value, 0, StartingArmor) / UnitMaxHealth as float
	pass

func UpdateHealthBarTween(value):
	HealthText.text = str("%02d/%02d" % [clamp(value, 0, UnitMaxHealth), UnitMaxHealth])
	HealthBar.value = clampf(value, 0, UnitMaxHealth) / UnitMaxHealth as float
	pass

func UpdateBarTweenComplete():
	HealthBarTweenCallback.emit()

func Refresh(_forceUpdate : bool = false):
	if Unit == null || Unit.Template == null:
		return

	var armor = Unit.GetArmorAmount()

	ArmorBar.visible = armor > 0
	HealthText.text = str(Unit.currentHealth) + "/" + str(Unit.maxHealth)
	HealthBar.value = Unit.currentHealth / Unit.maxHealth

	if armor > 0:
		ArmorBar.value = armor as float / Unit.maxHealth
		HealthText.text += str(" + %02d" % armor)

	if ExperienceBar != null:
		ExperienceBar.value = Unit.Exp

	UpdateFocusUI()
	pass

func UpdateFocusUI():
	var maxFocus = Unit.GetWorkingStat(GameManager.GameSettings.MindStat)
	FocusBarEntryList.ClearEntries()
	for fIndex in maxFocus:
		var entry = FocusBarEntryList.CreateEntry(FocusBarPrefab)
		entry.Toggle(Unit.currentFocus >= (fIndex + 1)) # +1 because it's an index
