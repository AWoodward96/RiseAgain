extends Node2D

signal Initialized

@export var FTUE : CutsceneTemplate


@export var TutorialPromptParent : Node
@export var TutorialPanel : Control
@export var TutorialText : RichTextLabel
@export var PressAnyKey : Control
@export var WaitTimeParent : Control
@export var WaitTimeBar : ProgressBar

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

func _ready() -> void:
	TutorialPromptParent.visible = false
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
