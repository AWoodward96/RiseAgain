extends Control
class_name AnchoredUIElement

@export var Priority : int = 1
@export var PreferredAnchor : Array[Control.LayoutPreset]
@export var AvailableAnchors : Array[Control.LayoutPreset]
@export var Disabled : bool
var GlobalDisable : bool


func RefreshAnchor(_availableSlots : Array[Control.LayoutPreset]):
	if _availableSlots.size() == 0 || Disabled || GlobalDisable:
		hide()
		return null

	show()
	# block the top right cornor if the resourceUI is open
	if _availableSlots.has(Control.LayoutPreset.PRESET_TOP_RIGHT) && GlobalUIHelper.IsShowingResourceUI:
		var index = _availableSlots.find(Control.LayoutPreset.PRESET_TOP_RIGHT)
		_availableSlots.remove_at(index)

	for anchor in PreferredAnchor:
		if _availableSlots.has(anchor):
			set_anchors_and_offsets_preset(anchor)
			return anchor

	for slot in _availableSlots:
		if AvailableAnchors.has(slot):
			set_anchors_and_offsets_preset(slot)
			return slot

	# If we've gotten here, there are no available anchors, so hide
	hide()
	return null


func _process(_delta: float) -> void:
	if GlobalDisable:
		visible = false
	else:
		visible = !Disabled
