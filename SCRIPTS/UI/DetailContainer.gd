extends Control
class_name DetailContainer

@export var Details : Array[DetailEntry]


func BeginShowDetails():
	if Details.size() == 0:
		return false

	for d in Details:
		if d == null:
			continue
		d.EnableFocus()

	UIManager.GlobalUIInstance.ShowDetailOfElement(Details[0])
	Details[0].grab_focus()
	return true

func UpdateShowDetail(_ctrl : Control):
	if _ctrl is DetailEntry:
		UIManager.GlobalUIInstance.ShowDetailOfElement(_ctrl as DetailEntry)

func EndShowDetails():
	for d in Details:
		d.DisableFocus()

	UIManager.GlobalUIInstance.HideDetail()
