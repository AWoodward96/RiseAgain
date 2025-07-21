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
@export var affinityIcon: TextureRect
@export var hasLootIcon : Node2D
@export var isBossIcon : Node2D

@export_category("SFX")
@export var takeDamageSound : FmodEventEmitter2D
@export var takeLethalDamageSound : FmodEventEmitter2D
@export var footstepsSound : FmodEventEmitter2D
@export var deathSound : FmodEventEmitter2D
@export var LeapSound : FmodEventEmitter2D
@export var LandSound : FmodEventEmitter2D

@onready var health_bar_parent = %HealthBarParent

@onready var damage_indicator: DamageIndicator = $DamageIndicator
@onready var positive_affinity: TextureRect = %PositiveAffinity

@onready var negative_affinity: TextureRect = %NegativeAffinity

var GridPosition : Vector2i
var CurrentTile : Tile
var Template : UnitTemplate
var visual : UnitVisual # could be made generic, but probably not for now
var UnitAllegiance : GameSettingsTemplate.TeamID = GameSettingsTemplate.TeamID.ALLY
var ItemSlots : Array[Item]
var Abilities : Array[Ability]
var CombatEffects : Array[CombatEffectInstance]
var EquippedWeapon : Ability
var Submerged : bool = false
var IsBoss : bool = false


var MovementIndex : int
var MovementRoute : PackedVector2Array
var MovementVelocity : Vector2
var CanMove : bool
var PendingMove : bool
var Injured : bool = false

var ActionStack : Array[UnitActionBase]
var CurrentAction : UnitActionBase
var TurnStartTile : Tile # The tile that this Unit Started their turn on

var baseStats = {}			#Stats determined by the template object and out-of-run-progression
var statModifiers = {}		#Stats determined by in-run progression. These are NOT temporary, and shouldn't be removed

var facingDirection : GameSettingsTemplate.Direction

var Level : int
var Exp : int
var ExtraEXPGranted : int = 0
var IsDying : bool = false

var AI # Only used by units initialized via a spawner
var AggroType # Only used by units initialized via a spawner
var IsAggrod : bool = false

var map : Map
var currentHealth

var takeDamageTween : Tween

var unitPersistence : UnitPersistBase

var DisplayLevel : int :
	get: return Level + 1

var trueMaxHealth :
	get:
		return GetWorkingStat(GameManager.GameSettings.HealthStat, true) as float

var maxHealth :
	get:
		return GetWorkingStat(GameManager.GameSettings.HealthStat) as float

var healthPerc :
	get:
		return currentHealth as float / maxHealth

var IsStackFree:
	get:
		return ActionStack.size() == 0 && CurrentAction == null

var Activated : bool :
	set(_value):
		if visual != null:
			visual.SetActivated(_value)

		Activated = _value

var IsFlying : bool :
	get:
		return Template.Descriptors.has(GameManager.GameSettings.FlyingDescriptor)

var CanHeal : bool :
	get:
		return currentHealth < maxHealth

func _ready():
	ShowHealthBar(false)
	healthBar.SetUnit(self)
	HideDamagePreview()

	damage_indicator.scale = Vector2i(Template.GridSize, Template.GridSize)
	health_bar_parent.scale = Vector2i(Template.GridSize, Template.GridSize)

	name = "{0}_{1}_{2}".format({"0" : str(UnitAllegiance), "1" : Template.DebugName, "2" : str(randi() % 100000)})

func Initialize(_unitTemplate : UnitTemplate, _levelOverride : int = 0, _healthPerc : float = 1) :
	Template = _unitTemplate

	RefreshVisuals()

	if ItemSlots.size() == 0:
		for s in GameManager.GameSettings.ItemSlotsPerUnit:
			ItemSlots.append(null)

	unitPersistence = PersistDataManager.universeData.GetUnitPersistence(Template)
	CreateStartingAbilities()
	InitializeLevels(_levelOverride)
	InitializeStats()
	UpdateDerivedStats()
	InitializeTier0Abilities()

	currentHealth = roundi(maxHealth * _healthPerc)

