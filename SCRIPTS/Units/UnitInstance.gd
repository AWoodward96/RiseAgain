extends Node2D
class_name UnitInstance

signal OnStatUpdated
signal OnCombatEffectsUpdated

@export var visualParent : Node2D
@export var abilityParent : Node2D
@export var combatEffectsParent : Node2D
@export var itemsParent : Node2D
@export var healthBar : UnitHealthBar
@export var focusSlotPrefab : PackedScene
@export var affinityIcon: Sprite2D

@onready var health_bar : ProgressBar = %HealthBar
@onready var hp_val = %"HP Val"
@onready var health_bar_parent = %HealthBarParent
@onready var armor_bar: ProgressBar = %ArmorBar

@onready var damage_indicator: DamageIndicator = $DamageIndicator
@onready var defend_icon: Sprite2D = %DefendIcon
@onready var focus_bar_parent: EntryList = %FocusBarParent
@onready var positive_afffinity: Sprite2D = %PositiveAfffinity
@onready var negative_affinity: Sprite2D = %NegativeAffinity

var GridPosition : Vector2i
var CurrentTile : Tile
var Template : UnitTemplate
var visual : UnitVisual # could be made generic, but probably not for now
var UnitAllegiance : GameSettingsTemplate.TeamID = GameSettingsTemplate.TeamID.ALLY
var ItemSlots : Array[Item]
var Abilities : Array[Ability]
var CombatEffects : Array[CombatEffectInstance]
var EquippedWeapon : Ability

var IsDefending : bool = false :
	set(value):
		if defend_icon != null:
			defend_icon.visible = value
		IsDefending = value

var IsFlying : bool :
	get:
		return Template.Descriptors.has(GameManager.GameSettings.FlyingDescriptor)

var MovementIndex : int
var MovementRoute : PackedVector2Array
var MovementVelocity : Vector2

var ActionStack : Array[UnitActionBase]
var CurrentAction : UnitActionBase
var TurnStartTile : Tile # The tile that this Unit Started their turn on

var baseStats = {}			#Stats determined by the template object and out-of-run-progression
var statModifiers = {}		#Stats determined by in-run progression. These are NOT temporary, and shouldn't be removed

var facingDirection : GameSettingsTemplate.Direction

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
	healthBar.SetUnit(self)
	HideDamagePreview()
	defend_icon.visible = false

	damage_indicator.scale = Vector2i(Template.GridSize, Template.GridSize)
	health_bar_parent.scale = Vector2i(Template.GridSize, Template.GridSize)

	name = "{0}_{1}_{2}".format({"0" : str(UnitAllegiance), "1" : Template.DebugName, "2" : str(randi() % 100000)})

func Initialize(_unitTemplate : UnitTemplate, _levelOverride : int = 0) :
	Template = _unitTemplate

	RefreshVisuals()

	if ItemSlots.size() == 0:
		for s in GameManager.GameSettings.ItemSlotsPerUnit:
			ItemSlots.append(null)

	CreateStartingAbilities()
	InitializeLevels(_levelOverride)
	InitializeStats()
	UpdateDerivedStats()
	InitializeTier0Abilities()

func RefreshVisuals():
	if Template.Affinity != null:
		affinityIcon.texture = Template.Affinity.loc_icon

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

func InitializeTier0Abilities():
	if Template == null:
		return

	for abilityPath in Template.Tier0Abilities:
		AddAbility(load(abilityPath))

func AddCombatEffect(_combatEffectInstance : CombatEffectInstance):
	CombatEffects.append(_combatEffectInstance)
	combatEffectsParent.add_child(_combatEffectInstance)
	UpdateCombatEffects()
	RefreshHealthBarVisuals()
	if _combatEffectInstance.Template.show_popup:
		Juice.CreateEffectPopup(CurrentTile, _combatEffectInstance)

func TriggerTurnStartEffects():
	for c in CombatEffects:
		if c.IsExpired():
			continue

		c.OnTurnStart()
		if c.TurnsRemaining != -1:
			c.TurnsRemaining -= 1

