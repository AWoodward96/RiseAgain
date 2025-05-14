extends Node

@export var sprite : Sprite2D
@export var text : Label

func SetAbility(_ability : Ability):
	if _ability == null:
		queue_free()

	if text != null: text.text = _ability.loc_displayName
	if sprite != null:
		var icon = GameManager.LocalizationSettings.Missing_CombatEffectIcon
		if _ability.icon != null:
			icon = _ability.icon
		sprite.texture = icon