func RefreshVisuals():
	if Template.Affinity != null:
		affinityIcon.texture = Template.Affinity.loc_icon

	footstepsSound.event_guid = AudioManager.DefaultFootstepGUID
	if Template.FootstepGUID != "":
		footstepsSound.event_guid = Template.FootstepGUID

	isBossIcon.visible = IsBoss

func InitializeStats():
	for stat in Template.BaseStats:
		if baseStats.has(stat.Template):
			baseStats[stat.Template] += stat.Value
		else:
			baseStats[stat.Template] = stat.Value

	UpdateDerivedStats()

	# Remember: Vitality != Health. Health = Vitality * ~1.5, a value which can change for balancing
	currentHealth = GetWorkingStat(GameManager.GameSettings.HealthStat)

	IsDying = false

func UpdateDerivedStats():
	for derivedStatDef in GameManager.GameSettings.DerivedStatDefinitions:
		baseStats[derivedStatDef.Template] = floori(GetWorkingStat(derivedStatDef.ParentStat) * derivedStatDef.Ratio)

	if currentHealth != null && currentHealth > maxHealth:
		currentHealth = maxHealth


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
	UpdateDerivedStats()
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
	IsDying = false

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

func OnTileUpdated(_tile : Tile):
	if IsDying || Template == null || _tile == null:
		return

	if Template.Descriptors.has(GameManager.GameSettings.AmphibiousDescriptor):
		if _tile.OpenWater && !Submerged:
			SetSubmerged(true)
		elif Submerged && !_tile.OpenWater:
			SetSubmerged(false)

func SetSubmerged(_val : bool):
	Submerged = _val

	if damage_indicator != null:
		damage_indicator.SetSubmerged(_val)


	visual.UpdateSubmerged(_val)
	if Submerged:
		affinityIcon.visible = false
	else:
		affinityIcon.visible = true


func UpdateLoot():
	hasLootIcon.visible = false
	for loot in ItemSlots:
		if loot != null:
			hasLootIcon.visible = true

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
			else:
				# loop through the item slots of this unit. If there's any modifiers in there see if they make the difference. If they do, then increment the success count on that item
				for item in ItemSlots:
					var found = false
					if item != null && item.growthModifierData != null:
						for statdef in item.growthModifierData.GrowthModifiers:
							if statdef.Template == growth.Template:
								workingValue = workingValue + statdef.Value
								if result <= workingValue:
									found = true
									statIncrease += 1
									item.growthModifierData.SuccessCount += 1
								break

					if found:
						break


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
	if _ability == null:
		push_error("Attempting to create a null ability. Unit: " + Template.DebugName)
		return


	# We don't validate if the ability is on the template at all because maybe there might be an item that grants a
	# general use ability to any unit
	var abilityInstance = _ability.instantiate() as Ability
	if abilityInstance == null:
		return

	if abilityInstance is Item:
		push_error("Attempting to add an item to the ability array. This is not allowed. Item: " + abilityInstance.internalName)
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

func TryEquipItem(_itemPrefabOrInstance):
	var success = false
	var counter = 0
	for slot in ItemSlots:
		if slot == null:
			EquipItem(counter, _itemPrefabOrInstance)
			success = true
			break
		counter += 1
	return success


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

	item.Initialize(self)

	# Set Map also gets called when a unit gets added to the map. This is just called here just in case a Unit gets an item mid map
	if map != null: item.SetMap(map)

	if ItemSlots[_slotIndex] == null:
		if item != null:
			var parent = item.get_parent()
			if parent != null:
				parent.remove_child(item)
			itemsParent.add_child(item)
		ItemSlots[_slotIndex] = item
		UpdateDerivedStats()
		if UnitAllegiance != GameSettingsTemplate.TeamID.ALLY:
			UpdateLoot()

		OnStatUpdated.emit()
		return true
	else:
		itemsParent.remove_child(ItemSlots[_slotIndex])
		itemsParent.add_child(item)
		ItemSlots[_slotIndex] = item
		UpdateDerivedStats()
		OnStatUpdated.emit()
		return true


