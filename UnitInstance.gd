extends Node2D
class_name UnitInstance

@export var visualParent : Node2D
@export var abilityParent : Node2D
@export var itemsParent : Node2D

@onready var health_bar = %HealthBar
@onready var hp_val = %"HP Val"
@onready var health_bar_parent = %HealthBarParent

@onready var damage_indicator: Node2D = $DamageIndicator

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

var takeDamageTween : Tween

var maxHealth :
	get:
		return currentStats[GameManager.GameSettings.HealthStat]

var healthPerc :
	get:
		return currentHealth as float / maxHealth

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
	HideDamagePreview()
	damage_indicator.Initialize(self)

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
	pass

func ReturnToGridPosition(delta):
	# We should be off center now, move back towards your grid position
	var desired = GridPosition * map.TileSize
	position = lerp(position, (GridPosition * map.TileSize) as Vector2, Juice.combatSequenceReturnToOriginLerp * delta)
	if position.distance_squared_to(desired) < (Juice.combatSequenceReturnToOriginLerp * Juice.combatSequenceReturnToOriginLerp):
		position = desired


func InitializeStats():
	for stat in Template.BaseStats:
		currentStats[stat.Template] = stat.Value

	for derivedStatDef in GameManager.GameSettings.DerivedStatDefinitions:
		if currentStats.has(derivedStatDef.ParentStat):
			currentStats[derivedStatDef.Template] = floori(currentStats[derivedStatDef.ParentStat] * derivedStatDef.Ratio)

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

func TakeDamage(_context : SkillDamageData, _source, _instantaneous : bool = false):
	var damage = CalculateDamage(_context, _source)

	Juice.CreateDamagePopup(damage, CurrentTile)

	if !_instantaneous:
		ShowHealthBar(true)
		takeDamageTween = get_tree().create_tween()
		takeDamageTween.tween_method(UpdateHealthBarTween, currentHealth, currentHealth - damage, Juice.combatSequenceTickDuration)
		takeDamageTween.tween_callback(DamageTweenComplete.bind(damage))
	else:
		DamageTweenComplete(damage)
	pass

func DamageTweenComplete(_damage):
	currentHealth -= _damage
	health_bar.value = healthPerc
	CheckDeath()

func CalculateDamage(_context : SkillDamageData, _source):
	var damage
	var defensiveStatValue = _context.DoMod(currentStats[_context.DefensiveStat], _context.DefensiveMod, _context.DefensiveModType)

	var sourceAsUnit = _source as UnitInstance
	if sourceAsUnit != null:
		# If Source is not equal to null, then the damage will be based on that units agressive stat
		var agressiveStatValue = _context.DoMod(sourceAsUnit.currentStats[_context.AgressiveStat], _context.AgressiveMod, _context.AgressiveModType)
		damage =  GameManager.GameSettings.DamageCalculation(agressiveStatValue, defensiveStatValue)
	else:
		# If Source is null, then damage will be based on _context's FlatValue property, which is unaffected by modifiers
		damage = GameManager.GameSettings.DamageCalculation(_context.FlatValue, defensiveStatValue)
		pass
	return damage

func CheckDeath():
	if currentHealth <= 0:
		map.OnUnitDeath(self)

func UpdateHealthBarTween(value):
	hp_val.text = str("%02d/%02d" % [max(value, 0), maxHealth])
	health_bar.value = max(value as float, 0) / maxHealth as float
	pass

func ShowHealthBar(_visible : bool):
	health_bar_parent.visible = _visible
	if _visible:
		hp_val.text = str(currentHealth)
		health_bar.value = healthPerc

func QueueAttackSequence(_destination : Vector2, _context : AbilityContext, _unitsToTakeDamage : Array[UnitInstance]):
	var attackAction = UnitAttackAction.new()
	attackAction.TargetPosition = _destination
	attackAction.Context = _context
	attackAction.UnitsToTakeDamage = _unitsToTakeDamage
	ActionStack.append(attackAction)
	if CurrentAction == null:
		PopAction()

func QueueDefenseSequence(_damageSourcePosition : Vector2, _damageContext : SkillDamageData, _source : UnitInstance):
	var defendAction = UnitDefendAction.new()
	defendAction.SourcePosition = _damageSourcePosition
	defendAction.Context = _damageContext
	defendAction.Source = _source
	ActionStack.append(defendAction)
	if CurrentAction == null:
		PopAction()


func ShowDamagePreview(_source : UnitInstance, _damageData : SkillDamageData):
	damage_indicator.visible = true
	damage_indicator.PreviewDamage(_damageData, _source)
	pass

func HideDamagePreview():
	damage_indicator.visible = false
	damage_indicator.PreviewCanceled()
	pass
