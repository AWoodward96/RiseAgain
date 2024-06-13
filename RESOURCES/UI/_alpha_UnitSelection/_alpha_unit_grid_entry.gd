extends PanelContainer

signal OnUnitSelected

@export var SelectedParent : Control
@export var UnitIcon : TextureRect
@export var UnitName : Label

var unitTemplate : UnitTemplate

func Initialize(_unitTemplate : UnitTemplate):
	unitTemplate = _unitTemplate
	UnitIcon.texture = unitTemplate.icon

	# TODO: Setup a baseline localization sheet for UI
	UnitName.text = tr(unitTemplate.loc_DisplayName)

func _ready():
	gui_input.connect(OnGUI)
	focus_entered.connect(OnFocusEntered)
	focus_exited.connect(OnFocusExited)

func OnGUI(_event : InputEvent):
	if _event.is_action_pressed("select"):
		OnUnitSelected.emit()

func OnFocusEntered():
	SelectedParent.visible = true

func OnFocusExited():
	SelectedParent.visible = false
