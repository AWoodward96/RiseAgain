extends Control
class_name InspectPanel

@export var icon : TextureRect
@export var healthbar : ProgressBar
@export var healthText : Label
@export var namelabel : Label

var ctrl

func Initialize(_playercontroller : PlayerController):
	ctrl = _playercontroller

func Update(_unit : UnitInstance):
	if _unit == null || _unit.Template == null:
		return

	var template = _unit.Template
	namelabel.text = template.loc_DisplayName
	icon.texture = template.icon
	healthText.text = str(_unit.currentHealth) + "/" + str(_unit.maxHealth)
	healthbar.value = _unit.currentHealth / _unit.maxHealth

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
