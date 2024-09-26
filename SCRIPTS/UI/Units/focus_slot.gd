extends MarginContainer

@export var on_state: ColorRect
@export var off_state: ColorRect


func Toggle(_on : bool):
	on_state.visible = _on
	off_state.visible = !_on
