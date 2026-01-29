extends Control
class_name FocusEntryPanel

@export var auto_initialize : bool = false
@export var entryParent : EntryList
@export var entryPrefab : PackedScene

var lastFocusedElement : Control

func _ready():
	UIManager.FocusChanged.connect(OnFocusChanged)
	if auto_initialize:
		Refresh()
	pass

func Refresh():
	pass

func ReturnFocus():
	if lastFocusedElement != null:
		lastFocusedElement.grab_focus()
	else:
		entryParent.FocusFirst()

func OnFocusChanged(_element : Control):
	var index = entryParent.createdEntries.find(_element)
	if index != -1:
		lastFocusedElement = _element
	pass


func EnableFocus(_enabled : bool):
	if _enabled:
		for entry in entryParent.createdEntries:
			entry.focus_mode = Control.FOCUS_ALL
	else:
		for entry in entryParent.createdEntries:
			entry.focus_mode = Control.FOCUS_NONE
