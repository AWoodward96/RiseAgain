extends FocusEntryPanel
class_name TeamGridPanel

signal OnUnitSelected(_unitTemplate : UnitTemplate)

@export var startWithFirstElementSelected : bool = true # just in case i want to reuse this element

@export var panelType : TeamManagementUI.UIMode = TeamManagementUI.UIMode.OutOfRun

var sorting : Callable
var unitTemplate : UnitTemplate

func Refresh():
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

	if sorting.is_valid():
		units.sort_custom(sorting)

	return units

func UpdateRequiredUnits(_unitList : Array[UnitTemplate]):
	for unitTempltae in _unitList:
		for createdInstances in entryParent.createdEntries:
			if createdInstances.template == unitTemplate && createdInstances.has_method("SetRequired"):
				createdInstances.SetRequired(true)


func OnFocusChanged(_element : Control):
	var index = entryParent.createdEntries.find(_element)
	if index != -1:
		lastFocusedElement = _element
		unitTemplate = entryParent.createdEntries[index].template
	pass

func EntrySelected(_entry : Control, _template : UnitTemplate):
	OnUnitSelected.emit(_template)
	pass