func MoveCharacterToNode(_route : Array[Tile], _tile : Tile, _speedOverride : int = -1, _moveFromAbility : bool = false, _cutsceneMove : bool = false, _allowOverwrite : bool = false, _style : UnitSettingsTemplate.MovementAnimationStyle = UnitSettingsTemplate.MovementAnimationStyle.Normal) :
	if _route == null  || _route.size() == 0:
		return

	var action = UnitMoveAction.new()
	action.Route = _route
	action.DestinationTile = _tile
	action.SpeedOverride = _speedOverride
	action.MoveFromAbility = _moveFromAbility
	action.CutsceneMove = _cutsceneMove
	action.AllowOccupantOverwrite = _allowOverwrite
	action.AnimationStyle = _style
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
	return GetWorkingStat(GameManager.GameSettings.MovementStat)

func Activate(_currentTurn : GameSettingsTemplate.TeamID):
	# Turns on this unit to let them take their turn
	Activated = true
	CanMove = true
	PendingMove = false
	CurrentAction = null
	ActionStack.clear()


	# If it's your units turn
	if _currentTurn == UnitAllegiance:
		# defending doesn't drop off until it's your turn again
		for abl in Abilities:
			abl.OnOwnerUnitTurnStart()

		TriggerTurnStartEffects()
		UpdateCombatEffects()

	# for 'canceling' movement
	TurnStartTile = CurrentTile
	PlayAnimation(UnitSettingsTemplate.ANIM_IDLE)
	if visual != null:
		visual.ResetAnimation()

func LockInMovement():
	if PendingMove:
		TurnStartTile = CurrentTile
		CanMove = false

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

func QueueAcquireLoot(_item : Item):
	var lootGain = UnitAcquireLootAction.new()
	lootGain.loot = _item
	ActionStack.append(lootGain)
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
	if _netHealthChange <= 0:
		# If this is a damage based change - armor should reduce the amount of damage taken
		# Since healthChange would be negative here, healthChange
		var armor = GetArmorAmount()
		Juice.CreateDamagePopup(min(_netHealthChange + armor, 0), map.grid.GetTileFromGlobalPosition(global_position))
		if -_netHealthChange >= currentHealth:
			takeLethalDamageSound.play()
		else:
			takeDamageSound.play()
		visual.PlayDamageAnimation()

	else:
		Juice.CreateHealPopup(_netHealthChange, map.grid.GetTileFromGlobalPosition(global_position))

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
func GetWorkingStat(_statTemplate : StatTemplate, _ignoreInjured : bool = false):
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
			var statChanges = (effect as StatChangeEffectInstance).GetEffects() as Array[StatBuff]
			for change in statChanges:
				if change != null && change.Stat == _statTemplate:
					current += change.Value

	if unitPersistence != null:
		current += unitPersistence.GetPrestiegeStatMod(_statTemplate)

	if Injured && !_ignoreInjured:
		if GameManager.GameSettings.InjuredAffectedStats.has(_statTemplate):
			current = roundi(float(current) - (float(current) * GameManager.GameSettings.InjuredStatsDebuff))
		elif _statTemplate == GameManager.GameSettings.HealthStat:
			current = roundi(float(current) - (float(current) * GameManager.GameSettings.InjuredHealthDebuff))

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

