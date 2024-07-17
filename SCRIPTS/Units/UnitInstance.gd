extends Node2D
class_name UnitInstance

@export var visualParent : Node2D
@export var abilityParent : Node2D
@export var itemsParent : Node2D
@export var focusSlotPrefab : PackedScene

@onready var health_bar = %HealthBar
@onready var hp_val = %"HP Val"
@onready var health_bar_parent = %HealthBarParent

@onready var damage_indicator: Node2D = $DamageIndicator
@onready var defend_icon: Sprite2D = %DefendIcon
@onready var focus_bar_parent: EntryList = %FocusBarParent

var GridPosition : Vector2i
var CurrentTile : Tile
var Template : UnitTemplate
var visual : UnitVisual # could be made generic, but probably not for now
var UnitAllegiance : GameSettingsTemplate.TeamID
var Inventory : Array[Item]
var Abilities : Array[Ability]
var EquippedItem : Item

var IsDefending : bool = false :
	set(value):
		if defend_icon != null:
			defend_icon.visible = value
		IsDefending = value

var MovementIndex : int
var MovementRoute : PackedVector2Array
var MovementVelocity : Vector2

var ActionStack : Array[UnitActionBase]
var CurrentAction : UnitActionBase
var TurnStartTile : Tile # The tile that this Unit Started their turn on

var baseStats = {}			#Stats determined by the template object and out-of-run-progression
var statModifiers = {}		#Stats determined by in-run progression. These are NOT temporary, and shouldn't be removed
var temporaryStats = {}		#Stats determined by buffs, debuffs, or other TEMPORARY changes on the battlefield. This gets cleared at the end of a map!

var facingDirection : int

var DisplayLevel : int :
	get: return Level + 1
var Level : int
var Exp : int

var map : Map
var currentHealth
var currentFocus

var takeDamageTween : Tween

var maxHealth :
	get:
		return GetWorkingStat(GameManager.GameSettings.HealthStat) as float

var healthPerc :
	get:
		return currentHealth as float / maxHealth

var IsStackFree:
	get:
		return ActionStack.size() == 0 && CurrentAction == null


var AI # Only used by units initialized via a spawner
var AggroType # Only used by units initialized via a spawner
var IsAggrod : bool = false

var Activated : bool :
	set(_value):
		if visual != null:
			visual.SetActivated(_value)

		Activated = _value

func _ready():
	ShowHealthBar(false)
	HideDamagePreview()
	damage_indicator.Initialize(self)
	defend_icon.visible = false

func Initialize(_unitTemplate : UnitTemplate, _levelOverride : int = 0) :
	Template = _unitTemplate

	CreateItems()
	CreateAbilities()
	InitializeLevels(_levelOverride)
	InitializeStats()
	UpdateDerivedStats()

func InitializeStats():
	for stat in Template.BaseStats:
		if baseStats.has(stat.Template):
			baseStats[stat.Template] += stat.Value
		else:
			baseStats[stat.Template] = stat.Value

	UpdateDerivedStats()

	# Remember: Vitality != Health. Health = Vitality * ~1.5, a value which can change for balancing
	currentHealth = GetWorkingStat(GameManager.GameSettings.HealthStat)


	if GameManager.GameSettings.InitializeUnitsWithMaxFocus:
		currentFocus = GetWorkingStat(GameManager.GameSettings.MindStat)
	else:
		currentFocus = 0


func UpdateDerivedStats():
	for derivedStatDef in GameManager.GameSettings.DerivedStatDefinitions:
		baseStats[derivedStatDef.Template] = floori(GetWorkingStat(derivedStatDef.ParentStat) * derivedStatDef.Ratio)

func InitializeLevels(_level : int):
	if _level == 0:
		# No additional stats are being granted - just go next
		return

	# When we're initializing units with a preset level, their stat growths become averages instead of rng based
	# This is typically only used by Enemies anyway so you shouldn't see this, but it can be used if a Unit mid-run gets added to the team and shouldn't start at level 1
	for statDef in Template.StatGrowths:
		var growthPerc = statDef.Value / 100.0
		if baseStats.has(statDef.Template):
			baseStats[statDef.Template] += floori(growthPerc * _level)
		else:
			baseStats[statDef.Template] = floori(growthPerc * _level)
	Level = _level
	pass

