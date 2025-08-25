extends CanvasLayer
class_name FullscreenUI


func _enter_tree() -> void:
	UIManager.UIOpened.emit(self)

func _exit_tree() -> void:
	UIManager.UIClosed.emit(self)