func UpdateCombatEffects():
	var slatedForRemoval : Array[CombatEffectInstance]
	for c in CombatEffects:
		if c.IsExpired():
			slatedForRemoval.append(c)

	OnCombatEffectsUpdated.emit()

	for remove in slatedForRemoval:
		CombatEffects.remove_at(CombatEffects.find(remove))
		combatEffectsParent.remove_child(remove)
		remove.queue_free()

func AddToMap(_map : Map, _gridLocation : Vector2i, _allegiance: GameSettingsTemplate.TeamID):
	GridPosition = _gridLocation
	map = _map
	UnitAllegiance = _allegiance

	facingDirection = GameSettingsTemplate.Direction.Down

	var parent = get_parent()
	if parent != null:
		parent.remove_child(self)
	map.squadParent.add_child(self)

	for i in ItemSlots:
		if i == null:
			continue

		i.SetMap(map)

	for a in Abilities:
		a.SetMap(map)

	CreateVisual()

	# has to be after CreateVisual
	#Activated = true

func OnMapComplete():
	ShowHealthBar(false)
	IsDefending = false

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

func PerformLevelUp(_rng : DeterministicRNG, _levelIncrease = 1):
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
			var result = _rng.NextInt(0,100)
			if result <= workingValue:
				statIncrease += 1

			print("StatCheck: ", result, " <= ", workingValue, " resulted in a stat increase: ", statIncrease)

			levelUpResult[growth.Template] = statIncrease
			baseStats[growth.Template] += statIncrease
	UpdateDerivedStats()
	OnStatUpdated.emit()
	return levelUpResult


func CreateStartingAbilities():
	if Template.StartingEquippedWeapon != null:
		AddAbility(Template.StartingEquippedWeapon)

	if Template.StartingTactical != null:
		AddAbility(Template.StartingTactical)


func AddAbility(_ability : PackedScene):
	# We don't validate if the ability is on the template at all because maybe there might be an item that grants a
	# general use ability to any unit
	var abilityInstance = _ability.instantiate() as Ability
	if abilityInstance == null:
		return

	# don't allow for duplicates
	for abl in Abilities:
		if abl == _ability:
			return

	abilityInstance.Initialize(self)

	if abilityInstance.type == Ability.AbilityType.Weapon:
		# Loop through the existing abilities - anything that's equippable needs to be deleted for this to be added
		for abl in Abilities:
			if abl.type == Ability.AbilityType.Weapon:
				abilityParent.remove_child(abl)
				abl.queue_free()

		EquippedWeapon = abilityInstance

	abilityParent.add_child(abilityInstance)
	Abilities.append(abilityInstance)
	return abilityInstance

# Equips an item to that slot
# Returns true or false depending on if the item was properly equipped
func EquipItem(_slotIndex : int, _itemPrefabOrInstance):
	if ItemSlots.size() == 0:
		for s in GameManager.GameSettings.ItemSlotsPerUnit:
			ItemSlots.append(null)

	if _slotIndex < 0 || _slotIndex >= ItemSlots.size():
		return false

	# _Item can be a packed Scene or an Item itself
	var item : Item
	if _itemPrefabOrInstance is PackedScene:
		item = _itemPrefabOrInstance.instantiate() as Item
	elif _itemPrefabOrInstance is Item:
		item = _itemPrefabOrInstance
	else:
		# If it's null then we're unequipping something from this slot
		pass

	if ItemSlots[_slotIndex] == null:
		if item != null:
			var parent = item.get_parent()
			if parent != null:
				parent.remove_child(item)
			itemsParent.add_child(item)
		ItemSlots[_slotIndex] = item
		UpdateDerivedStats()
		OnStatUpdated.emit()
		return true
	else:
		itemsParent.remove_child(ItemSlots[_slotIndex])
		ItemSlots[_slotIndex] = item
		UpdateDerivedStats()
		OnStatUpdated.emit()
		return true


