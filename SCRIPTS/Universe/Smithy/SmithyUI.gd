extends FullscreenUI
class_name SmithyUI


@export var Tabs : Array[SmithyEntryTabUI]
@export var TabBarUI : TabBar
@export var SmithyLevelNumber : Label

var currentTab : SmithyEntryTabUI
var currentTabIndex : int = 0

func _ready():
	super()
	SmithyLevelNumber.text = tr(LocSettings.Level_Num).format({"NUM" = PersistDataManager.universeData.bastionData.CurrentSmithyLevel + 1})
	SwitchTabs(0)

func _process(_delta):
	if !IsInDetailState:
		if UIManager.HighestLevelUI == self:
			if InputManager.inputDown[1]:
				SwitchTabs(currentTabIndex + 1)
			elif InputManager.inputDown[3]:
				SwitchTabs(currentTabIndex - 1)


func SwitchTabs(_newTabIndex : int):
	var i = _newTabIndex
	if i >= Tabs.size():
		i = i % Tabs.size()

	if i < 0:
		i = Tabs.size() - 1

	if currentTab != null:
		currentTab.visible = false

	currentTab = Tabs[i]
	currentTab.visible = true
	currentTab.Refresh()
	currentTabIndex = i
	TabBarUI.current_tab = currentTabIndex


func _exit_tree() -> void:
	super()
	UIManager.HideResources()

func _enter_tree() -> void:
	super()
	UIManager.ShowResources()

func ReturnFocus():
	currentTab.ReturnFocus()
