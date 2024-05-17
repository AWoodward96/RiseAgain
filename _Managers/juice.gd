extends Node2D

@export var damagePopup : PackedScene

@export_category("Camera Settings")
@export var cameraMoveSpeed = 10


@export_category("Combat Settings")
@export var combatSequenceWarmupTimer = 0.5
@export var combatSequenceTimeBetweenAttackAndDefense = 0.2
@export var combatSequenceCooloffTimer = 0.1
@export var combatSequenceAttackOffset = 0.5
@export var combatSequenceDefenseOffset = 1
@export var combatSequenceReturnToOriginLerp = 4
@export var combatSequenceResetDistance = 0.1
@export var combatSequenceTickDuration = 0.5

@export var enemyTurnWarmup = 0.5

@export_category("Damage Preview Settings")
@export var damagePreviewDelayTime = 0.5
@export var damagePreviewTickDuration = 0.5


func CreateDamagePopup(_damageVal, _tile : Tile):
	var popup = damagePopup.instantiate()
	popup.SetValue(_damageVal)
	popup.global_position = _tile.GlobalPosition
	add_child(popup)

func CreateMissPopup(_tile : Tile):
	var popup = damagePopup.instantiate()
	popup.SetMiss()
	popup.global_position = _tile.GlobalPosition
	add_child(popup)
	pass