func MoveCharacterToNode(_route : Array[Tile], _tile : Tile, _speedOverride : int = -1) :
	if _route == null || _route.size() == 0:
		return

	var action = UnitMoveAction.new()
	action.Route = _route
	action.DestinationTile = _tile
	action.SpeedOverride = _speedOverride
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

	# If it's your units turn
	if _currentTurn == UnitAllegiance:
		# defending doesn't drop off until it's your turn again
		IsDefending = false

		TriggerTurnStartEffects()
		UpdateCombatEffects()

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
	var blockTurnEnd = false
	for e in CombatEffects:
		if e is EnergizedEffectInstance:
			e.TurnsRemaining -= 1
			blockTurnEnd = true
			Juice.CreateEffectPopup(CurrentTile, e)
			break

	ShowHealthBar(false)
	Activated = false
	if blockTurnEnd:
		Activate(map.currentTurn)
	else:
		map.OnUnitTurnEnd.emit(self)

func QueueTurnStartDelay():
	var delay = UnitDelayAction.new()
	ActionStack.append(delay)
	if CurrentAction == null:
		PopAction()

func DoHeal(_result : HealStepResult):
	ModifyHealth(_result.HealthDelta, _result)
	pass

func DoCombat(_result : DamageStepResult, _instantaneous : bool = false):
	if _result.Miss:
		Juice.CreateMissPopup(CurrentTile)
	else:
		ModifyHealth(_result.HealthDelta, _result, _instantaneous)

func ModifyHealth(_netHealthChange, _result : DamageStepResult, _instantaneous : bool = false):
	if _netHealthChange < 0:
		# If this is a damage based change - armor should reduce the amount of damage taken
		# Since healthChange would be negative here, healthChange
		var armor = GetArmorAmount()
		Juice.CreateDamagePopup(min(_netHealthChange + armor, 0), CurrentTile)
	else:
		Juice.CreateHealPopup(_netHealthChange, CurrentTile)

	if !_instantaneous:
		ShowHealthBar(true)
		healthBar.ModifyHealthOverTime(_netHealthChange)

		# NOTE:
		# If you have two back to back health bar changes - only the first one is going to go through to OnModifyHealthTweenComplete
		# You'll need to wait for one to be finished before the other one starts
		if !healthBar.HealthBarTweenCallback.is_connected(OnModifyHealthTweenComplete):
			healthBar.HealthBarTweenCallback.connect(OnModifyHealthTweenComplete.bind(_netHealthChange, _result))

	else:
		OnModifyHealthTweenComplete(_netHealthChange, _result)
	pass

func UpdateHealthBarTween(value):
	hp_val.text = str("%02d/%02d" % [clamp(value, 0, maxHealth), maxHealth])
	health_bar.value = clampf(value, 0, maxHealth) / maxHealth as float
	pass

func ModifyFocus(_netFocusChange):
	currentFocus += _netFocusChange
	currentFocus = clamp(currentFocus, 0, GetWorkingStat(GameManager.GameSettings.MindStat))

	healthBar.UpdateFocusUI()
	OnStatUpdated.emit()

func OnModifyHealthTweenComplete(_delta, _result : ActionStepResult):
	# you have to disconnect this because the nethealth change is a bound variable
	if healthBar.HealthBarTweenCallback.is_connected(OnModifyHealthTweenComplete):
		healthBar.HealthBarTweenCallback.disconnect(OnModifyHealthTweenComplete)

	var remainingDelta = _delta
	var armor = GetArmorAmount()
	if _delta < 0 && armor > 0:
		var armorDamage = clamp(_delta, -armor, 0)
		DealDamageToArmor(armorDamage)
		remainingDelta -= armorDamage

	currentHealth = clampi(currentHealth + remainingDelta, 0, maxHealth)
	RefreshHealthBarVisuals()

	# For AI enemies, check if this damage would aggro them
	if _delta < 0 && AggroType is AggroOnDamage:
		IsAggrod = true

	CheckDeath(_result)

func DealDamageToArmor(_damage : int):
	# Damage dealt to armor should always be signed - and therefore should always be negative
	if _damage >= 0:
		return

	var remainingDamage = _damage
	for effects in CombatEffects:
		if effects is ArmorEffectInstance:
			var delta = clamp(remainingDamage, -effects.ArmorValue, 0)
			effects.ArmorValue += delta
			remainingDamage -= delta # double negatives here

	UpdateCombatEffects()
	pass

func RefreshHealthBarVisuals():
	healthBar.Refresh()

