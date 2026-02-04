extends Control
class_name UnitHealthBar

signal HealthBarTweenCallback

@export var HealthBar : ProgressBar
@export var IncomingDamageBar : ProgressBar
@export var ArmorBar : ProgressBar
@export var InjuredBar : ProgressBar
@export var HealthText : Label
@export var ExtraHealthBarParent : Control
@export var ExtraHealthBarLabel : Label
@export var HideTimer : Timer
@export var InjuredParent : Control

@export_category("Level and EXP")
@export var ExperienceBar : ProgressBar
@export var LevelLabel : Label
@export var LevelLocalization : String
@export var ExpLabel : Label
@export var ExpLocalization : String


@export_category("Combat Effects")

@export var EffectParent : Control
@export var EffectsList : EntryList
@export var EffectsIconPrefab : PackedScene

var Unit : UnitInstance
var AssignedTile : Tile
var UpdateOverTime : bool
var DeltaValueChange : int		# How much damage or healing is being dealt
var DeltaHealth : int			# How much is our Health changing - signed
var DeltaArmor : int			# How much is our Armor changing - will always be negative because positives happen instantly
var DesiredHealthValue : int
var StartingArmor : int

var UpdateBarTween : Tween
var MaxHealth : int :
	get():
		if Unit != null:
			return Unit.maxHealth
		elif AssignedTile != null:
			return AssignedTile.MaxHealth
		else:
			return 0
var CurrentHealth : int:
	get():
		if Unit != null:
			return Unit.currentHealth
		elif AssignedTile != null:
			return AssignedTile.Health
		else:
			return 0


func SetUnit(_unit : UnitInstance):
	if Unit != null:
		Unit.OnCombatEffectsUpdated.disconnect(RefreshCombatEffects)

	Unit = _unit

	if !Unit.OnCombatEffectsUpdated.is_connected(RefreshCombatEffects):
		Unit.OnCombatEffectsUpdated.connect(RefreshCombatEffects)

	Refresh()
	RefreshCombatEffects()

func SetTile(_tile : Tile):
	AssignedTile = _tile
	Refresh(false)


func ModifyHealthOverTime(_deltaHealthChange : int):
	if Unit == null && AssignedTile == null:
		return

	DeltaValueChange = _deltaHealthChange
	if DeltaValueChange == 0:
		UpdateBarTweenComplete()
		return # Nothing occurs early exit

	DeltaArmor = 0
	DeltaHealth = 0
	var remainingDelta = DeltaValueChange
	StartingArmor = 0
	if Unit != null: StartingArmor = Unit.GetArmorAmount()
	var health = CurrentHealth
	var maxHealth = MaxHealth


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
			UpdateBarTween.tween_method(UpdateHealthBarTween, health, health + DeltaHealth, healthBarMoveTime)

		UpdateBarTween.tween_callback(UpdateBarTweenComplete)
	elif DeltaValueChange == 0:
		UpdateBarTweenComplete()
	else:
		UpdateBarTween = create_tween()
		DeltaHealth = min(maxHealth - health, DeltaValueChange) # Either use the delta value change, or bring us up to full hp
		UpdateBarTween.tween_method(UpdateHealthBarTween, health, health + DeltaHealth, Juice.HealthBarLossTime)
		UpdateBarTween.tween_callback(UpdateBarTweenComplete)



func UpdateArmorBarTween(value):
	if Unit != null && Unit.Submerged:
		HealthText.text = tr(LocSettings.Health_Submerged)
		ArmorBar.value = 0
	else:
		HealthText.text = str("%01.0d/%01.0d" % [clamp(CurrentHealth + value, 0, MaxHealth + value), MaxHealth])
		HealthBar.value = clampf(CurrentHealth, 0, MaxHealth) / MaxHealth as float
		ArmorBar.value = clampf(value, 0, StartingArmor) / MaxHealth as float
	pass

func UpdateHealthBarTween(value):
	if Unit != null && Unit.Submerged:
		HealthText.text = tr(LocSettings.Health_Submerged)
	else:
		HealthText.text = str("%01.0d/%01.0d" % [clamp(value, 0, MaxHealth), MaxHealth])
		HealthBar.value = clampf(value, 0, MaxHealth) / MaxHealth as float
	pass

func RefreshIncomingDamageBar():
	if IncomingDamageBar != null:
		IncomingDamageBar.value = clampf(CurrentHealth, 0, MaxHealth) / MaxHealth as float

func UpdateBarTweenComplete():
	HealthBarTweenCallback.emit()

func Refresh(_autohide : bool = true):
	if Unit == null && AssignedTile == null:
		return

	if HideTimer != null:
		HideTimer.stop()

	var armor = 0
	if Unit != null:
		StartingArmor = Unit.GetArmorAmount()

	armor = StartingArmor

	ArmorBar.visible = armor > 0


	if armor > 0:
		ArmorBar.visible = Unit != null
		if Unit != null:
			if Unit.Submerged:
				ArmorBar.value = 0
			else:
				ArmorBar.value = armor as float / Unit.trueMaxHealth


	if HealthText != null:
		if Unit != null:
			if !Unit.Submerged:
				HealthText.text = "%01.0d/%01.0d" % [CurrentHealth + armor, MaxHealth]
			else:
				HealthText.text = tr(LocSettings.Health_Submerged)


	if HealthBar != null:
		if Unit != null:
			if Unit.Submerged:
				HealthBar.value = 1
			else:
				HealthBar.value = Unit.currentHealth / Unit.trueMaxHealth
		elif AssignedTile != null:
			HealthBar.value = AssignedTile.Health / AssignedTile.MaxHealth

	if InjuredBar != null:
		InjuredBar.visible = Unit != null && Unit.Injured
		if Unit != null:
			InjuredBar.value = ((Unit.trueMaxHealth - Unit.maxHealth) / Unit.trueMaxHealth)

	if LevelLabel != null:
		LevelLabel.visible = Unit != null
		if Unit != null:
			var lvlStr = tr(LevelLocalization)
			LevelLabel.text = lvlStr.format({"NUM" : Unit.DisplayLevel })

	if ExpLabel != null:
		ExpLabel.visible = Unit != null
		if Unit != null:
			var madlibs = {"NUM" : Unit.Exp, "CUR" : Unit.Exp, "MAX" : str(100)}
			ExpLabel.text = tr(ExpLocalization).format(madlibs)

	if ExperienceBar != null:
		ExperienceBar.visible = Unit != null
		if Unit != null:
			ExperienceBar.value = Unit.Exp

	if InjuredParent != null:
		InjuredParent.visible = Unit != null
		if Unit != null:
			InjuredParent.visible = Unit.Injured

	if ExtraHealthBarParent != null:
		ExtraHealthBarParent.visible = Unit != null && Unit.extraHealthBars > 0

	if ExtraHealthBarLabel != null:
		ExtraHealthBarLabel.visible = Unit != null && Unit.extraHealthBars > 0
		if Unit != null:
			ExtraHealthBarLabel.text = tr(LocSettings.X_Num).format({"NUM" = str(Unit.extraHealthBars)})

	if _autohide && HideTimer != null:
		HideTimer.start()

func RefreshCombatEffects():
	if EffectsList == null || Unit == null:
		return

	EffectParent.visible = Unit.CombatEffects.size() > 0

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

func CancelPreview():
	if UpdateBarTween != null:
		UpdateBarTween.stop()
		UpdateBarTween = null
