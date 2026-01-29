extends CanvasLayer

signal OnRosterSelected(_squad : Array[UnitTemplate], _level : int)
@export var UnitEntryPrefab : PackedScene
@export var SquadEntryPrefab : PackedScene
@export var ReadyButton : Button
@export var RemainingSlotsText : Label
@export var LevelOverride : LineEdit
@export var UnlockAbilities : CheckButton
@export var DebugOptionsParent : Control

@onready var unitEntryParent = %UnitEntryParent
@onready var squadEntryParent = %SquadEntryParent

var createdUnitEntries : Array[Control]
var unitSettings : UnitSettingsTemplate
var workingSquad : Array[UnitTemplate]
var maxSquadSize = 100 #defaulting to 100. If initialized by a map, this is set

func Initialize(_maxSquadSize : int):
	maxSquadSize = _maxSquadSize

func _ready():
	unitSettings = GameManager.UnitSettings
	ReadyButton.pressed.connect(OnReadyButton)
	if GameManager.GameSettings.ShowcaseMode:
		DebugOptionsParent.visible = false
	CreateUnitEntries()

func _process(_delta):
	if InputManager.startDown:
		OnReadyButton()

# Creates the unit entries in the grida
func CreateUnitEntries():
	for unit in unitSettings.AllyUnitManifest:
		var entry = UnitEntryPrefab.instantiate()
		entry.Initialize(unit)
		entry.OnUnitSelected.connect(OnUnitEntrySelected.bind(unit))
		unitEntryParent.add_child(entry)
		createdUnitEntries.append(entry)

	if createdUnitEntries.size() > 0:
		createdUnitEntries[0].grab_focus()

# Clears out the squad list, and updates it with the current squad data
func UpdateSquadList():
	for entry in squadEntryParent.get_children():
		entry.queue_free()

	for unit in workingSquad:
		var entry = SquadEntryPrefab.instantiate()
		entry.Initialize(unit)
		squadEntryParent.add_child(entry)

	RemainingSlotsText.text = "Remaining Slots: " + str(maxSquadSize - workingSquad.size())

# When a unit is selected, if it's already in the party, unselect it. If it isn't, then add it to it then update the squad list
func OnUnitEntrySelected(_unitTemplate : UnitTemplate):
	var indexOf = workingSquad.find(_unitTemplate)
	if indexOf == -1:
		if workingSquad.size() < maxSquadSize:
			workingSquad.append(_unitTemplate)
	else:
		workingSquad.remove_at(indexOf)
	UpdateSquadList()

func OnReadyButton():
	if workingSquad.size() > 0:
		OnRosterSelected.emit(workingSquad, int(LevelOverride.text))
		if UnlockAbilities.button_pressed:
			CSR.UnlockAllAbilities()
		queue_free()
