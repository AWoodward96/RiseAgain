extends Button
class_name ContextButtonEntry

func Initialize(_locTitle : String, _callback : Callable):
	text = _locTitle
	pressed.connect(_callback)
