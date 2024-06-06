extends CanvasLayer

signal FormationSelected

@export var MoveInfoPanelParent : Control

func _ready():
	ShowSwapWithPanel(false)

func _process(_delta):
	if InputManager.startDown:
		FormationSelected.emit()
		queue_free()

func ShowSwapWithPanel(_val : bool):
	MoveInfoPanelParent.visible = _val
