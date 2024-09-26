extends Control
class_name InspectPanel

@export var icon : TextureRect
@export var unitHealthBar : UnitHealthBar
@export var namelabel : Label

@export_category("Stat Stuff")

@export var dmgIcon : TextureRect
@export var dmgLabel : Label
@export var defLabel : Label
@export var spDefLabel : Label
@export var moveLabel : Label



@export_category("Weapon Stuff")

@export var weaponIcon : TextureRect
@export var weaponName : Label
@export var weaponEntryParent : EntryList

var ctrl
var currentUnit : UnitInstance


func Initialize(_playercontroller : PlayerController):
	ctrl = _playercontroller

func Update(_unit : UnitInstance, _forceUpdate : bool = false):
	if _unit == null || _unit.Template == null:
		return

	var forceUpdate = currentUnit != _unit || _forceUpdate

	if currentUnit != null:
		currentUnit.OnStatUpdated.disconnect(OnUnitStatUpdated)
		currentUnit.OnCombatEffectsUpdated.disconnect(OnUnitEffectsUpdated)

	currentUnit = _unit

	currentUnit.OnStatUpdated.connect(OnUnitStatUpdated)
	currentUnit.OnCombatEffectsUpdated.connect(OnUnitEffectsUpdated)

	var template = _unit.Template
	icon.texture = template.icon
	namelabel.text = template.loc_DisplayName
	unitHealthBar.SetUnit(_unit)
	unitHealthBar.Refresh()

	if forceUpdate:
		UpdateStatsUI()
		UpdateWeaponInfo()

func OnUnitStatUpdated():
	Update(currentUnit, true)

func OnUnitEffectsUpdated():
	Update(currentUnit, true)

func UpdateWeaponInfo():
	var equippedItem = currentUnit.EquippedItem
	var hasItem = equippedItem != null
	weaponIcon.visible = hasItem
	weaponName.visible = hasItem
	weaponEntryParent.visible = hasItem

	if hasItem:
		weaponIcon.texture = equippedItem.icon
		weaponName.text = equippedItem.loc_displayName


func UpdateStatsUI():
	var equippedItem = currentUnit.EquippedItem
	if equippedItem == null || (equippedItem != null && !equippedItem.IsDamage):
		# If there's no equippied item - then just do whatever is the bigger number
		var attack = currentUnit.GetWorkingStat(GameManager.GameSettings.AttackStat)
		var spattack = currentUnit.GetWorkingStat(GameManager.GameSettings.SpAttackStat)

		if attack > spattack:
			dmgIcon.texture = GameManager.GameSettings.AttackStat.loc_icon
			dmgLabel.text = str(attack)
		else:
			dmgIcon.texture = GameManager.GameSettings.SpAttackStat.loc_icon
			dmgLabel.text = str(spattack)
	else:
		var agressiveStat = equippedItem.UsableDamageData.AgressiveStat
		dmgIcon.texture = agressiveStat.loc_icon
		dmgLabel.text = str(currentUnit.GetWorkingStat(agressiveStat))

	defLabel.text = str(currentUnit.GetWorkingStat(GameManager.GameSettings.DefenseStat))
	spDefLabel.text = str(currentUnit.GetWorkingStat(GameManager.GameSettings.SpDefenseStat))
	moveLabel.text = str(currentUnit.GetWorkingStat(GameManager.GameSettings.MovementStat))


func _process(_delta):
	if ctrl != null:
		if ctrl.ControllerState.ShowInspectUI():
			if ctrl.CurrentTile != null && ctrl.CurrentTile.Occupant != null:
				visible = true
				Update(ctrl.CurrentTile.Occupant)
			else:
				visible = false


		else:
			visible = false
