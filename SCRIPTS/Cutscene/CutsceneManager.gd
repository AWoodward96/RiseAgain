extends Node2D

signal Initialized

@export var FTUE : CutsceneTemplate

var BlockAllInput : bool :
	get:
		return local_block_all_input && active_cutscene != null
var BlockCancelInput : bool :
	get:
		return local_block_cancel_input && active_cutscene != null
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


var local_block_cancel_input : bool
var local_block_all_input : bool

var local_block_ability_context : bool
var local_block_weapon_context : bool
var local_block_tactical_context : bool
var local_block_wait_context : bool

var active_cutscene : CutsceneTemplate
var queued_cutscenes : Array[CutsceneTemplate]
var cutscene_context : CutsceneContext

func _ready() -> void:
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
