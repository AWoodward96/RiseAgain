extends Node2D
class_name UnitUsable

@export var internalName : String
@export var loc_displayName : String
@export var loc_displayDesc : String
@export var icon : Texture2D

@export var TargetingData : SkillTargetingData
@export var UsableDamageData : DamageData
@export var StatData : ItemStatComponent
@export var HealData : HealComponent
@export var StatConsumableData : StatConsumableComponent
@export var MovementData : AbilityMovementComponent
@export var EffectData : CombatEffectComponent


var ownerUnit : UnitInstance
var map : Map
var playerController : PlayerController :
	get:
		return map.playercontroller

func _ready():
	GetComponents()
	pass

func Initialize(_unitOwner : UnitInstance, _map : Map):
	ownerUnit = _unitOwner
	map = _map
	GetComponents()

func SetMap(_map : Map):
	map = _map

func ShowRangePreview():
	if map == null:
		return

	if TargetingData == null:
		map.grid.ClearActions()
		return

	var availableTargets = TargetingData.GetTilesInRange(ownerUnit, map.grid)
	for t in availableTargets:
		t.CanAttack = true

	map.grid.ShowActions()

func GetRange():
	if TargetingData != null:
		return TargetingData.TargetRange
	return Vector2i(0, 0)


func IsWithinRange(_currentPosition : Vector2, _target : Vector2):
	if TargetingData == null:
		return false

	var dst = (_target - _currentPosition).length()
	return dst >= TargetingData.TargetRange.x && dst <= TargetingData.TargetRange.y

func GetAccuracy():
	if StatData != null:
		return StatData.BaseAccuracy

	# Not quite sure if this is the right value to default to.
	# Healing should always be 100% accurate and might not have StatData, so we'll see
	return 100

func IsHeal(_includingConsumables : bool):
	if _includingConsumables:
		return HealData != null && UsableDamageData == null
	else:
		return HealData != null && UsableDamageData == null && TargetingData != null

func IsDamage():
	return UsableDamageData != null && TargetingData != null


func GetComponents():
	var children = get_children()
	for child in children:
		if TargetingData == null && child is SkillTargetingData:
			TargetingData = child as SkillTargetingData

		if UsableDamageData == null && child is DamageData:
			UsableDamageData = child as DamageData

		if StatData == null && child is ItemStatComponent:
			StatData = child as ItemStatComponent

		if HealData == null && child is HealComponent:
			HealData = child as HealComponent

		if StatConsumableData == null && child is StatConsumableComponent:
			StatConsumableData = child as StatConsumableComponent

		if MovementData == null && child is AbilityMovementComponent:
			MovementData = child as AbilityMovementComponent

		if EffectData == null && child is CombatEffectComponent:
			EffectData = child as CombatEffectComponent
