extends PanelContainer

signal OnUnitSelected

@export var SelectedParent : Control
@export var UnitIcon : TextureRect
@export var UnitName : Label
@export var UnitDescriptionText : RichTextLabel

var unitTemplate : UnitTemplate

func Initialize(_unitTemplate : UnitTemplate):
	unitTemplate = _unitTemplate
	UnitIcon.texture = unitTemplate.icon

	UnitName.text = tr(unitTemplate.loc_DisplayName)
	UnitDescriptionText.text = tr(unitTemplate.loc_Description)

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
