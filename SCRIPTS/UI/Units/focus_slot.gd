extends MarginContainer

@onready var on_state: ColorRect = $MarginContainer/OnState
@onready var off_state: ColorRect = $MarginContainer/OffState


func Toggle(_on : bool):
	on_state.visible = _on
	off_state.visible = !_on
