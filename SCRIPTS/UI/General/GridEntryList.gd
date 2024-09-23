extends EntryList
class_name GridEntryList

@export var slots : Array[Control]
@export var entriesPerSlot : int = 3
@export var mirror : bool


func ClearEntries():
	if createdEntries is Array && createdEntries != null:
		for e in createdEntries:
			if e == null:
				continue

			var parent = e.get_parent()
			if parent != null:
				parent.remove_child(e)
			e.queue_free()

		createdEntries.clear()

func CreateEntry(_prefab : PackedScene):
	var entry = _prefab.instantiate()

	if !mirror:
		# Will count up filling the slots in ascending order
		for i in range(0, slots.size()):
			var slot = slots[i]
			var childrenCount = slot.get_child_count(false)
			if childrenCount >= entriesPerSlot:
				continue
			else:
				slot.add_child(entry)
				break
	else:
		# Will cound down, filling the slots in decending order
		for i in range(slots.size() - 1, -1, -1):
			var slot = slots[i]
			var childrenCount = slot.get_child_count(false)
			if childrenCount >= entriesPerSlot:
				continue
			else:
				slot.add_child(entry)
				break

	createdEntries.append(entry)
	return entry

func SetMirror(_mirror : bool):
	# reorder the created entries from back to front instead of front to back
	mirror = _mirror
	pass
