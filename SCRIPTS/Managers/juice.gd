extends Node2D

@export var damagePopup : PackedScene
@export var damagePreview : PackedScene

@export_category("Camera Settings")
@export var cameraMoveSpeed = 10

@export_category("Health Bar Settings")
@export var HealthBarLossTime : float = 0.5

@export_category("Combat Settings")
@export var combatSequenceWarmupTimer = 0.5
@export var combatSequenceTimeBetweenAttackAndDefense = 0.2
@export var combatSequenceCooloffTimer = 0.1
@export var combatSequenceAttackOffset : float = 0.5
@export var combatSequenceDefenseOffset : float = 1
@export var combatSequenceReturnToOriginLerp = 4
@export var combatSequenceResetDistance = 0.1

@export var enemyTurnWarmup = 0.5

@export_category("Damage Preview Settings")
@export var damagePreviewDelayTime = 0.5
@export var damagePreviewTickDuration = 0.5

func CreateHealPopup(_healVal, _tile : Tile):
	var popup = damagePopup.instantiate()
	popup.SetHealValue(_healVal)
	popup.global_position = _tile.GlobalPosition
	add_child(popup)

func CreateDamagePopup(_damageVal, _tile : Tile):
	var popup = damagePopup.instantiate()
	popup.SetDamageValue(_damageVal)
	popup.global_position = _tile.GlobalPosition
	add_child(popup)

func CreateArmorPopup(_armorVal, _tile : Tile):
	var popup = damagePopup.instantiate()
	popup.SetArmorValue(_armorVal)
	popup.global_position = _tile.GlobalPosition
	add_child(popup)

func CreateMissPopup(_tile : Tile):
	var popup = damagePopup.instantiate()
	popup.SetMiss()
	popup.global_position = _tile.GlobalPosition
	add_child(popup)
	pass

func CreateDamageIndicator(_tile : Tile):
	var indicator = damagePreview.instantiate()
	indicator.global_position = _tile.GlobalPosition
	add_child(indicator)
	return indicator
