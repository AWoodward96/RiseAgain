extends Control
class_name UnitHealthBar

@export var HealthBar : ProgressBar
@export var ArmorBar : ProgressBar
@export var HealthText : Label
@export var FocusBarEntryList : EntryList
@export var FocusBarPrefab : PackedScene

@export_category("Level and EXP")
@export var ExperienceBar : ProgressBar
@export var LevelLabel : Label
@export var LevelLocalization : String
@export var ExpLabel : Label
@export var ExpLocalization : String


@export_category("Combat Effects")

@export var EffectsList : EntryList
@export var EffectsIconPrefab : PackedScene

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
	if Unit != null:
		Unit.OnCombatEffectsUpdated.disconnect(RefreshCombatEffects)
	Unit = _unit
	Unit.OnCombatEffectsUpdated.connect(RefreshCombatEffects)

	Refresh()
	RefreshCombatEffects()

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

	if HealthText != null: HealthText.text = str(Unit.currentHealth) + "/" + str(Unit.maxHealth)
	if HealthBar != null: HealthBar.value = Unit.currentHealth / Unit.maxHealth

	if LevelLabel != null:
		var lvlStr = tr(LevelLocalization)
		LevelLabel.text = lvlStr.format({"NUM" : Unit.DisplayLevel })

	if armor > 0:
		ArmorBar.value = armor as float / Unit.maxHealth
		HealthText.text += str(" + %02d" % armor)

	if ExpLabel != null:
		var madlibs = {"NUM" : Unit.Exp, "CUR" : Unit.Exp, "MAX" : str(100)}
		ExpLabel.text = tr(ExpLocalization).format(madlibs)

	if ExperienceBar != null:
		ExperienceBar.value = Unit.Exp

	UpdateFocusUI()
	pass

func RefreshCombatEffects():
	if EffectsList == null:
		return

	EffectsList.ClearEntries()
	for effect in Unit.CombatEffects:
		var effectTemplate = effect.Template
		var entry = EffectsList.CreateEntry(EffectsIconPrefab) as EffectEntry

		var icon = GameManager.LocalizationSettings.Missing_CombatEffectIcon
		var labeltext = GameManager.LocalizationSettings.Missing_CombatEffectName
		if effectTemplate != null && effectTemplate.loc_icon != null:
				icon = effectTemplate.loc_icon

		if effectTemplate != null && effectTemplate.loc_name != "":
			labeltext = tr(effectTemplate.loc_name)

		if entry.icon != null: entry.icon.texture = icon
		if entry.label != null: entry.label.text = labeltext

func UpdateFocusUI():
	var maxFocus = Unit.GetWorkingStat(GameManager.GameSettings.MindStat)
	FocusBarEntryList.ClearEntries()
	for fIndex in maxFocus:
		var entry = FocusBarEntryList.CreateEntry(FocusBarPrefab)
		entry.Toggle(Unit.currentFocus >= (fIndex + 1)) # +1 because it's an index