func PlayDeathAnimation():
	IsDying = true
	affinityIcon.visible = false
	if visual != null && visual.AnimationWorkComplete:
		deathSound.play()
		PlayAnimation(UnitSettingsTemplate.ANIM_TAKE_DAMAGE)
		var tween = create_tween()
		tween.tween_interval(Juice.combatSequenceCooloffTimer)
		tween.tween_property(visual.visual.material, 'shader_parameter/tint', Color(0.0,0.0,0.0,0.0), 0.5)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_EXPO)
		tween.tween_interval(1)
		tween.tween_callback(DeathAnimComplete)
	else:
		deathSound.play()
		var tween = create_tween()
		tween.tween_interval(Juice.combatSequenceCooloffTimer)
		tween.tween_property(visual.sprite, 'self_modulate', Color(0,0,0,0), 0.5)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_EXPO)
		tween.tween_interval(1)
		tween.tween_callback(DeathAnimComplete)


func DeathAnimComplete():
	if  UnitAllegiance == GameSettingsTemplate.TeamID.ALLY:
		if !Injured:
			Injured = true
			if GameManager.CurrentCampaign != null:
				GameManager.CurrentCampaign.UnitInjured(self)
			else:
				map.QueueUnitForRemoval(self)
		else:
			if GameManager.CurrentCampaign != null:
				GameManager.CurrentCampaign.RegisterUnitDeath(self)
			else:
				map.QueueUnitForRemoval(self)

	else:
		map.QueueUnitForRemoval(self)

func CheckKillbox():
	if CurrentTile.ActiveKillbox && !IsFlying:
		if CurrentTile.OpenWater && Template.Descriptors.has(GameManager.GameSettings.AmphibiousDescriptor):
			return false

		# The unit's fucking dead - kill them
		ModifyHealth(-currentHealth - GetArmorAmount(), null, true)
		return true
	return false

func ShowHealthBar(_visible : bool):
	health_bar_parent.visible = _visible
	if _visible:
		healthBar.Refresh()

func QueueAttackSequence(_destination : Vector2, _log : ActionLog, _useRetaliation : bool = false):
	var attackAction = UnitAttackAction.new()
	attackAction.TargetPosition = _destination
	attackAction.IsRetaliation = _useRetaliation

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


func ShowAffinityRelation(_affinity : AffinityTemplate):
	if _affinity == null:
		positive_affinity.visible = false
		negative_affinity.visible = false
		return

	# Chat, I love bitwise ops
	if _affinity.strongAgainst & Template.Affinity.affinity:
		negative_affinity.visible = true

	if Template.Affinity.strongAgainst & _affinity.affinity:
		positive_affinity.visible = true

# Checks all the item slots and sees if the unit has any item equipped
func HasAnyItem():
	for i in ItemSlots:
		if i != null:
			return true
	return false

func Rest():
	for ability in Abilities:
		ability.OnRest()

	Injured = false
	currentHealth = maxHealth

func PreviewModifiedTile(_tile : Tile):
	if _tile != null:
		position = _tile.GlobalPosition

func ResetVisualToTile():
	position = CurrentTile.GlobalPosition

func PlayAnimation(_animString : String, _smoothTransition : bool = false, _animSpeed : float = 1, _fromEnd : bool = false):
	if visual != null:
		visual.PlayAnimation(_animString, _smoothTransition, _animSpeed, _fromEnd)

# Should check to see if now's actually when we should return to idle.
# Is currently just a wrapping method
func TryPlayIdleAnimation():
	if visual != null:
		PlayAnimation(UnitSettingsTemplate.ANIM_IDLE)

func PlayPrepAnimation(_dst : Vector2, _animSpeed : float = 1):
	if visual != null && visual.AnimationWorkComplete:
		var round = GameManager.GameSettings.AxisRound(_dst)
		match round:
			Vector2.UP:
				visual.PlayAnimation(UnitSettingsTemplate.ANIM_PREP_UP, false, _animSpeed)
			Vector2.RIGHT:
				visual.PlayAnimation(UnitSettingsTemplate.ANIM_PREP_RIGHT, false, _animSpeed)
			Vector2.DOWN:
				visual.PlayAnimation(UnitSettingsTemplate.ANIM_PREP_DOWN, false, _animSpeed)
			Vector2.LEFT:
				visual.PlayAnimation(UnitSettingsTemplate.ANIM_PREP_LEFT, false, _animSpeed)

