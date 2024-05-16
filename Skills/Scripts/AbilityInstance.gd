extends Node2D
class_name AbilityInstance

@export var loc_displayName : String
@export var loc_displayDesc : String
@export var AutoEndTurn = true
@export var TargetingData : SkillTargetingData
@export var SkillDamageData : DamageData

var persisted_dictionary = {}
var context : CombatLog
var ownerUnit : UnitInstance
var map : Map
var selectedTileForExecution : Tile

var cachedTargets : Array[Tile]
var playerController : PlayerController :
	get:
		return map.playercontroller

var active = false

func _ready():
	if TargetingData == null:
		TargetingData = get_node_or_null("TargetingComponent") as SkillTargetingData

	if SkillDamageData == null:
		SkillDamageData = get_node_or_null("DamageComponent") as DamageData

	pass

func Initialize(_unitOwner : UnitInstance, _map : Map):
	ownerUnit = _unitOwner
	map = _map

func _process(_delta):
	pass

# This does the damage and effects for the ability
func ExecuteAbility(_optionalContext : CombatLog = null):
	context = _optionalContext
	if context == null:
		context = CombatLog.new()
		context.Construct(map, ownerUnit, self)

	if context.targetTiles != null:
		context.targetTiles.append_array(cachedTargets)
	else:
		context.targetTiles = cachedTargets

	if context.originTile == null:
		context.originTile = selectedTileForExecution

	context.damageContext = SkillDamageData

	if !playerController.OnCombatSequenceComplete.is_connected(OnAbilityExecutionComplete):
		playerController.OnCombatSequenceComplete.connect(OnAbilityExecutionComplete)

	playerController.EnterCombatState(context)
	pass

func PollTargets():
	if playerController == null:
		return

	# if there's no targeting data, just yolo and execute the damn thing
	if TargetingData == null:
		ExecuteAbility()
		return

	TargetingData.GetTilesInRange(ownerUnit, map.grid)
	playerController.EnterTargetingState(self)
	if !playerController.OnTileSelected.is_connected(OnTargetTileSelected):
		playerController.OnTileSelected.connect(OnTargetTileSelected)
	pass

func OnAbilityExecutionComplete():
	if playerController.OnCombatSequenceComplete.is_connected(OnAbilityExecutionComplete):
		playerController.OnCombatSequenceComplete.disconnect(OnAbilityExecutionComplete)

	ownerUnit.QueueEndTurn()

func OnTargetTileSelected(_tile : Tile):
	if playerController.OnTileSelected.is_connected(OnTargetTileSelected):
		playerController.OnTileSelected.disconnect(OnTargetTileSelected)

	selectedTileForExecution = _tile
	cachedTargets.clear()
	cachedTargets.append_array(TargetingData.GetAdditionalTileTargets(_tile))
	ExecuteAbility()
	pass

func CancelAbility():
	if playerController.OnTileSelected.is_connected(OnTargetTileSelected):
		playerController.OnTileSelected.disconnect(OnTargetTileSelected)
	cachedTargets.clear()

func GetRange():
	if TargetingData != null:
		return TargetingData.TargetRange
	return Vector2i(0, 0)

func IsWithinRange(_currentPosition : Vector2, _target : Vector2):
	if TargetingData == null:
		return false

	var dst = (_target - _currentPosition).length()
	return dst >= TargetingData.TargetRange.x && dst <= TargetingData.TargetRange.y
