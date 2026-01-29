extends Node2D
class_name UnitUsable

@export var internalName : String
@export var loc_displayName : String
@export var loc_displayDesc : String
@export var loc_flavorDesc : String
@export var icon : Texture2D
@export var descriptors : Array[DescriptorTemplate]

@export var TargetingTemplate : TargetingDataBase
@export var TargetingData : SkillTargetingData
@export var UsableDamageData : DamageData :
	get:
		if UsableDamageData != null && UsableDamageData.UseWeaponDataInstead && ownerUnit != null && ownerUnit.EquippedWeapon != null:
			return ownerUnit.EquippedWeapon.UsableDamageData

		return UsableDamageData
@export var StatData : ItemStatComponent
@export var HealData : HealComponent
@export var MovementData : AbilityMovementComponent
@export var EffectData : CombatEffectComponent
@export var SummonData : SummonUnitComponent
@export var customAITargetingBehavior : Script

var componentArray : Array[Node2D]
var ownerUnit : UnitInstance
var map : Map
var playerController : PlayerController

func _ready():
	GetComponents()
	pass

func Initialize(_unitOwner : UnitInstance):
	ownerUnit = _unitOwner
	GetComponents()

func SetMap(_map : Map):
	map = _map
	playerController = map.playercontroller

func GetRange():
	if TargetingTemplate != null:
		return TargetingTemplate.TargetRange

	if TargetingData != null:
		return TargetingData.TargetRange
	return Vector2i(0, 0)


func IsWithinRange(_currentPosition : Vector2, _target : Vector2):
	if TargetingData == null:
		return false

	var dst = (_target - _currentPosition).length()
	return dst >= TargetingData.TargetRange.x && dst <= TargetingData.TargetRange.y

func GetAccuracy():
	# Not quite sure if this is the right value to default to.
	# Healing should always be 100% accurate and might not have StatData, so we'll see
	return 100

func IsHeal():
	return HealData != null && UsableDamageData == null && TargetingData != null

func IsDamage():
	return UsableDamageData != null && TargetingData != null


func GetComponents():
	componentArray.clear()
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

		if MovementData == null && child is AbilityMovementComponent:
			MovementData = child as AbilityMovementComponent

		if EffectData == null && child is CombatEffectComponent:
			EffectData = child as CombatEffectComponent

		if SummonData == null && child is SummonUnitComponent:
			SummonData = child as SummonUnitComponent

	if TargetingData != null: componentArray.append(TargetingData)
	if UsableDamageData != null: componentArray.append(UsableDamageData)
	if StatData != null: componentArray.append(StatData)
	if HealData != null: componentArray.append(HealData)
	if MovementData != null: componentArray.append(MovementData)
	if EffectData != null: componentArray.append(EffectData)
	if SummonData != null: componentArray.append(SummonData)
