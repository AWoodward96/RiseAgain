extends Node2D
class_name Item

@export var loc_displayName : String
@export var loc_displayDesc : String
@export var icon : Texture2D

@export var TargetingData : SkillTargetingData
@export var SkillDamageData : DamageData
@export var StatData : ItemStatComponent

var context : CombatLog
var ownerUnit : UnitInstance
var map : Map
var selectedTileForExecution : Tile

var cachedTargets : Array[Tile]
var playerController : PlayerController :
	get:
		return map.playercontroller


func _ready():
	if TargetingData == null:
		TargetingData = get_node_or_null("TargetingComponent") as SkillTargetingData

	if SkillDamageData == null:
		SkillDamageData = get_node_or_null("DamageComponent") as DamageData

	if StatData == null:
		StatData = get_node_or_null("StatComponent") as ItemStatComponent

	pass


func Initialize(_unitOwner : UnitInstance, _map : Map):
	ownerUnit = _unitOwner
	map = _map

# This does the damage and effects for the ability
func ExecuteCombat(_optionalContext : CombatLog = null):
	# Either take the combat context passed in, or create a new one
	context = _optionalContext
	if context == null:
		context = CombatLog.new()
		context.Construct(map, ownerUnit, self, ownerUnit.CurrentTile, selectedTileForExecution)

	# ensure the context has this item ref
	if context.item == null:
		context.item = self

	# If there are no targeted tiles, take the ones that might have been cached by this script
	if context.targetTiles != null:
		context.targetTiles.append_array(cachedTargets)
	else:
		context.targetTiles = cachedTargets

	# The damage data is based on the damage component
	context.damageContext = SkillDamageData

	if !playerController.OnCombatSequenceComplete.is_connected(OnCombatExecutionComplete):
		playerController.OnCombatSequenceComplete.connect(OnCombatExecutionComplete)

	playerController.EnterCombatState(context)
	pass

func PollTargets():
	if playerController == null:
		return

	# if there's no targeting data, just yolo and execute the damn thing
	if TargetingData == null:
		ExecuteCombat()
		return

	TargetingData.GetAndShowTilesInRange(ownerUnit, map.grid)
	playerController.EnterTargetingState(self)
	if !playerController.OnTileSelected.is_connected(OnTargetTileSelected):
		playerController.OnTileSelected.connect(OnTargetTileSelected)
	pass

func ShowRangePreview():
	if TargetingData == null:
		return

	TargetingData.GetAndShowTilesInRange(ownerUnit, map.grid)

func OnCombatExecutionComplete():
	if playerController.OnCombatSequenceComplete.is_connected(OnCombatExecutionComplete):
		playerController.OnCombatSequenceComplete.disconnect(OnCombatExecutionComplete)

	ownerUnit.QueueEndTurn()

func OnTargetTileSelected(_tile : Tile):
	if playerController.OnTileSelected.is_connected(OnTargetTileSelected):
		playerController.OnTileSelected.disconnect(OnTargetTileSelected)

	selectedTileForExecution = _tile
	cachedTargets.clear()
	cachedTargets.append_array(TargetingData.GetAdditionalTileTargets(_tile))
	ExecuteCombat()
	pass

func CancelAbility():
	if playerController.OnTileSelected.is_connected(OnTargetTileSelected):
		playerController.OnTileSelected.disconnect(OnTargetTileSelected)
	cachedTargets.clear()

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
