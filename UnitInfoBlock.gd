extends Control
class_name UnitInfoBlock

@export var statBlockEntry : PackedScene
@export var statBlockParent : EntryList
@export var unitIcon : TextureRect

func Initialize(_unitInstance : UnitInstance):
	unitIcon.texture = _unitInstance.Template.icon

	statBlockParent.ClearEntries()
	for stat in _unitInstance.currentStats:
		var entry = statBlockParent.CreateEntry(statBlockEntry)
		entry.icon.texture = stat.loc_icon
		entry.statlabel.text = "%d" % _unitInstance.GetWorkingStat(stat)
