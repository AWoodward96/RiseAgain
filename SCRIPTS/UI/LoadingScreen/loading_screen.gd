extends CanvasLayer
class_name LoadingScreen

signal ScreenObscured
signal ScreenCleared

@export var Screen : ColorRect
var tween : Tween

func ShowLoadingScreen(_fadeTime = 1.5, lambda = null):
	Screen.visible = true
	if _fadeTime <= 0:
		Screen.modulate.a = 1
		if tween != null: tween.kill()
		return
	else:
		Screen.modulate.a = 0

	tween = create_tween()
	tween.tween_property(Screen, "modulate:a", 1, _fadeTime)
	tween.tween_callback(ObscureComplete.bind(lambda))

func HideLoadingScreen(_fadeTime = 1.5, lambda = null):
	if _fadeTime <= 0:
		Screen.modulate.a = 0
		if tween != null: tween.kill()
		return
	else:
		Screen.modulate.a = 1

	tween = create_tween()
	tween.tween_property(Screen, "modulate:a", 0, _fadeTime)
	tween.tween_callback(ClearComplete.bind(lambda))


func ObscureComplete(lambda):
	ScreenObscured.emit()

	if lambda != null:
		lambda.call()

func ClearComplete(lambda):
	Screen.visible = false
	ScreenCleared.emit()

	if lambda != null:
		lambda.call()