func PlayAttackAnimation(_dst : Vector2, _animSpeed : float = 1):
	if visual != null && visual.AnimationWorkComplete:
		var round = GameManager.GameSettings.AxisRound(_dst)
		match round:
			Vector2.UP:
				visual.PlayAnimation(UnitSettingsTemplate.ANIM_ATTACK_UP, false, _animSpeed)
			Vector2.RIGHT:
				visual.PlayAnimation(UnitSettingsTemplate.ANIM_ATTACK_RIGHT, false, _animSpeed)
			Vector2.DOWN:
				visual.PlayAnimation(UnitSettingsTemplate.ANIM_ATTACK_DOWN, false, _animSpeed)
			Vector2.LEFT:
				visual.PlayAnimation(UnitSettingsTemplate.ANIM_ATTACK_LEFT, false, _animSpeed)


func ToJSON():
	var dict = {
		"Template" : Template.resource_path,
		"currentHealth" : currentHealth,
		"Level" : Level,
		"Exp" : Exp,
		"CanMove" : CanMove,
		"GridPosition" : GridPosition,
		"IsAggrod" : IsAggrod,
		"UnitAllegience" : UnitAllegiance,
		"Activated" : Activated,
		"ExtraEXPGranted" : ExtraEXPGranted,
		"Abilities" : PersistDataManager.ArrayToJSON(Abilities),
		"CombatEffects" : PersistDataManager.ArrayToJSON(CombatEffects),
		"Injured" : Injured,
		"Submerged" : Submerged,
		"IsBoss" : IsBoss
	}

	dict["ItemSlots"] = PersistDataManager.ArrayToJSON(ItemSlots)
	if AI != null:
		dict["AI"] = AI.resource_path
		if AggroType != null:
			# Fuck this needs to be persisted doesn't it
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
	unitInstance.CanMove = _dict["CanMove"]
	unitInstance.Injured = _dict["Injured"]

	unitInstance.ExtraEXPGranted = int(_dict["ExtraEXPGranted"])

	if _dict.has("AI"):
		unitInstance.AI = load(_dict["AI"]) as AIBehaviorBase
		if _dict.has("AggroType"):
			if _dict["AggroType"] == "":
				unitInstance.AggroType = null
			else:
				unitInstance.AggroType = load(_dict["AggroType"]) as AlwaysAggro

	unitInstance.GridPosition = PersistDataManager.String_To_Vector2i(_dict["GridPosition"])
	unitInstance.IsAggrod = _dict["IsAggrod"]
	unitInstance.Submerged = _dict["Submerged"]

	unitInstance.unitPersistence = PersistDataManager.universeData.GetUnitPersistence(unitInstance.Template)
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


	var cedata = PersistDataManager.JSONToArray(_dict["CombatEffects"], Callable.create(CombatEffectInstance, "FromJSON"))
	unitInstance.CombatEffects.assign(cedata)

	var elementIndex = 0
	for itemElement in _dict["ItemSlots"]:
		if itemElement != "NULL":
			var elementAsDict = JSON.parse_string(itemElement)
			var prefab = load(elementAsDict["prefab"]) as PackedScene
			var newInstance = prefab.instantiate() as Item
			unitInstance.EquipItem(elementIndex, newInstance)
			if newInstance != null:
				newInstance.FromJSON(elementAsDict)

		elementIndex += 1


	if _dict.has("IsBoss"):
		unitInstance.IsBoss = _dict["IsBoss"]


	unitInstance.UpdateDerivedStats()
	unitInstance.CreateVisual()
	# Set these after derived stats, so that health can actually be equal to the correct values
	unitInstance.currentHealth = _dict["currentHealth"]

	var updateActivated = func(_internalDict : Dictionary):
		unitInstance.Activated = _internalDict["Activated"]
	updateActivated.call_deferred(_dict)


	unitInstance.RefreshVisuals()
	return unitInstance
