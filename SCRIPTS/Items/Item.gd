extends Node2D
class_name Item

@export var internalName : String
@export var loc_displayName : String
@export var loc_displayDesc : String
@export var icon : Texture2D

@export var TargetingData : SkillTargetingData
@export var ItemDamageData : DamageData
@export var StatData : ItemStatComponent
@export var HealData : HealComponent
@export var StatConsumableData : StatConsumableComponent

@export var UsageLimit : int = -1

var ownerUnit : UnitInstance
var map : Map
var currentUsages = 1

var cachedTargets : Array[Tile]
var playerController : PlayerController :
	get:
		return map.playercontroller


func _ready():
	GetComponents()
	pass

func Initialize(_unitOwner : UnitInstance, _map : Map):
	ownerUnit = _unitOwner
	map = _map

	currentUsages = UsageLimit
	GetComponents()

func SetMap(_map : Map):
	map = _map

func GetComponents():
	var children = get_children()
	for child in children:
		if TargetingData == null && child is SkillTargetingData:
			TargetingData = child as SkillTargetingData

		if ItemDamageData == null && child is DamageData:
			ItemDamageData = child as DamageData

		if StatData == null && child is ItemStatComponent:
			StatData = child as ItemStatComponent

		if HealData == null && child is HealComponent:
			HealData = child as HealComponent

		if StatConsumableData == null && child is StatConsumableComponent:
			StatConsumableData = child as StatConsumableComponent

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

func GetAccuracy():
	if StatData != null:
		return StatData.BaseAccuracy

	# Not quite sure if this is the right value to default to.
	# Healing should always be 100% accurate and might not have StatData, so we'll see
	return 100

func IsWithinRange(_currentPosition : Vector2, _target : Vector2):
	if TargetingData == null:
		return false

	var dst = (_target - _currentPosition).length()
	return dst >= TargetingData.TargetRange.x && dst <= TargetingData.TargetRange.y

func OnUse():
	# It's a bit unclear how this will actually work, but for now use items are just
	# healing items. They're applied to yourself, and nothing else
	var isUsed = false
	# for now, assume that the owner of this item is also the target of this item
	if HealData != null:
		# Okay then this is a heal, pass the heal amount to ourselfs
		var targets : Array[UnitInstance] = [ownerUnit]
		ownerUnit.QueueHealAction(HealData, targets)
		isUsed = true


	if StatConsumableData != null:
		for statDef in StatConsumableData.StatsToGrant:
			ownerUnit.ApplyStatModifier(statDef)
			isUsed = true


	if UsageLimit != -1 && isUsed:
		currentUsages -= 1
		if currentUsages <= 0:
			ownerUnit.TrashItem(self)

	if isUsed:
		ownerUnit.QueueEndTurn()
		playerController.EnterUnitStackClearState(ownerUnit)
	pass


func IsHeal(_includingConsumables : bool):
	if _includingConsumables:
		return HealData != null && ItemDamageData == null
	else:
		return HealData != null && ItemDamageData == null && TargetingData != null

func IsDamage():
	return ItemDamageData != null && TargetingData != null

func ToJSON():
	return {
		"Item" : scene_file_path,
		"currentUsages" : currentUsages
	}
