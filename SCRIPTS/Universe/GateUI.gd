extends FullscreenUI
class_name GateUI


enum EState { ObjectiveSelect, TeamSelect, Summary }

@export var Animator : AnimationPlayer
@export var ObjectiveSelectionPanel : ObjectiveSelectPanel
@export var AvailableUnitsPanel : TeamGridPanel

@export_category("Current Squad Data")
@export var currentSquadParent : EntryList
@export var currentSquadEntry : PackedScene
@export var continueButton : Button
@export var slotsRemainingLabel : Label

@export_category("Summary Panel Data")
@export var objectiveTitleLabel : Label
@export var objectiveDescLabel : Label
@export var objectiveIcon : TextureRect
@export var summarySquadParent : EntryList
@export var summarySquadEntry : PackedScene
@export var currentActiveFoodBuff : CurrentActiveFoodPanel
@export var embarkButton : Button


var currentState : EState = EState.ObjectiveSelect
var selectedCampaign : CampaignTemplate

func _ready():
	ObjectiveSelectionPanel.CampaignSelected.connect(CampaignSelected)
	AvailableUnitsPanel.OnUnitSelected.connect(UnitSelected)
	AvailableUnitsPanel.Refresh()
	EnterObjectiveSelect()
	pass

func _process(_delta):
	if !visible:
		return

	if IsInDetailState:
		return

	if InputManager.cancelDown:
		InputManager.ReleaseCancel()
		match currentState:
			EState.ObjectiveSelect:
				queue_free()
				return
			EState.TeamSelect:
				EnterObjectiveSelect()
			EState.Summary:
				EnterTeamSelect()

func EnterObjectiveSelect():
	currentState = EState.ObjectiveSelect
	continueButton.focus_mode = Control.FOCUS_NONE
	embarkButton.focus_mode = Control.FOCUS_NONE
	ObjectiveSelectionPanel.Refresh()
	ObjectiveSelectionPanel.EnableFocus(true)
	AvailableUnitsPanel.EnableFocus(false)
	Animator.play("ObjectiveSelect")

func EnterTeamSelect():
	if selectedCampaign.requiredUnit.size() > 0:
		for u in selectedCampaign.requiredUnit:
			if !PersistDataManager.universeData.bastionData.SelectedRoster.has(u):
				PersistDataManager.universeData.bastionData.SelectedRoster.push_front(u)
		PersistDataManager.universeData.bastionData.SelectedRoster.resize(selectedCampaign.startingRosterSize)

	continueButton.focus_mode = Control.FOCUS_ALL
	embarkButton.focus_mode = Control.FOCUS_NONE
	AvailableUnitsPanel.sorting = SortingUnits
	AvailableUnitsPanel.Refresh()
	AvailableUnitsPanel.UpdateRequiredUnits(selectedCampaign.requiredUnit)
	ObjectiveSelectionPanel.EnableFocus(false)
	AvailableUnitsPanel.EnableFocus(true)
	if currentState == EState.Summary:
		Animator.play("BackToTeamSelect")
	else:
		Animator.play("TeamSelect")
	currentState = EState.TeamSelect
	RefreshSquad()

func EnterSummary():
	currentState = EState.Summary
	continueButton.focus_mode = Control.FOCUS_NONE
	embarkButton.focus_mode = Control.FOCUS_ALL
	ObjectiveSelectionPanel.EnableFocus(false)
	AvailableUnitsPanel.EnableFocus(false)
	Animator.play("Summary")
	embarkButton.grab_focus()
	currentActiveFoodBuff.Refresh()
	RefreshSummary()

func RefreshSquad():
	var roster = PersistDataManager.universeData.bastionData.SelectedRoster
	slotsRemainingLabel.text = tr("ui_slots_remaining").format({"NUM" = selectedCampaign.startingRosterSize - roster.size()})
	continueButton.disabled = roster.size() == 0

	currentSquadParent.ClearEntries()
	for u in roster:
		if u == null:
			continue

		var entry = currentSquadParent.CreateEntry(currentSquadEntry) as UnitEntryUI
		entry.Initialize(u)
		entry.PlayAnimation("run_right")
		entry.focus_mode = Control.FOCUS_NONE

func RefreshSummary():
	objectiveTitleLabel.text = selectedCampaign.loc_name
	objectiveDescLabel.text = selectedCampaign.loc_desc
	objectiveIcon.texture = selectedCampaign.loc_icon

	summarySquadParent.ClearEntries()
	for u in PersistDataManager.universeData.bastionData.SelectedRoster:
		if u == null:
			continue

		var entry = summarySquadParent.CreateEntry(summarySquadEntry) as UnitEntryUI
		entry.Initialize(u)
		entry.PlayAnimation("run_right")
		entry.focus_mode = Control.FOCUS_NONE
	pass


func CampaignSelected(_campaignTemplate : CampaignTemplate):
	selectedCampaign = _campaignTemplate
	EnterTeamSelect()
	pass

func UnitSelected(_element, _unitTemplate : UnitTemplate):
	var roster = PersistDataManager.universeData.bastionData.SelectedRoster
	var index = roster.find(_unitTemplate)
	if index == -1:
		if selectedCampaign.startingRosterSize > roster.size():
			roster.append(_unitTemplate)
			if _element != null: _element.SetInRoster(true)
	else:
		var foundInReq = selectedCampaign.requiredUnit.find(_unitTemplate)
		if foundInReq == -1:
			roster.remove_at(index)
			if _element != null: _element.SetInRoster(false)


	PersistDataManager.universeData.bastionData.SelectedRoster = roster
	RefreshSquad()
	pass


func SortingUnits(_unitTemplate1 : UnitTemplate, _unitTemplate2 : UnitTemplate):
	if selectedCampaign != null:
		if selectedCampaign.requiredUnit.has(_unitTemplate1):
			return true

	var persist1 = PersistDataManager.universeData.GetUnitPersistence(_unitTemplate1)
	var persist2 = PersistDataManager.universeData.GetUnitPersistence(_unitTemplate2)

	if persist1 != null && persist2 == null:
		return true
	elif persist2 != null && persist1 == null:
		return false
	elif persist1 != null && persist2 != null:
		if persist1.Unlocked && !persist2.Unlocked:
			return true

	var atCampsite1 = PersistDataManager.universeData.bastionData.UnitsInCampsite.has(_unitTemplate1)
	var atCampsite2 = PersistDataManager.universeData.bastionData.UnitsInCampsite.has(_unitTemplate2)
	if atCampsite1 && !atCampsite2:
		return true
	elif atCampsite2 && !atCampsite1:
		return false

	var inTavern1 = PersistDataManager.universeData.bastionData.UnitsInTavern.has(_unitTemplate1)
	var inTavern2 = PersistDataManager.universeData.bastionData.UnitsInTavern.has(_unitTemplate2)
	if inTavern1 && !inTavern2:
		return true
	elif inTavern2 && !inTavern1:
		return false

	if (atCampsite1 || inTavern1) && (!atCampsite2 && !inTavern2):
		return true

	return false

func OnContinueFromTeamSelect():
	EnterSummary()

func OnEmabarkSelect():
	GameManager.StartCampaign(Campaign.CreateNewCampaignInstance(selectedCampaign, PersistDataManager.universeData.bastionData.SelectedRoster))
	queue_free()
	pass

func ReturnFocus():
	match currentState:
		EState.ObjectiveSelect:
			ObjectiveSelectionPanel.ReturnFocus()
		EState.TeamSelect:
			AvailableUnitsPanel.ReturnFocus()
		EState.Summary:
			embarkButton.grab_focus()
	pass
