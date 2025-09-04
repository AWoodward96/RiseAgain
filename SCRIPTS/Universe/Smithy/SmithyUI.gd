extends FullscreenUI
class_name SmithyUI

@export var Tabs : Array[SmithyEntryTabUI]
@export var TabBarUI : TabBar

var currentTab : SmithyEntryTabUI

func _ready():
	currentTab = Tabs[0]
	GameManager.GlobalUI.ShowResources()

func _exit_tree() -> void:
	super()
	GameManager.GlobalUI.HideResources()


func ReturnFocus():
	currentTab.ReturnFocus()
