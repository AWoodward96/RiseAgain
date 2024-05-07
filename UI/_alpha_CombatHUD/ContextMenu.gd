extends Control
class_name ContextMenu

signal ActionSelected(_ability : AbilityInstance)

@export var entryPrefab : PackedScene
@export var waitButton : Button
@export var entryParent : Control

var currentUnit : UnitInstance
var createdButtons : Array[Control]

func Initialize(_unit : UnitInstance):
	currentUnit = _unit
	for a in _unit.Abilities:
		var entry = entryPrefab.instantiate()
		entry.Initialize(a)
		entry.pressed.connect(OnAbilityButton.bind(a))
		entryParent.add_child(entry)
		createdButtons.append(entry)
	
	for i in createdButtons.size():
		entryParent.move_child(createdButtons[i], i)
		
	entryParent.move_child(waitButton, createdButtons.size() + 1)
	entryParent.get_child(0).grab_focus()
	
func OnWaitButton():
	ActionSelected.emit(null)
	pass

func OnAbilityButton(_ability : AbilityInstance):
	ActionSelected.emit(_ability)
	pass

func Clear():
	for c in createdButtons:
		c.queue_free()
	createdButtons.clear()
