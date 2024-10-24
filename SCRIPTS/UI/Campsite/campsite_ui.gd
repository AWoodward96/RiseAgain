extends CanvasLayer
class_name CampsiteUI

signal OnRest

@export var Vignette : Control
@export var UIParent : Control
@export var ViewButton : Button
@export var InspectButton : Button
@export var RestButton : Button


func _ready():
	ViewButton.grab_focus()


func Initialize():
	#UIParent.visible = true
	ViewButton.disabled = false
	InspectButton.disabled = false
	RestButton.disabled = false

	pass


func btn_View():
	pass

func btn_Inspect():
	pass

func btn_Rest():

	OnRest.emit()
	queue_free()
	pass

static func ShowUI():
	var ui = GameManager.CampsiteUIPrefab.instantiate() as CampsiteUI
	ui.Initialize()
	GameManager.add_child(ui)
	return ui