func GetArmorAmount():
	var armor = 0
	for effects in CombatEffects:
		if effects is ArmorEffectInstance:
			armor += effects.ArmorValue

	return armor

### The function you want to call when you want to know the Final state that the Unit is working with
func GetWorkingStat(_statTemplate : StatTemplate):
	# start with the base
	var current = 0
	if baseStats.has(_statTemplate):
		current = baseStats[_statTemplate]

	if statModifiers.has(_statTemplate):
		current += statModifiers[_statTemplate]


	if EquippedWeapon != null && EquippedWeapon.StatData != null:
		for statDef in EquippedWeapon.StatData.GrantedStats:
			if statDef.Template == _statTemplate:
				current += statDef.Value

	for item in ItemSlots:
		if item != null:
			current += item.GetStatDelta(_statTemplate)

	for effect in CombatEffects:
		if effect is StatChangeEffectInstance:
			var statChange = (effect as StatChangeEffectInstance).GetEffect() as StatBuff
			if statChange != null && statChange.Stat == _statTemplate:
				current += statChange.Value

	return current

func ApplyStatModifier(_statDef : StatDef):
	if statModifiers.has(_statDef.Template) && !(_statDef is DerivedStatDef):
		statModifiers[_statDef.Template] += _statDef.Value
	else:
		statModifiers[_statDef.Template] = _statDef.Value
	UpdateDerivedStats()
	OnStatUpdated.emit()

func CheckDeath(_context : DamageStepResult):
	if currentHealth <= 0:
		map.OnUnitDeath(self, _context)

func CheckKillbox():
	if CurrentTile.ActiveKillbox && !IsFlying:
		# The unit's fucking dead - kill them
		ModifyHealth(-currentHealth, null, true)
		pass

func ShowHealthBar(_visible : bool):
	health_bar_parent.visible = _visible
	if _visible:
		hp_val.text = str(currentHealth)
		health_bar.value = healthPerc

func QueueAttackSequence(_destination : Vector2, _log : ActionLog):
	var attackAction = UnitAttackAction.new()
	attackAction.TargetPosition = _destination

	# You have to pass the action index when the queue is added because the actionstack index is going to change as the action is executed.
	# This locks in which action is doing what and when
	attackAction.ActionIndex = _log.actionStackIndex
	attackAction.Log = _log

	ActionStack.append(attackAction)
	if CurrentAction == null:
		PopAction()

func QueueDefenseSequence(_damageSourcePosition : Vector2, _result : DamageStepResult):
	var defendAction = UnitDefendAction.new()
	defendAction.SourcePosition = _damageSourcePosition
	defendAction.Result = _result
	ActionStack.append(defendAction)
	if CurrentAction == null:
		PopAction()

func QueueHealAction(_log : ActionLog):
	var healAction = UnitHealAction.new()
	healAction.Log = _log
	# You have to pass the action index when the queue is added because the actionstack index is going to change as the action is executed.
	# This locks in which action is doing what and when
	healAction.ActionIndex = _log.actionStackIndex
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

func ShowHealPreview(_source : UnitInstance, _usable : UnitUsable, _targetedTileData : TileTargetedData):
	damage_indicator.visible = true
	damage_indicator.PreviewHeal(_usable, _source, self, _targetedTileData)

func HideDamagePreview():
	damage_indicator.visible = false
	damage_indicator.PreviewCanceled()
	pass

func GetEffectiveAttackRange():
	if EquippedWeapon != null:
		return EquippedWeapon.GetRange()
	return Vector2i.ZERO

func HasDamageAbility():
	for i in Abilities:
		if i.IsDamage():
			return true
	return false

func HasHealAbility():
	for i in Abilities:
		if i.IsHeal():
			return true
	return false

func UpdateFocusUI():
	focus_bar_parent.ClearEntries()
	var maxFocus = GetWorkingStat(GameManager.GameSettings.MindStat)
	for fIndex in maxFocus:
		var entry = focus_bar_parent.CreateEntry(focusSlotPrefab)
		entry.Toggle(currentFocus >= (fIndex + 1)) # +1 because it's an index

