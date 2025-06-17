extends Node2D

const CHARACTER_PER_SECOND = 0.02
signal Initialized

signal EventPromptScrawlComplete
signal EventDecisionChosen(_decision : int)

@export var FTUE : CutsceneTemplate

@export_category("Tutorial References")
@export var TutorialPromptParent : Node
@export var TutorialPanel : Control
@export var TutorialText : RichTextLabel
@export var PressAnyKey : Control
@export var WaitTimeParent : Control
@export var WaitTimeBar : ProgressBar


@export_category("Event References")
@export var EventParent : Node
@export var EventText : RichTextLabel
@export var EventPromptParent : Control
@export var EventDecisionParent : Control
@export var EventOptionParent : EntryList
@export var EventOptionPrefab : PackedScene

var BlockMovementInput : bool :
	get:
		return local_block_movement_input && active_cutscene != null

var BlockCancelInput : bool :
	get:
		return local_block_cancel_input && active_cutscene != null

var BlockSelectInput : bool :
	get:
		return local_block_select_input && active_cutscene != null

# Otherwise known as the threat button
var BlockInspectInput : bool :
	get:
		return local_block_inspect_input && active_cutscene != null


var BlockAbilityContextMenuOption : bool :
	get:
		return local_block_ability_context && active_cutscene != null

var BlockWeaponContextMenuOption : bool :
	get:
		return local_block_weapon_context && active_cutscene != null

var BlockTacticalContextMenuOption : bool :
	get:
		return local_block_tactical_context && active_cutscene != null

var BlockWaitContextMenuOption : bool :
	get:
		return local_block_wait_context && active_cutscene != null

var InvisibleReticle : bool :
	get:
		return local_invisible_reticle && active_cutscene != null

var BlockWincon : bool :
	get:
		return local_block_wincon && active_cutscene != null

var BlockEnterAction : bool :
	get:
		return local_block_enter_action && active_cutscene != null



var local_block_select_input : bool
var local_block_cancel_input : bool
var local_block_inspect_input : bool
var local_block_movement_input : bool

var local_block_wincon : bool
var local_invisible_reticle : bool
var local_block_enter_action : bool

var local_block_ability_context : bool
var local_block_weapon_context : bool
var local_block_tactical_context : bool
var local_block_wait_context : bool

var active_cutscene : CutsceneTemplate
var queued_cutscenes : Array[CutsceneTemplate]
var cutscene_context : CutsceneContext

var textScrawlTween : Tween

func _ready() -> void:
	TutorialPromptParent.visible = false
	EventParent.visible = false
	QueueCutscene(FTUE)
	Initialized.emit()

func QueueCutscene(_cutsceneTemplate : CutsceneTemplate):
	if _cutsceneTemplate == null:
		return

	if !_cutsceneTemplate.repeatable && PersistDataManager.universeData.completedCutscenes.has(_cutsceneTemplate):
		return

	# Can't queue a cutscene more than once
	if queued_cutscenes.has(_cutsceneTemplate):
		return

	queued_cutscenes.append(_cutsceneTemplate)
	print("CutsceneManager: Queued Cutscene: " + _cutsceneTemplate.resource_path + ", current queue count: " + str(queued_cutscenes.size()))
	CheckStartCutscene()
	pass

func CheckStartCutscene():
	if queued_cutscenes.size() > 0 && active_cutscene == null:
		for cutscene in queued_cutscenes:
			if cutscene.CanStart(null):
				active_cutscene = cutscene
				break

		# if we found a new active one
		if active_cutscene != null:
			var index = queued_cutscenes.find(active_cutscene)
			queued_cutscenes.remove_at(index)
			active_cutscene.index = -1
			cutscene_context = CutsceneContext.new()
			cutscene_context.Template = active_cutscene
			print("CutsceneManager: Starting Cutscene: " + active_cutscene.resource_path)

func _process(delta: float) -> void:
	CheckStartCutscene()

	if active_cutscene != null:
		if active_cutscene.Execute(delta, cutscene_context):
			if active_cutscene.autoComplete:
				if !PersistDataManager.universeData.completedCutscenes.has(active_cutscene):
					PersistDataManager.universeData.completedCutscenes.append(active_cutscene)
					PersistDataManager.universeData.Save()
			print("CutsceneManager: Cutscene Ended: " + active_cutscene.resource_path)
			active_cutscene = null

func ShowGlobalTutorialPrompt(_text : String, _anchor : Control.LayoutPreset, _promptSize : Vector2, _pressAnyKey : bool):
	TutorialPromptParent.visible = true
	TutorialPanel.visible = true
	TutorialText.text = _text
	TutorialPanel.set_anchors_and_offsets_preset(_anchor, Control.PRESET_MODE_MINSIZE)
	TutorialPanel.size = _promptSize
	pass

func ShowEventPrompt(_textTranslated : String, _instantaneousText : bool):
	EventParent.visible = true
	EventPromptParent.visible = true
	EventDecisionParent.visible = false

	EventText.text = _textTranslated
	if _instantaneousText:
		EventText.visible_characters = -1
	else:
		EventText.visible_characters = 0
		textScrawlTween = create_tween()
		textScrawlTween.tween_property(EventText, "visible_characters", _textTranslated.length(), _textTranslated.length() * CHARACTER_PER_SECOND)
		textScrawlTween.finished.connect(ForceCompleteEventPromptScrawl)

func ForceCompleteEventPromptScrawl():
	textScrawlTween.stop()
	textScrawlTween = null
	EventText.visible_characters = -1
	EventPromptScrawlComplete.emit()


func ShowEventDecision(_decisions : Array[EventDecision], _context):
	EventParent.visible = true
	EventPromptParent.visible = false
	EventDecisionParent.visible = true

	EventOptionParent.ClearEntries()
	var decisionIndex = 0
	for dec in _decisions:
		var passReq = true
		for r in dec.requirements:
			if r == null:
				continue

			var res = r.CheckRequirement(_context)
			if !res && !r.NOT || res && r.NOT:
				passReq = false

		# If you don't pass the hidden requirement for this option to be shown, don't let it exist
		if !passReq && dec.hiddenRequirement:
			decisionIndex += 1 # gotta up the index to keep the reference consistent
			continue

		var entry = EventOptionParent.CreateEntry(EventOptionPrefab) as EventOptionEntryUI
		entry.Initialize(dec, passReq, decisionIndex, _context)
		entry.EntrySelected.connect(DecisionSelected.bind(decisionIndex))
		decisionIndex += 1

	EventOptionParent.FocusFirst()
	pass

func DecisionSelected(_int : int):
	EventDecisionChosen.emit(_int)

func UpdateTutorialPromptWaitTime(_cur : float = -1, _max : float = -1):
	if _cur == -1 && _max == -1:
		PressAnyKey.visible = false
		WaitTimeBar.visible = false
		WaitTimeParent.visible = false
		return

	PressAnyKey.visible = _cur >= _max
	WaitTimeParent.visible = _cur < _max
	WaitTimeBar.visible = _cur < _max
	WaitTimeBar.value = _cur / _max


func HideGlobalTutorialPrompt():
	TutorialPromptParent.visible = false
	TutorialPanel.visible = false

func HideEventPrompt():
	EventParent.visible = false
