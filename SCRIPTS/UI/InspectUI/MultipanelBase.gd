extends Control
class_name MultipanelBase

func _ready():
	visibility_changed.connect(OnVisiblityChanged)

func Show(_show : bool):
	visible = _show

func OnVisiblityChanged():
	pass
