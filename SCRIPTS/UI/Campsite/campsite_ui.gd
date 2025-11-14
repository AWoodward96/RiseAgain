extends FullscreenUI
class_name CampsiteUI

signal OnRest

@export var Vignette : Control
@export var UIParent : Control
@export var ViewButton : Button
@export var InspectButton : Button
@export var RestButton : Button

var inspectUI
var lastButton

func Initialize():
	#UIParent.visible = true
	ViewButton.disabled = true
	InspectButton.disabled = false
	RestButton.disabled = false
	pass

func ReturnFocus():
	if inspectUI != null:
		inspectUI.ReturnFocus()
	else:
		InspectButton.grab_focus()
	pass


func btn_View():
	pass

func btn_Inspect():
	inspectUI = UIManager.OpenFullscreenUI(UIManager.TeamManagementFullscreenUI)
#	ui.Initialize()
	pass


func OnManageItemsClosed():
	InspectButton.grab_focus()

func btn_Rest():
	OnRest.emit()
	queue_free()
	pass

static func ShowUI():
	var ui = UIManager.OpenFullscreenUI(UIManager.CampsiteUIPrefab)
	ui.Initialize()
	return ui
