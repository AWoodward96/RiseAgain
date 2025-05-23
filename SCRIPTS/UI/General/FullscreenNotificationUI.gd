extends FullscreenUI
class_name FullscreenNotificationUI

signal OnTimeout

@export var rich_text_label: RichTextLabel
@export var timer: Timer


func AddSoundEffect(_soundPath : String):
	var inlineEvent = FmodServer.create_event_instance(_soundPath)
	inlineEvent.start()

func AddAutoTimeout(_timeInSeconds : float):
	timer.start(_timeInSeconds)
	timer.timeout.connect(Timeout)

func AddTranlatedText(_text : String):
	rich_text_label.append_text(tr(_text))

func AddIcon(_image : Texture2D, _size : Vector2, _color : Color = Color(1,1,1,1)):
	rich_text_label.add_image(_image, _size.x, _size.y, _color)
	rich_text_label.append_text(" ") # Adding a blank to format thjis a little bit since the icon is inline

func Timeout():
	OnTimeout.emit()
	queue_free()
