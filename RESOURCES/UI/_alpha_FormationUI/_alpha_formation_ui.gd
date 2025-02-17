extends CanvasLayer

signal FormationSelected

@export var MoveInfoPanelParent : Control
@export var FormationParent : Control
@export var MenuParent : Control
@export var FormationButton : Button
@export var ItemButton : Button

@export var mapObjectiveText : Label
@export var optionalObjectiveLabel : Label
@export var optionalObjectiveText : Label

@export var manageItemsPanel : ManageItemsPanel

var ctrl : PlayerController
var map : Map

func _ready():
	MenuParent.visible = true
	FormationParent.visible = false
	FormationButton.grab_focus()

	manageItemsPanel.OnClose.connect(OnManageItemsClosed)

	ShowSwapWithPanel(false)

func Initialize(_ctrl : PlayerController, _map : Map):
	ctrl = _ctrl
	ctrl.BlockMovementInput = true
	ctrl.reticle.visible = false

	manageItemsPanel.visible = false

	mapObjectiveText.text = _map.WinCondition.loc_description
	if _map.OptionalObjectives.size() == 0:
		optionalObjectiveLabel.visible = false
		optionalObjectiveText.visible = false
	else:
		optionalObjectiveLabel.visible = true
		optionalObjectiveText.visible = true
		optionalObjectiveText.text = _map.OptionalObjectives[0].UpdateLocalization(_map)

func _process(_delta):
	if InputManager.startDown:
		FormationSelected.emit()
		queue_free()

func SetFormationMode(_enabled : bool):
	MenuParent.visible = !_enabled
	FormationParent.visible = _enabled
	ctrl.BlockMovementInput = !_enabled
	ctrl.reticle.visible = _enabled
	if !_enabled:
		FormationButton.grab_focus()

func OnFormationButton():
	SetFormationMode(true)

func OnItemButton():
	manageItemsPanel.visible = true
	manageItemsPanel.Initialize(Map.Current, GameManager.CurrentCampaign)
	pass

func ShowSwapWithPanel(_val : bool):
	MoveInfoPanelParent.visible = _val

func OnManageItemsClosed():
	ItemButton.grab_focus()
