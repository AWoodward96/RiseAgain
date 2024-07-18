extends Control
class_name InspectPanel

@export var icon : TextureRect
@export var healthbar : ProgressBar
@export var healthText : Label
@export var namelabel : Label
@export var levelLabel : Label
@export var expbar : ProgressBar

@export var focusSlotPrefab : PackedScene

@export_category("Stat Stuff")

@export var statPrefab : PackedScene
@export var statEntryParent : EntryList

@export_category("Weapon Stuff")

@export var weaponIcon : TextureRect
@export var weaponName : Label
@export var weaponEntryParent : EntryList

@export_category("Localization")
@export var levelLoc : String

@onready var focus_bar_parent: EntryList = %FocusBarParent

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
	currentUnit = _unit
	currentUnit.OnStatUpdated.connect(OnUnitStatUpdated)


	var template = _unit.Template
	namelabel.text = template.loc_DisplayName
	icon.texture = template.icon
	healthText.text = str(_unit.currentHealth) + "/" + str(_unit.maxHealth)
	healthbar.value = _unit.currentHealth / _unit.maxHealth
	expbar.value = _unit.Exp

	# I don't know how fast this is, but w/e
	var lvlStr = tr(levelLoc)
	levelLabel.text = lvlStr.format({"NUM" : _unit.DisplayLevel })

	UpdateFocusUI(forceUpdate)
	if forceUpdate:
		UpdateStatsUI()
		UpdateWeaponInfo()


func OnUnitStatUpdated():
	Update(currentUnit, true)

func UpdateFocusUI(_createNew : bool):
	var maxFocus = currentUnit.GetWorkingStat(GameManager.GameSettings.MindStat)
	if _createNew:
		focus_bar_parent.ClearEntries()
		for fIndex in maxFocus:
			var entry = focus_bar_parent.CreateEntry(focusSlotPrefab)
			entry.Toggle(currentUnit.currentFocus >= (fIndex + 1)) # +1 because it's an index
	else:
		for fIndex in maxFocus:
			var entry = focus_bar_parent.GetEntry(fIndex)
			entry.Toggle(currentUnit.currentFocus >= (fIndex + 1)) # +1 because it's an index

func UpdateWeaponInfo():
	var equippedItem = currentUnit.EquippedItem
	var hasItem = equippedItem != null
	weaponIcon.visible = hasItem
	weaponName.visible = hasItem
	weaponEntryParent.visible = hasItem

	weaponEntryParent.ClearEntries()
	if hasItem:
		weaponIcon.texture = currentUnit.EquippedItem.icon
		weaponName.text = currentUnit.EquippedItem.loc_displayName
		if equippedItem.StatData != null:
			for stat in equippedItem.StatData.GrantedStats:
				var entry = weaponEntryParent.CreateEntry(statPrefab)
				entry.icon.texture = stat.Template.loc_icon
				entry.statlabel.text = str(stat.Value)


	pass


func UpdateStatsUI():
	statEntryParent.ClearEntries()
	UpdateStat(statEntryParent.CreateEntry(statPrefab), GameManager.GameSettings.AttackStat)
	UpdateStat(statEntryParent.CreateEntry(statPrefab), GameManager.GameSettings.DefenseStat)
	UpdateStat(statEntryParent.CreateEntry(statPrefab), GameManager.GameSettings.SkillStat)
	UpdateStat(statEntryParent.CreateEntry(statPrefab), GameManager.GameSettings.MindStat)
	UpdateStat(statEntryParent.CreateEntry(statPrefab), GameManager.GameSettings.SpAttackStat)
	UpdateStat(statEntryParent.CreateEntry(statPrefab), GameManager.GameSettings.SpDefenseStat)
	UpdateStat(statEntryParent.CreateEntry(statPrefab), GameManager.GameSettings.LuckStat)
	UpdateStat(statEntryParent.CreateEntry(statPrefab), GameManager.GameSettings.MovementStat)

func UpdateStat(_entry, _statTemplate : StatTemplate):
	_entry.icon.texture = _statTemplate.loc_icon
	_entry.statlabel.text = str(currentUnit.GetWorkingStat(_statTemplate))

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
