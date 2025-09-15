extends Control
class_name TeamGridPanel

signal OnUnitSelected(_unitTemplate : UnitTemplate)


@export var autoInitialize : bool = true
@export var startWithFirstElementSelected : bool = true # just in case i want to reuse this element
@export var entryParent : EntryList
@export var entryPrefab : PackedScene

@export var panelType : TeamManagementUI.UIMode = TeamManagementUI.UIMode.OutOfRun

var unitTemplate : UnitTemplate
var lastFocusedElement : Control

func _ready() -> void:
	if autoInitialize:
		Refresh(panelType)
	UIManager.FocusChanged.connect(OnFocusChanged)

func Refresh(_type : TeamManagementUI.UIMode):
	panelType = _type
	var list = GetTeamList()
	entryParent.ClearEntries()
	for ut in list:
		var entry = entryParent.CreateEntry(entryPrefab)
		entry.Initialize(ut)
		entry.OnSelected.connect(EntrySelected)

	if startWithFirstElementSelected:
		entryParent.FocusFirst()


func GetTeamList():
	var units : Array[UnitTemplate] = []
	match panelType:
		TeamManagementUI.UIMode.OutOfRun:
			for persist in PersistDataManager.universeData.unitPersistData:
				if persist.Unlocked: # this is true for every basic unit rn, but won't be later
					units.append(persist.Template)
		TeamManagementUI.UIMode.InRun:
			if GameManager.CurrentCampaign != null:
				for unitInstances in GameManager.CurrentCampaign.CurrentRoster:
					# I think there will probably be a filter that's needed to be applied here but I can't think
					# of what that'd be so, fuck it. Every unit in your roster is good.
					units.append(unitInstances.Template)
					pass

	return units

func ReturnFocus():
	if lastFocusedElement != null:
		lastFocusedElement.grab_focus()
	else:
		entryParent.FocusFirst()

func EnableFocus(_enabled : bool):
	if _enabled:
		for entry in entryParent.createdEntries:
			entry.focus_mode = Control.FOCUS_ALL
	else:
		for entry in entryParent.createdEntries:
			entry.focus_mode = Control.FOCUS_NONE

func OnFocusChanged(_element : Control):
	var index = entryParent.createdEntries.find(_element)
	if index != -1:
		lastFocusedElement = _element
		unitTemplate = entryParent.createdEntries[index].template
	pass

func EntrySelected(_entry : Control, _template : UnitTemplate):
	OnUnitSelected.emit(_template)
	pass
