extends CanvasLayer

signal OnClose

func _process(_delta):
	if InputManager.selectDown:
		OnClose.emit()
		queue_free()
