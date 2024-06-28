extends Control
class_name InspectPanel

@export var icon : TextureRect
@export var healthbar : ProgressBar
@export var healthText : Label
@export var namelabel : Label

@export var focusSlotPrefab : PackedScene
@onready var focus_bar_parent: EntryList = %FocusBarParent

var ctrl
var currentUnit : UnitInstance

func Initialize(_playercontroller : PlayerController):
	ctrl = _playercontroller

func Update(_unit : UnitInstance):
	if _unit == null || _unit.Template == null:
		return

	var forceUpdate = currentUnit != _unit
	currentUnit = _unit
	var template = _unit.Template
	namelabel.text = template.loc_DisplayName
	icon.texture = template.icon
	healthText.text = str(_unit.currentHealth) + "/" + str(_unit.maxHealth)
	healthbar.value = _unit.currentHealth / _unit.maxHealth
	UpdateFocusUI(forceUpdate)

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
