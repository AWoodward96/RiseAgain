extends Node2D
class_name UnitInstance

enum CharacterAIState { Idle, Moving, Attacking, Defending }

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

var AIState : CharacterAIState
var TurnStartTile : Tile # The tile that this Unit Started their turn on

var map : Map
var currentHealth
var maxHealth :
	get:
		return currentStats[GameManager.GameSettings.HealthStat]

var healthPerc :
	get:
		return currentHealth / maxHealth

var currentStats = {}
var visual

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
	match AIState:
		CharacterAIState.Moving:
			var speed = GameManager.GameSettings.CharacterTileMovemementSpeed
			var destination = MovementRoute[MovementIndex]
			var distance = position.distance_squared_to(destination)
			MovementVelocity = (destination - position).normalized() * speed
			position += MovementVelocity * delta
			var maximumDistanceTraveled = speed * delta;

			if distance < (maximumDistanceTraveled * maximumDistanceTraveled) :
				#AudioFootstep.play()
				MovementIndex += 1
				if MovementIndex >= MovementRoute.size() :
					position = MovementRoute[MovementIndex - 1]
					AIState = CharacterAIState.Idle
		CharacterAIState.Attacking:
			ReturnToGridPosition(delta)
		CharacterAIState.Defending:
			ReturnToGridPosition(delta)

func ReturnToGridPosition(delta):
	# We should be off center now, move back towards your grid position
		var desired = GridPosition * map.TileSize
		position = lerp(position, (GridPosition * map.TileSize) as Vector2, Juice.combatSequenceReturnToOriginLerp * delta)
		if position.distance_squared_to(desired) < (Juice.combatSequenceReturnToOriginLerp * Juice.combatSequenceReturnToOriginLerp):
			position = desired
			AIState = CharacterAIState.Idle

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
		var abilityEntry = ability.instantiate()
		abilityParent.add_child(abilityEntry)
		Abilities.append(abilityEntry)


func MoveCharacterToNode(_route : PackedVector2Array, _tile : Tile) :
	if _route == null || _route.size() == 0:
		return
	AIState = CharacterAIState.Moving
	MovementRoute = _route
	map.grid.SetUnitGridPosition(self, _tile.Position, false)
	MovementIndex = 0

func StopCharacterMovement():
	AIState = CharacterAIState.Idle

func GetUnitMovement():
	return currentStats[GameManager.GameSettings.MovementStat]

func Activate():
	# Turns on this unit to let them take their turn
	Activated = true

	# for 'canceling' movement
	TurnStartTile = CurrentTile

func EndTurn():
	Activated = false

func TakeDamage(_context : DamageContext, _source):
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

func PlayAttackSequence(_destination : Vector2):
	AIState = CharacterAIState.Attacking
	var dst = (_destination - position).normalized()
	dst = dst * (Juice.combatSequenceAttackOffset * map.TileSize)
	position += dst

func PlayDefenseSequence(_damageSourcePosition : Vector2):
	AIState = CharacterAIState.Defending
	var dst = (position - _damageSourcePosition).normalized()
	dst = dst * (Juice.combatSequenceDefenseOffset * map.TileSize)
	position += dst
