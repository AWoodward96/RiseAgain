extends CanvasLayer
class_name CampsiteUI

signal OnRest

@export var Vignette : Control
@export var UIParent : Control
@export var ViewButton : Button
@export var InspectButton : Button
@export var RestButton : Button

@export var itemsPanel : ManageItemsPanel

func _ready():
	RestButton.grab_focus()


func Initialize():
	#UIParent.visible = true
	ViewButton.disabled = true
	InspectButton.disabled = false
	RestButton.disabled = false
	itemsPanel.OnClose.connect(OnManageItemsClosed)
	pass


func btn_View():
	pass

func btn_Inspect():
	itemsPanel.visible = true
	itemsPanel.Initialize(Map.Current, GameManager.CurrentCampaign)
	pass


func OnManageItemsClosed():
	InspectButton.grab_focus()

func btn_Rest():

	OnRest.emit()
	queue_free()
	pass

static func ShowUI():
	var ui = UIManager.CampsiteUIPrefab.instantiate() as CampsiteUI
	ui.Initialize()
	GameManager.add_child(ui)
	return ui