func ShowAffinityRelation(_affinity : AffinityTemplate):
	if _affinity == null:
		positive_afffinity.visible = false
		negative_affinity.visible = false
		return

	# Chat, I love bitwise ops
	if _affinity.strongAgainst & Template.Affinity.affinity:
		negative_affinity.visible = true

	if Template.Affinity.strongAgainst & _affinity.affinity:
		positive_afffinity.visible = true

# Checks all the item slots and sees if the unit has any item equipped
func HasAnyItem():
	for i in ItemSlots:
		if i != null:
			return true
	return false

func Rest():
	for ability in Abilities:
		ability.OnRest()

	currentHealth = maxHealth

func PreviewModifiedTile(_tile : Tile):
	if _tile != null:
		position = _tile.GlobalPosition

func ResetVisualToTile():
	position = CurrentTile.GlobalPosition

func ToJSON():
	var dict = {
		"Template" : Template.resource_path,
		"currentHealth" : currentHealth,
		"currentFocus" : currentFocus,
		"Level" : Level,
		"Exp" : Exp,
		"GridPosition" : GridPosition,
		"IsAggrod" : IsAggrod,
		"UnitAllegience" : UnitAllegiance,
		"Activated" : Activated,
		"Abilities" : PersistDataManager.ArrayToJSON(Abilities),
		"ItemSlots" : PersistDataManager.ArrayToJSON(ItemSlots)
	}

	if AI != null:
		dict["AI"] = AI.resource_path
		dict["AggroType"] = AggroType.resource_path

	# get base stats
	var baseStatsStorage : Dictionary
	for b in baseStats:
		baseStatsStorage[b.resource_path] = baseStats[b]
	dict["baseStats"] = baseStatsStorage

	var modifierStatStorage : Dictionary
	for b in statModifiers:
		modifierStatStorage[b.resource_path] = statModifiers[b]
	dict["statModifiers"] = modifierStatStorage


	return dict

static func FromJSON(_dict : Dictionary):
	var unitInstance = GameManager.UnitSettings.UnitInstancePrefab.instantiate() as UnitInstance
	unitInstance.Template = load(_dict["Template"]) as UnitTemplate
	unitInstance.Level = _dict["Level"]
	unitInstance.Exp = _dict["Exp"]
	unitInstance.UnitAllegiance = _dict["UnitAllegience"]

	if _dict.has("AI"):
		unitInstance.AI = load(_dict["AI"]) as AIBehaviorBase
		unitInstance.AggroType = load(_dict["AggroType"]) as AlwaysAggro

	unitInstance.GridPosition = PersistDataManager.String_To_Vector2i(_dict["GridPosition"])
	unitInstance.IsAggrod = _dict["IsAggrod"]

	var baseStatsDict = _dict["baseStats"]
	for stringref in baseStatsDict:
		var template = load(stringref) as StatTemplate
		unitInstance.baseStats[template] = baseStatsDict[stringref]

	var statmods = _dict["statModifiers"]
	for stringref in statmods:
		var template = load(stringref) as StatTemplate
		unitInstance.statModifiers[template] = statmods[stringref]

	for element in _dict["Abilities"]:
		var elementAsDict = JSON.parse_string(element)
		var prefab = load(elementAsDict["prefab"]) as PackedScene
		var newInstance = unitInstance.AddAbility(prefab)
		if newInstance != null:
			newInstance.FromJSON(elementAsDict)

	for abl in unitInstance.Abilities:
		if abl.type == Ability.AbilityType.Weapon:
			unitInstance.EquippedWeapon = abl
			break

	var data = PersistDataManager.JSONToArray(_dict["ItemSlots"], Callable.create(Item, "FromJSON"))
	unitInstance.ItemSlots.assign(data)

	unitInstance.UpdateDerivedStats()
	unitInstance.CreateVisual()
	# Set these after derived stats, so that health can actually be equal to the correct values
	unitInstance.currentHealth = _dict["currentHealth"]
	unitInstance.currentFocus = _dict["currentFocus"]

	var updateActivated = func(_dict : Dictionary):
		unitInstance.Activated = _dict["Activated"]
	updateActivated.call_deferred(_dict)

	unitInstance.RefreshVisuals()
	return unitInstance