func AddToMap(_map : Map, _gridLocation : Vector2i, _allegiance: GameSettingsTemplate.TeamID):
	GridPosition = _gridLocation
	map = _map
	UnitAllegiance = _allegiance

	facingDirection = GameSettingsTemplate.CastDirectionEnumToInt(GameSettingsTemplate.Direction.Down)

	var parent = get_parent()
	if parent != null:
		parent.remove_child(self)
	map.squadParent.add_child(self)

	for i in Inventory:
		i.SetMap(map)

	CreateVisual()

	# has to be after CreateVisual
	Activated = true

func OnMapComplete():
	ShowHealthBar(false)
	IsDefending = false
	temporaryStats.clear()

func SetAI(_ai : AIBehaviorBase, _aggro : AlwaysAggro):
	AI = _ai
	IsAggrod = false

	if _aggro == null:
		AggroType = AlwaysAggro.new()
	else:
		AggroType = _aggro

func CreateVisual():
	# we want a clean child, so remove anything that this might have used
	var children = visualParent.get_children()
	for n in children:
		var parent = n.get_parent()
		if parent != null:
			parent.remove_child(n)
		n.queue_free()

	visual = Template.VisualPrefab.instantiate() as UnitVisual
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

func AddExperience(_expIncrease : int):
	Exp += _expIncrease
	var levelIncrease = 0
	while Exp >= 100:
		levelIncrease += 1
		Exp -= 100

	return levelIncrease


func PerformLevelUp(_rng : RandomNumberGenerator, _levelIncrease = 1):
	print("Level Up!")
	Level += _levelIncrease
	var levelUpResult = {}
	for i in _levelIncrease:
		for growth in Template.StatGrowths:
			var workingValue = growth.Value
			var statIncrease = 0

			# growths over 100 should be counted as garunteed stat growths
			while workingValue >= 100:
				statIncrease += 1
				workingValue -= 100

			# Roll RNG
			var result = _rng.randi_range(0,100)
			if result <= workingValue:
				statIncrease += 1

			print("StatCheck: ", result, " <= ", workingValue, " resulted in a stat increase: ", statIncrease)

			levelUpResult[growth.Template] = statIncrease
			baseStats[growth.Template] += statIncrease
	UpdateDerivedStats()
	return levelUpResult

func CreateItems():
	# TODO: Figure out how to initialize from save data, so that Item information persists between levels
	for item in Template.StartingItems:
		GiveItem(item)

	if Inventory.size() > 0:
		EquipItem(Inventory[0])

func CreateAbilities():
	for ability in Template.Abilities:
		var abilityInstance = ability.instantiate() as Ability
		abilityInstance.Initialize(self, map)
		abilityParent.add_child(abilityInstance)
		Abilities.append(abilityInstance)

func EquipItem(_item : Item):
	var index = Inventory.find(_item)
	if index != -1:
		EquippedItem = _item

		# move up the equipped weapon to slot 0 of the inventory
		var invAt0 = Inventory[0]
		Inventory[0] = _item
		Inventory[index] = invAt0

func TrashItem(_item : Item):
	var index = Inventory.find(_item)
	if index != -1:
		itemsParent.remove_child(_item)
		Inventory.remove_at(index)

func GiveItem(_item : PackedScene):
	var itemInstance = _item.instantiate() as Item
	itemInstance.Initialize(self, map)
	itemsParent.add_child(itemInstance)
	Inventory.append(itemInstance)

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
	return baseStats[GameManager.GameSettings.MovementStat]

func Activate(_currentTurn : GameSettingsTemplate.TeamID):
	# Turns on this unit to let them take their turn
	Activated = true
	CurrentAction = null
	ActionStack.clear()

	# defending doesn't drop off until it's your turn again
	if _currentTurn == UnitAllegiance:
		IsDefending = false

	# for 'canceling' movement
	TurnStartTile = CurrentTile

func Defend():
	IsDefending = true

