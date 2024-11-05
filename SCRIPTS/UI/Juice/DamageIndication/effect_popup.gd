extends Node

@export var sprite : Sprite2D
@export var text : Label



func SetEffect(_effectInstance : CombatEffectInstance):
	var template = _effectInstance.Template
	if template == null:
		queue_free()

	if text != null: text.text = template.loc_name
	if sprite != null: sprite.texture = template.loc_icon
