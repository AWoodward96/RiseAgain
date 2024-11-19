extends Node2D

@export var damagePopup : PackedScene
@export var damagePreview : PackedScene
@export var effectPopup : PackedScene
@export var critPopup : PackedScene

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
@export var combatPopupCooldown : float = 0.5

@export var enemyTurnWarmup = 0.5

@export_category("Damage Preview Settings")
@export var damagePreviewDelayTime = 0.5
@export var damagePreviewTickDuration = 0.5

func CreateHealPopup(_healVal, _tile : Tile):
	var popup = damagePopup.instantiate()
	popup.SetHealValue(_healVal)
	popup.global_position = _tile.GlobalPosition
	add_child(popup)
	_tile.QueuePopup(popup)

func CreateDamagePopup(_damageVal, _tile : Tile):
	var popup = damagePopup.instantiate()
	popup.SetDamageValue(_damageVal)
	popup.global_position = _tile.GlobalPosition
	add_child(popup)
	_tile.QueuePopup(popup)

func CreateArmorPopup(_armorVal, _tile : Tile):
	var popup = damagePopup.instantiate()
	popup.SetArmorValue(_armorVal)
	popup.global_position = _tile.GlobalPosition
	add_child(popup)
	_tile.QueuePopup(popup)

func CreateMissPopup(_tile : Tile):
	var popup = damagePopup.instantiate()
	popup.SetMiss()
	popup.global_position = _tile.GlobalPosition
	add_child(popup)
	_tile.QueuePopup(popup)
	pass

func CreateEffectPopup(_tile : Tile, _effectInstance : CombatEffectInstance):
	var popup = effectPopup.instantiate()
	popup.SetEffect(_effectInstance)
	popup.global_position = _tile.GlobalPosition
	add_child(popup)
	_tile.QueuePopup(popup)
	pass

func CreateCritPopup(_tile : Tile):
	var popup = critPopup.instantiate()
	popup.global_position = _tile.GlobalPosition
	add_child(popup)
	_tile.QueuePopup(popup)
	pass

func CreateDamageIndicator(_tile : Tile):
	var indicator = damagePreview.instantiate()
	indicator.global_position = _tile.GlobalPosition
	add_child(indicator)
	return indicator
