extends Control
class_name EntryList

# should be an array of whatever entries we're creating
var createdEntries : Array[Control]

func ClearEntries():
	if createdEntries is Array && createdEntries != null:
		for e in createdEntries:
			if e == null:
				continue

			remove_child(e)
			e.queue_free()

		createdEntries.clear()

func SetEntryFocus(_focus : Control.FocusMode):
	for e in createdEntries:
		e.focus_mode = _focus

func CreateEntry(_prefab : PackedScene):
	var entry = _prefab.instantiate()
	add_child(entry)
	createdEntries.append(entry)
	return entry

func GetEntry(_index : int):
	if createdEntries is Array && createdEntries != null && createdEntries.size() > _index && _index >= 0:
		return createdEntries[_index]
	return null

func FocusFirst():
	if createdEntries is Array && createdEntries != null && createdEntries.size() > 0:
		createdEntries[0].grab_focus()
