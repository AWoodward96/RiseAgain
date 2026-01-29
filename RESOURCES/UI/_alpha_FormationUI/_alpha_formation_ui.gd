extends FullscreenUI

signal FormationSelected

@export var MoveInfoPanelParent : Control
@export var FormationParent : Control
@export var MenuParent : Control
@export var FormationButton : Button
@export var ItemButton : Button
@export var BlockInstantStartTimer : float = 1
@export var FacadeAnimator : AnimationPlayer

@export var mapObjectiveText : Label
@export var optionalObjectiveLabel : Label
@export var optionalObjectiveText : Label

@export var manageItemsPanel : ManageItemsPanel

var ctrl : PlayerController
var map : Map
var blockTimer : float = 0

func _ready():
	MenuParent.visible = true
	FormationParent.visible = false
	FormationButton.grab_focus()
	blockTimer = 0

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
	if blockTimer > BlockInstantStartTimer:
		if InputManager.startDown:
			if CutsceneManager.BlockEnterAction:
				return

			FormationSelected.emit()
			queue_free()
	else:
		blockTimer += _delta

func SetFormationMode(_formationMode : bool):
	ItemButton.disabled = _formationMode
	FormationButton.disabled = _formationMode
	if !_formationMode:
		FacadeAnimator.play("ToMenu")
		FormationButton.grab_focus()
	else:
		FacadeAnimator.play("ToFormation")

	FormationParent.visible = _formationMode
	ctrl.BlockMovementInput = !_formationMode
	ctrl.reticle.visible = _formationMode

func OnFormationButton():
	SetFormationMode(true)

func OnItemButton():
	UIManager.OpenFullscreenUI(UIManager.TeamManagementFullscreenUI)
	pass

func ShowSwapWithPanel(_val : bool):
	MoveInfoPanelParent.visible = _val

func OnManageItemsClosed():
	ItemButton.grab_focus()

func ReturnFocus():
	FormationButton.grab_focus()
	pass