func QueueEndTurn():
	var endTurn = UnitEndTurnAction.new()
	ActionStack.append(endTurn)
	if CurrentAction == null:
		PopAction()

func QueueExpGain(_expGain : int):
	var expGain = UnitExpGainAction.new()
	expGain.ExpGained = _expGain
	ActionStack.append(expGain)
	if CurrentAction == null:
		PopAction()

func EndTurn():
	ShowHealthBar(false)
	Activated = false

func QueueTurnStartDelay():
	var delay = UnitDelayAction.new()
	ActionStack.append(delay)
	if CurrentAction == null:
		PopAction()

func DoHeal(_result : ActionResult):
	ModifyHealth(_result.HealthDelta)

func DoCombat(_result : ActionResult, _instantaneous : bool = false):
	if _result.Miss:
		Juice.CreateMissPopup(CurrentTile)
	else:
		ModifyHealth(_result.HealthDelta, _instantaneous)

func ModifyHealth(_netHealthChange, _instantaneous : bool = false):
	if _netHealthChange < 0:
		Juice.CreateDamagePopup(_netHealthChange, CurrentTile)
	else:
		Juice.CreateHealPopup(_netHealthChange, CurrentTile)

	if !_instantaneous:
		ShowHealthBar(true)
		takeDamageTween = get_tree().create_tween()
		takeDamageTween.tween_method(UpdateHealthBarTween, currentHealth, currentHealth + _netHealthChange, Juice.combatSequenceTickDuration)
		takeDamageTween.tween_callback(OnModifyHealthTweenComplete.bind(_netHealthChange))
	else:
		OnModifyHealthTweenComplete(_netHealthChange)
	pass

func ModifyFocus(_netFocusChange):
	currentFocus += _netFocusChange
	currentFocus = clamp(currentFocus, 0, GetWorkingStat(GameManager.GameSettings.MindStat))
	UpdateFocusUI()

func OnModifyHealthTweenComplete(_healthNetChange):
	currentHealth += _healthNetChange
	currentHealth = clamp(currentHealth, 0, maxHealth)
	health_bar.value = healthPerc

	# For AI enemies, check if this damage would aggro them
	if _healthNetChange < 0 && AggroType is AggroOnDamage:
		IsAggrod = true

	CheckDeath()

# DamageData is not typed so that it can be eiter the DamageData or the DamageDataResourceWrapper
func CalculateDamage(_damageData, _source):
	var damage = _damageData.FlatValue
	var defense = GetWorkingStat(_damageData.DefensiveStat)
	var defensiveStatValue = _damageData.DoMod(defense, _damageData.DefensiveMod, _damageData.DefensiveModType)

	var sourceAsUnit = _source as UnitInstance
	if sourceAsUnit != null:
		# If Source is not equal to null, then the damage will be based on that units agressive stat
		var attack = sourceAsUnit.GetWorkingStat(_damageData.AgressiveStat)
		var agressiveStatValue = _damageData.DoMod(attack, _damageData.AgressiveMod, _damageData.AgressiveModType)

		damage += GameManager.GameSettings.DamageCalculation(agressiveStatValue, defensiveStatValue)
	else:
		# If Source is null, then damage will be based on _damageData's FlatValue property, which is unaffected by modifiers
		damage += GameManager.GameSettings.DamageCalculation(_damageData.FlatValue, defensiveStatValue)
		pass
	return damage

func CalculateHeal(_healData : HealComponent, _source):
	var healAmount = _healData.FlatValue
	if _healData.ScalingStat != null && _source != null:
		healAmount += _healData.DoMod(_source.GetWorkingStat(_healData.ScalingStat))
	healAmount = floori(healAmount)
	return healAmount

### The function you want to call when you want to know the Final state that the Unit is working with
func GetWorkingStat(_statTemplate : StatTemplate):
	# start with the base
	var current = 0
	if baseStats.has(_statTemplate):
		current = baseStats[_statTemplate]

	if statModifiers.has(_statTemplate):
		current += statModifiers[_statTemplate]

	if temporaryStats.has(_statTemplate):
		current += temporaryStats[_statTemplate]

	if EquippedItem != null && EquippedItem.StatData != null:
		for statDef in EquippedItem.StatData.GrantedStats:
			if statDef.Template == _statTemplate:
				current += statDef.Value

	return current

