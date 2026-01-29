extends FullscreenUI
class_name ConfirmPurchaseUI

@export var focusButton : Button
@export var costEntryParent : EntryList
@export var costEntryPrefab : PackedScene


var confirm : Callable
var deny : Callable

func _ready():
	ReturnFocus()

func Initialize(_cost : Array[ResourceDef], _onConfirm : Callable, _onDeny : Callable):
	costEntryParent.ClearEntries()
	for c in _cost:
		var entry = costEntryParent.CreateEntry(costEntryPrefab)
		entry.Initialize(c)
	confirm = _onConfirm
	deny = _onDeny


func OnConfirm():
	if confirm != null:
		confirm.call()
	queue_free()

func OnDeny():
	if deny != null:
		deny.call()
	queue_free()

func ReturnFocus():
	super()
	focusButton.grab_focus()

static func OpenUI(_cost : Array[ResourceDef], _onConfirm : Callable, _onCancel : Callable):
	var ui = UIManager.OpenFullscreenUI(UIManager.FullscreenConfirmPurchaseUI)
	ui.Initialize(_cost, _onConfirm, _onCancel)
	return ui
