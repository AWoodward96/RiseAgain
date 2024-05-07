extends Node2D
class_name UnitInstance

@export var visualParent : Node2D
@export var abilityParent : Node2D
@export var itemsParent : Node2D
@onready var health_bar = %HealthBar
@onready var hp_val = %"HP Val"
@onready var health_bar_parent = %HealthBarParent

var GridPosition : Vector2i
var CurrentTile : Tile
var Template : UnitTemplate
var UnitVisual : UnitVisual
var UnitAllegiance : GameSettings.TeamID
var Abilities : Array[AbilityInstance]

var MovementIndex : int
var MovementRoute : PackedVector2Array
var MovementVelocity : Vector2

var ActionStack : Array[UnitActionBase]
var CurrentAction : UnitActionBase
var TurnStartTile : Tile # The tile that this Unit Started their turn on

var currentStats = {}
var visual
var map : Map
var currentHealth

var maxHealth :
	get:
		return currentStats[GameManager.GameSettings.HealthStat]

var healthPerc :
	get:
		return currentHealth / maxHealth

var IsStackFree:
	get:
		return ActionStack.size() == 0 && CurrentAction == null


var AI # Only used by units initialized via a spawner

var Activated : bool :
	set(_value):
		if visual != null:
			visual.SetActivated(_value)

		Activated = _value

func _ready():
	ShowHealthBar(false)

func Initialize(_unitTemplate : UnitTemplate, _map: Map, _gridLocation : Vector2i, _allegiance : GameSettings.TeamID) :
	GridPosition = _gridLocation
	Template = _unitTemplate
	UnitAllegiance = _allegiance
	map = _map

	CreateVisual()
	CreateAbilities()
	InitializeStats()

	# has to be after CreateVisual
	Activated = true

func SetAI(_ai : AIBehaviorBase):
	AI = _ai

func CreateVisual():
	# we want a clean child, so remove anything that this might have used
	var children = visualParent.get_children()
	for n in children:
		remove_child(n)
		n.queue_free()

	visual = Template.VisualPrefab.instantiate()
	visualParent.add_child(visual)
	visual.Initialize(self)


func _physics_process(delta):
	if CurrentAction != null:
		if CurrentAction._Execute(self, delta):
			PopAction()
	#match AIState:
		#CharacterAIState.Moving:
			#pass
		#CharacterAIState.Attacking:
			#ReturnToGridPosition(delta)
		#CharacterAIState.Defending:
			#ReturnToGridPosition(delta)
	pass

func ReturnToGridPosition(delta):
	# We should be off center now, move back towards your grid position
	var desired = GridPosition * map.TileSize
	position = lerp(position, (GridPosition * map.TileSize) as Vector2, Juice.combatSequenceReturnToOriginLerp * delta)
	if position.distance_squared_to(desired) < (Juice.combatSequenceReturnToOriginLerp * Juice.combatSequenceReturnToOriginLerp):
		position = desired

func _process(_delta):
	if health_bar_parent.visible:
		health_bar.value = lerp(health_bar.value, currentHealth, Juice.HealthBarLerpSpeed)

func InitializeStats():
	for stat in Template.BaseStats:
		currentStats[stat.Template] = stat.Value

	for derivedStatDef in GameManager.GameSettings.DerivedStatDefinitions:
		if currentStats.has(derivedStatDef.ParentStat):
			currentStats[derivedStatDef.Template] = currentStats[derivedStatDef.ParentStat] * derivedStatDef.Ratio

	currentHealth = currentStats[GameManager.GameSettings.HealthStat]

func CreateAbilities():
	for ability in Template.Abilities:
		var abilityEntry = ability.instantiate() as AbilityInstance
		abilityEntry.Initialize(self, map)
		abilityParent.add_child(abilityEntry)
		Abilities.append(abilityEntry)


func MoveCharacterToNode(_route : PackedVector2Array, _tile : Tile) :
	if _route == null || _route.size() == 0:
		return

	var action = UnitMoveAction.new()
	action.Route = _route
	action.DestinationTile = _tile
	ActionStack.append(action)
	if CurrentAction == null:
		PopAction()

func StopCharacterMovement():
	if CurrentAction is UnitMoveAction:
		PopAction()

func PopAction():
	if CurrentAction != null:
		CurrentAction._Exit()

	CurrentAction = ActionStack.pop_front()
	if CurrentAction != null:
		CurrentAction._Enter(self, map)

func GetUnitMovement():
	return currentStats[GameManager.GameSettings.MovementStat]

func Activate():
	# Turns on this unit to let them take their turn
	Activated = true
	CurrentAction = null
	ActionStack.clear()

	# for 'canceling' movement
	TurnStartTile = CurrentTile

func QueueEndTurn():
	var endTurn = UnitEndTurnAction.new()
	ActionStack.append(endTurn)
	if CurrentAction == null:
		PopAction()

func EndTurn():
	Activated = false

func TakeDamage(_context : SkillDamageData, _source):
	var damage
	var defensiveStatValue = _context.DoMod(currentStats[_context.DefensiveStat], _context.DefensiveMod, _context.DefensiveModType)

	var sourceAsUnit = _source as UnitInstance
	if sourceAsUnit != null:
		# If Source is not equal to null, then the damage will be based on that units agressive stat
		var agressiveStatValue = _context.DoMod(sourceAsUnit.currentStats[_context.AgressiveStat], _context.AgressiveMod, _context.AgressiveModType)
		damage = DamageCalculation(agressiveStatValue, defensiveStatValue)
	else:
		# If Source is null, then damage will be based on _context's FlatValue property, which is unaffected by modifiers
		damage = DamageCalculation(_context.FlatValue, defensiveStatValue)
		pass

	currentHealth -= damage
	CheckDeath()
	pass

func CheckDeath():
	if currentHealth <= 0:
		map.OnUnitDeath(self)

func DamageCalculation(_atk, _def):
	return (_atk * 1.5) - _def

func ShowHealthBar(_visible : bool):
	health_bar_parent.visible = _visible
	if _visible:
		hp_val.text = str(currentHealth)
		health_bar.value = currentHealth / maxHealth

func QueueAttackSequence(_destination : Vector2):
	var attackAction = UnitAttackAction.new()
	attackAction.TargetPosition = _destination
	ActionStack.append(attackAction)
	if CurrentAction == null:
		PopAction()
func QueueDefenseSequence(_damageSourcePosition : Vector2):
	var defendAction = UnitDefendAction.new()
	defendAction.SourcePosition = _damageSourcePosition
	ActionStack.append(defendAction)
	if CurrentAction == null:
		PopAction()
