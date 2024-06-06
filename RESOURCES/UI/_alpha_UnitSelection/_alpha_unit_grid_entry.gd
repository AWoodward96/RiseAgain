extends PanelContainer

signal OnUnitSelected

@export var SelectedParent : Control
@export var UnitIcon : TextureRect
@export var UnitName : Label

var UnitTemplate : UnitTemplate

func Initialize(_unitTemplate : UnitTemplate):
	UnitTemplate = _unitTemplate
	UnitIcon.texture = UnitTemplate.icon

	# TODO: Setup a baseline localization sheet for UI
	UnitName.text = UnitTemplate.DebugName

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
