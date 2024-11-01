extends CanvasLayer
class_name ExperienceGainUI

signal SequenceComplete
@export var fillTime : float = 0.5
@export var delayTime : float = 0.5
@export var statUpDelayTime : float = 0.25
@export var statBlockEntryPrefab : PackedScene
@onready var stat_entry_parent: EntryList = %StatEntryParent
@onready var current_level_label: Label = %CurrentLevelLabel


@onready var experience_progress_bar: ProgressBar = $ExperienceProgressBar
@onready var level_up_parent: Control = $LevelUpParent

var startingEXP
var startingLevel
var startingDisplayLevel
var tweenEXPGain
var statChanges
var levelsGained
var currentUnit : UnitInstance
var root : Node2D

func Initialize(_experienceGained : int, _unit : UnitInstance, _root : Node2D, _rng : RandomNumberGenerator):
	experience_progress_bar.visible = true
	level_up_parent.visible = false

	root = _root
	currentUnit = _unit
	startingEXP = _unit.Exp
	startingLevel = _unit.Level
	startingDisplayLevel = _unit.DisplayLevel
	levelsGained = _unit.AddExperience(_experienceGained)
	if levelsGained != 0:
		statChanges = _unit.PerformLevelUp(_rng, levelsGained)

	tweenEXPGain = get_tree().create_tween()
	tweenEXPGain.tween_method(UpdateExpGain, startingEXP, startingEXP + _experienceGained, fillTime)
	tweenEXPGain.tween_callback(ExpGainComplete.bind(_experienceGained))
	pass

func UpdateExpGain(_value):
	var current = _value
	while current >= 100:
		current -= 100
	experience_progress_bar.value = current
	pass

func ExpGainComplete(_netChange):
	await get_tree().create_timer(delayTime).timeout

	if levelsGained == 0:
		SequenceComplete.emit()
		queue_free()
		return

	ShowLevelUpData()
	pass

func ShowLevelUpData():
	level_up_parent.visible = true
	experience_progress_bar.visible = false
	current_level_label.text = str(startingDisplayLevel)

	for stats in GameManager.GameSettings.LevelUpStats:
		var entry = stat_entry_parent.CreateEntry(statBlockEntryPrefab)
		entry.icon.texture = stats.loc_icon
		var oldValue = currentUnit.GetWorkingStat(stats)
		if statChanges.has(stats):
			oldValue -= statChanges[stats]
		entry.statlabel.text = str(oldValue)

	await root.get_tree().create_timer(statUpDelayTime).timeout

	current_level_label.text = str(currentUnit.DisplayLevel)

	for increment in statChanges:
		if statChanges[increment] <= 0:
			continue
		var index = GameManager.GameSettings.LevelUpStats.find(increment)
		var entry = stat_entry_parent.GetEntry(index)
		entry.statIncreaseLabel.visible = true
		entry.statIncreaseLabel.text = str("+", statChanges[increment])
		entry.statlabel.text = str(currentUnit.GetWorkingStat(increment))
		await root.get_tree().create_timer(statUpDelayTime).timeout


	await InputManager.selectDownCallback

	if startingLevel < GameManager.GameSettings.FirstAbilityBreakpoint && startingLevel + levelsGained >= GameManager.GameSettings.FirstAbilityBreakpoint:
		var ui = SelectAbilityUI.Show(currentUnit, currentUnit.Template.Tier1Abilities)
		ui.SelectionComplete.connect(AbilitySelected)
		await ui.SelectionComplete

	SequenceComplete.emit()
	queue_free()
	pass

func AbilitySelected(_ability : PackedScene):
	currentUnit.AddAbility(_ability)

static func Show(_experienceGained : int, _unit :  UnitInstance, _root : Node2D, _rng : RandomNumberGenerator):
	var ui = UIManager.ExperienceUI.instantiate() as ExperienceGainUI
	_root.add_child(ui)
	ui.Initialize(_experienceGained, _unit, _root, _rng)
	return ui
