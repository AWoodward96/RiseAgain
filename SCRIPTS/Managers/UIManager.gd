extends Node2D

signal UIOpened(UI : FullscreenUI)
signal UIClosed(UI : FullscreenUI)

@export var AlphaUnitSelection : PackedScene
@export var AlphaFormationUI : PackedScene
@export var CombatHUDUI : PackedScene
@export var MapRewardUI : PackedScene
@export var ExperienceUI : PackedScene
@export var AbilitySelectionUI : PackedScene
@export var UnitInspectionUI : PackedScene
@export var CSRUI : PackedScene
@export var CampsiteUIPrefab : PackedScene
@export var CampsiteRestedPopupPrefab : PackedScene
@export var TradeUIPrefab : PackedScene

var CurrentInspectedElement : Control
var InspectActive : bool = false
var OpenUIs : Array[FullscreenUI]

# Notice: Loading screen is on the GameManager - not here
#
func _ready():
	get_viewport().gui_focus_changed.connect(OnNodeFocusedChanged)

func OnNodeFocusedChanged(_ctrl : Control):
	CurrentInspectedElement = _ctrl

func _process(_delta: float) -> void:
	if InputManager.infoDown:
		InspectActive = true
		if OpenUIs.size() > 0:
			OpenUIs[0].OnInspect()

func OnUIOpened(_ui : FullscreenUI):
	OpenUIs.append(_ui)
	OpenUIs.sort_custom(func(a : FullscreenUI, b : FullscreenUI): return a.layer < b.layer)
	InspectActive = false
	UIOpened.emit(_ui)

func OnUIClosed(_ui : FullscreenUI):
	InspectActive = false
	var index = OpenUIs.find(_ui)
	if index != -1:
		OpenUIs.remove_at(index)

	# remove null uis
	for i in range(OpenUIs.size() - 1, -1, -1):
		if OpenUIs[i] == null:
			OpenUIs.remove_at(i)
	
	UIClosed.emit(_ui)