func ApplyStatModifier(_statDef : StatDef):
	if statModifiers.has(_statDef.Template) && !(_statDef is DerivedStatDef):
		statModifiers[_statDef.Template] += _statDef.Value
	else:
		statModifiers[_statDef.Template] = _statDef.Value
	UpdateDerivedStats()

func CheckDeath():
	if currentHealth <= 0:
		map.OnUnitDeath(self)

func UpdateHealthBarTween(value):
	hp_val.text = str("%02d/%02d" % [clamp(value, 0, maxHealth), maxHealth])
	health_bar.value = clampf(value, 0, maxHealth) / maxHealth as float
	pass

func ShowHealthBar(_visible : bool):
	health_bar_parent.visible = _visible
	if _visible:
		hp_val.text = str(currentHealth)
		health_bar.value = healthPerc

func QueueAttackSequence(_destination : Vector2, _log : ActionLog):
	var attackAction = UnitAttackAction.new()
	attackAction.TargetPosition = _destination
	attackAction.Log = _log
	ActionStack.append(attackAction)
	if CurrentAction == null:
		PopAction()

func QueueDefenseSequence(_damageSourcePosition : Vector2, _result : ActionResult):
	var defendAction = UnitDefendAction.new()
	defendAction.SourcePosition = _damageSourcePosition
	defendAction.Result = _result
	ActionStack.append(defendAction)
	if CurrentAction == null:
		PopAction()

func QueueHealAction(_log : ActionLog):
	var healAction = UnitHealAction.new()
	healAction.Log = _log
	ActionStack.append(healAction)
	if CurrentAction == null:
		PopAction()
	pass

func QueueDelayedCombatAction(_log : ActionLog):
	var combatAction = UnitDelayedCombatAction.new()
	combatAction.Log = _log
	ActionStack.append(combatAction)
	if CurrentAction == null:
		PopAction()

func ShowDamagePreview(_source : UnitInstance, _damageData : DamageData, _targetedTileData : TileTargetedData):
	damage_indicator.visible = true
	damage_indicator.PreviewDamage(_damageData, _source, _targetedTileData)
	pass

func ShowHealPreview(_source : UnitInstance, _healData : HealComponent, _targetedTileData : TileTargetedData):
	damage_indicator.visible = true
	damage_indicator.PreviewHeal(_healData, _source, _targetedTileData)

func HideDamagePreview():
	damage_indicator.visible = false
	damage_indicator.PreviewCanceled()
	pass

func GetEffectiveAttackRange():
	if Inventory.size() == 0:
		return Vector2i(0,0)

	# Default range should start at 1 1 and go up from there
	var range = Vector2i(1, 1)
	for item in Inventory:
		if item == null:
			continue

		var itemRange = item.GetRange()
		if itemRange != Vector2i(0,0):
			if range.y < itemRange.y:
				range.y = itemRange.y

	return range

func HasDamageItem():
	for i in Inventory:
		if i.IsDamage():
			return true
	return false

func HasHealItem(_includingConsumables : bool):
	for i in Inventory:
		if i.IsHeal(_includingConsumables):
			return true
	return false

func UpdateFocusUI():
	focus_bar_parent.ClearEntries()
	var maxFocus = GetWorkingStat(GameManager.GameSettings.MindStat)
	for fIndex in maxFocus:
		var entry = focus_bar_parent.CreateEntry(focusSlotPrefab)
		entry.Toggle(currentFocus >= (fIndex + 1)) # +1 because it's an index

func ToJSON():
	var inventoryJSON = []
	for item in Inventory:
		inventoryJSON.append(item.ToJSON())

	return {
		"Template" : Template.resource_path,
		"currentHealth" : currentHealth,
		"GridPosition_x" : GridPosition.x,
		"GridPosition_y" : GridPosition.y,
		"IsAggrod" : IsAggrod,
		"Inventory" : inventoryJSON
	}
