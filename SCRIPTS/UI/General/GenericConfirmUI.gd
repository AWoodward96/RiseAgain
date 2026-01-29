extends FullscreenUI
class_name GenericConfirmUI

@export var focusButton : Button
@export var contentLabel : Label
@export var confirmButton : Button
@export var cancelButton : Button

var confirm : Callable
var deny : Callable

func _ready():
	ReturnFocus()

func Initialize(_translatedText : String, _onConfirm : Callable, _onDeny : Callable, _confirmText : String = "", _denyText : String = ""):
	confirm = _onConfirm
	deny = _onDeny
	contentLabel.text = _translatedText

	if _confirmText != "":
		confirmButton.text = _confirmText

	if _denyText != "":
		cancelButton.text = _denyText


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

static func OpenUI(_translatedText : String, _onConfirm : Callable, _onCancel : Callable,  _confirmText : String = "", _denyText : String = ""):
	var ui = UIManager.OpenFullscreenUI(UIManager.FullscreenConfirmUI)
	ui.Initialize(_translatedText, _onConfirm, _onCancel, _confirmText, _denyText)
	return ui
