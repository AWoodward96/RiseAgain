extends Control
class_name MultipanelController


@export var controls : Array[MultipanelBase]
@export var saveLastPanelIndex : bool = true

var openPanelIndex : int = 0
var lastOpenPanel : int = 0
var tabshift_cd : float = 0

func _ready():
	if saveLastPanelIndex:
		ShowPanel(lastOpenPanel)
	else:
		ShowPanel(0)
	pass


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("right"):
		if UIManager.CurrentInspectedElement == null || UIManager.CurrentInspectedElement.find_valid_focus_neighbor(SIDE_RIGHT) == null:
			ShowPanel(openPanelIndex + 1)
	if event.is_action_pressed("left"):
		if UIManager.CurrentInspectedElement == null || UIManager.CurrentInspectedElement.find_valid_focus_neighbor(SIDE_LEFT) == null:
			ShowPanel(openPanelIndex - 1)

func ShowPanel(_index : int):
	if controls.size() == 0:
		return

	# ensure that the index of this panel is correct
	var workingIndex = _index
	if workingIndex < 0:
		workingIndex += controls.size()

	if workingIndex >= controls.size():
		workingIndex = workingIndex % controls.size()

	openPanelIndex = workingIndex
	for i in range(0,controls.size()):
		var panel = controls[i]
		panel.Show(i == openPanelIndex)
		pass
