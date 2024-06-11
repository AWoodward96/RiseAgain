extends Control
class_name EntryList

# should be an array of whatever entries we're creating
var createdEntries : Array[Control]
var selectedIndex : int = -1

func ClearEntries():
	if createdEntries is Array && createdEntries != null:
		for e in createdEntries:
			remove_child(e)
			e.queue_free()

		createdEntries.clear()

	# This should reset the index list for the selection feature
	selectedIndex = -1

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


#func SetSelected(_index : int):
	#if selectedIndex != -1:
		#createdEntries[selectedIndex].SetSelected(false)
#
	#createdEntries[selectedIndex].SetSelected(true)
