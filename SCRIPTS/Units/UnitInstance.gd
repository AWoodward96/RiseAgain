extends Node2D
class_name UnitInstance

signal OnStatUpdated
signal OnCombatEffectsUpdated
signal OnUnitDamaged(_result : DamageStepResult)

@export var visualParent : Node2D
@export var abilityParent : Node2D
@export var combatEffectsParent : Node2D
@export var itemsParent : Node2D
@export var iconAnchors : Node2D
@export var damageIndicator: DamageIndicator

@export var hasLootIcon : Node2D
@export var isBossIcon : Node2D

@export_category("SFX")
@export var takeDamageSound : FmodEventEmitter2D
@export var takeLethalDamageSound : FmodEventEmitter2D
@export var footstepsSound : FmodEventEmitter2D
@export var deathSound : FmodEventEmitter2D
@export var leapSound : FmodEventEmitter2D
@export var landSound : FmodEventEmitter2D



var GridPosition : Vector2i
var CurrentTile : Tile
var PreviousTraversedTile : Tile
var Template : UnitTemplate
var Visual : UnitVisual
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
var CanMove : bool						# Or, has this unit (not) moved this turn yet?
var PendingMovementExpended : int = 0	# The amount of tiles a Unit has moved this turn - not locked in yet - because the player can still cancel out
var MovementExpended : int = 0			# The amount of tiles a Unit has definitively moved this turn and cant cancel out of
var PendingMove : bool					# Is a movement currently in process (like the player has selected a tile for this unit to move to and they are actively moving there)

var Injured : bool = false
var UsingSlowSpeedAbility : bool = false

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

var DamageTakenThisTurn : int
var DamageTakenLastTurn : int

var AI : AIBehaviorBase # Only used by units initialized via a spawner
var AggroType : AlwaysAggro # Only used by units initialized via a spawner
var IsAggrod : bool = false

var map : Map
var currentHealth : int

var takeDamageTween : Tween

var unitPersistence : UnitPersistBase

var extraHealthBars : int = 0

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
		if Visual != null:
			Visual.SetActivated(_value)

		Activated = _value

var IsFlying : bool :
	get:
		return Template.Descriptors.has(GameManager.GameSettings.FlyingDescriptor)

var CanHeal : bool :
	get:
		return currentHealth < maxHealth

var Shrouded : bool :
	get:
		if CurrentTile != null:
			return CurrentTile.IsShroud
		else:
			return false

var Stealthed : bool :
	get:
		return StealthedCount > 0

var Invulnerable : bool :
	get:
		for effect in CombatEffects:
			if effect is InvulnerableEffectInstance && !effect.IsExpired():
				return true
		return false

var StealthedCount : int = 0 :
	set(v):
		StealthedCount = v
		if StealthedCount < 0:
			StealthedCount = 0

var ShroudedFromPlayer : bool :
	get:
		if UnitAllegiance == GameSettingsTemplate.TeamID.ALLY:
			return false

		if CurrentTile != null && CurrentTile.IsShroud:
			# This is the only thing that matters. Is it shrouded for the Ally
			return !CurrentTile.Shroud.Exposed[GameSettingsTemplate.TeamID.ALLY]
		else:
			return false

func _ready():
	ShowHealthBar(false)
	HideDamagePreview()

	damageIndicator.scale = Vector2i(Template.GridSize, Template.GridSize)
	damageIndicator.AssignOwner(self)
	iconAnchors.scale = Vector2i(Template.GridSize, Template.GridSize)

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
		AddPackedAbility(load(abilityPath))

func AddCombatEffect(_combatEffectInstance : CombatEffectInstance):
	if _combatEffectInstance == null:
		return

	# If it's not stackable, don't try and stack it
	if _combatEffectInstance.Template.StackableType != CombatEffectTemplate.EStackableType.None:
		# but if it isssss, you need to know where you're stacking it
		var matchingEffectType = null
		for effect in CombatEffects:
			var scriptType = _combatEffectInstance.get_script()
			var effectScriptType = effect.get_script()
			if scriptType == effectScriptType:
				matchingEffectType = effect
				break

		# If we found it, then apply the stack
		if matchingEffectType != null:
			matchingEffectType.Stacks += _combatEffectInstance.Stacks
			match matchingEffectType.Template.StackableType:
				CombatEffectTemplate.EStackableType.AddTurns:
					matchingEffectType.TurnsRemaining += _combatEffectInstance.TurnsRemaining
				CombatEffectTemplate.EStackableType.ResetTurnCount:
					matchingEffectType.TurnsRemaining = max(matchingEffectType.Template.Turns, _combatEffectInstance.Template.Turns)
		else:
			# If there's nothing to stack, ignore the rules, and just add the combat effect like normal
			CombatEffects.append(_combatEffectInstance)
			combatEffectsParent.add_child(_combatEffectInstance)
			_combatEffectInstance.OnEffectApplied()

	else:
		CombatEffects.append(_combatEffectInstance)
		combatEffectsParent.add_child(_combatEffectInstance)
		_combatEffectInstance.OnEffectApplied()

	UpdateCombatEffects()
	UpdateDerivedStats()
	damageIndicator.healthbar.Refresh()

	if _combatEffectInstance is StealthEffectInstance:
		StealthedCount += 1

	if _combatEffectInstance is StatChangeEffectInstance:
		var changes = _combatEffectInstance.GetEffects()
		for c in changes:
			if c.Stat == GameManager.GameSettings.MovementStat && c.Value > 0:
				ReEnableMovement()

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
			if c.Template.ExpirationType == CombatEffectTemplate.EExpirationType.Normal:
				slatedForRemoval.append(c)
			elif c.Template.ExpirationType == CombatEffectTemplate.EExpirationType.RemoveStack:
				if c.Stacks > 1:
					c.Stacks -= 1
					c.TurnsRemaining = c.Template.Turns
				else:
					slatedForRemoval.append(c)

	OnCombatEffectsUpdated.emit()

	for remove in slatedForRemoval:
		if remove is StealthEffectInstance:
			StealthedCount -= 1

		remove.OnEffectRemoved()
		CombatEffects.remove_at(CombatEffects.find(remove))
		combatEffectsParent.remove_child(remove)
		remove.queue_free()

func AddToMap(_map : Map, _gridLocation : Vector2i, _allegiance: GameSettingsTemplate.TeamID, _extraHealthBars : int = 0):
	GridPosition = _gridLocation
	map = _map
	UnitAllegiance = _allegiance
	IsDying = false
	extraHealthBars = _extraHealthBars

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


func OnMapComplete():
	ShowHealthBar(false)

	# Clear out all combat effects bc they shouldn't persist between maps
	for e in CombatEffects:
		e.queue_free()
	CombatEffects.clear()


func OnTileUpdated(_tile : Tile):
	if IsDying || Template == null || _tile == null:
		return


	CurrentTile = _tile

	if Template.Descriptors.has(GameManager.GameSettings.AmphibiousDescriptor):
		if _tile.OpenWater && !Submerged:
			SetSubmerged(true)
		elif Submerged && !_tile.OpenWater:
			SetSubmerged(false)

	if _tile.IsShroud && _tile.Shroud != null:
		_tile.Shroud.UnitEntered(_tile, self)

	if PreviousTraversedTile != null && PreviousTraversedTile.Shroud != null && (_tile.Shroud == null || _tile.Shroud != PreviousTraversedTile.Shroud):
		PreviousTraversedTile.Shroud.UnitExited(self)

	if !ShroudedFromPlayer:
		map.UpdateObscure(PreviousTraversedTile, CurrentTile)

	PreviousTraversedTile = _tile


func SetSubmerged(_val : bool):
	Submerged = _val

	if damageIndicator != null:
		damageIndicator.SetSubmerged(_val)


	Visual.UpdateSubmerged(_val)


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

	Visual = Template.VisualPrefab.instantiate() as UnitVisual
	visualParent.add_child(Visual)
	Visual.Initialize(self)


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

	var meal = PersistDataManager.universeData.bastionData.ActiveMeal

	var levelUpResult = {}
	for i in _levelIncrease:
		for growth in Template.StatGrowths:
			var workingValue = growth.Value
			var statIncrease = 0

			if meal != null:
				# check the meal for mods
				for modifiers : StatDef in meal.statGrowthMods:
					if modifiers.Template == growth.Template:
						workingValue += modifiers.Value

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
	var weapPath : String = ""
	var tacPath : String = ""
	if unitPersistence != null:
		# loads the starting weapons and tacticals based on the persist data
		if unitPersistence.EquippedStartingWeapon != null: weapPath = unitPersistence.EquippedStartingWeapon.AbilityPath
		if unitPersistence.EquippedStartingTactical != null: tacPath = unitPersistence.EquippedStartingTactical.AbilityPath
	else:
		# load the starting weapons and tacticals based on the template data
		if Template.StartingEquippedWeapon != null: weapPath = Template.StartingEquippedWeapon.AbilityPath
		if Template.StartingTactical != null: tacPath = Template.StartingTactical.AbilityPath

	if !weapPath.is_empty():
		AddPackedAbility(load(weapPath))

	if !tacPath.is_empty():
		AddPackedAbility(load(tacPath))

func AddAbilityInstance(_abilityInstance : Ability):
	_abilityInstance.Initialize(self)

	if _abilityInstance.type == Ability.EAbilityType.Weapon:
		# Loop through the existing abilities - anything that's equippable needs to be deleted for this to be added
		UnEquipWeapon()
		EquippedWeapon = _abilityInstance
	elif _abilityInstance.type == Ability.EAbilityType.Tactical:
		# Do the same for the tactical, but there's no 'equipped' variable to update
		UnEquipTactical()

	abilityParent.add_child(_abilityInstance)
	Abilities.append(_abilityInstance)
	return _abilityInstance

func AddPackedAbility(_ability : PackedScene):
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

	AddAbilityInstance(abilityInstance)

func UnEquipWeapon():
	for i in range(Abilities.size() -1, -1, -1):
		var abl = Abilities[i]
		if abl.type == Ability.EAbilityType.Weapon:
			abilityParent.remove_child(abl)
			if GameManager.CurrentCampaign != null:
				GameManager.CurrentCampaign.Convoy.AddToConvoy(abl)
			else:
				abl.queue_free()
			Abilities.remove_at(i)
	EquippedWeapon = null


func UnEquipTactical():
	for i in range(Abilities.size() -1, -1, -1):
		var abl = Abilities[i]
		if abl.type == Ability.EAbilityType.Tactical:
			abilityParent.remove_child(abl)
			if GameManager.CurrentCampaign != null:
				GameManager.CurrentCampaign.Convoy.AddToConvoy(abl)
			else:
				abl.queue_free()
			Abilities.remove_at(i)


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

	if item != null:
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
		if GameManager.CurrentCampaign != null:
			GameManager.CurrentCampaign.Convoy.AddToConvoy(ItemSlots[_slotIndex])


		if item != null:
			itemsParent.add_child(item)

		ItemSlots[_slotIndex] = item
		UpdateDerivedStats()
		OnStatUpdated.emit()
		return true


func MoveCharacterToNode(_movementData: MovementData) :
	if _movementData == null || _movementData.Route == null  || _movementData.Route.size() == 0:
		return

	var action = UnitMoveAction.new()
	action.movementData = _movementData
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
	for effect in CombatEffects:
		if effect == null:
			continue

		if (effect is RootEffectInstance || effect is StunEffectInstance) && !effect.IsExpired():
			return 0

	return GetWorkingStat(GameManager.GameSettings.MovementStat) - MovementExpended

func Activate(_currentTurn : GameSettingsTemplate.TeamID):
	# Turns on this unit to let them take their turn
	Activated = true
	CanMove = true
	PendingMove = false
	MovementExpended = 0
	PendingMovementExpended = 0
	CurrentAction = null
	ActionStack.clear()


	# If it's your units turn
	if _currentTurn == UnitAllegiance:
		# defending doesn't drop off until it's your turn again
		for abl in Abilities:
			abl.OnOwnerUnitTurnStart()

		TriggerTurnStartEffects()
		UpdateCombatEffects()
		UsingSlowSpeedAbility = false

	# for 'canceling' movement
	TurnStartTile = CurrentTile
	DamageTakenLastTurn = DamageTakenThisTurn
	DamageTakenThisTurn = 0
	TryPlayIdleAnimation()
	if Visual != null && !UsingSlowSpeedAbility:
		Visual.ResetAnimation()

func LockInMovement(_tile : Tile):
	if PendingMove:
		TurnStartTile = _tile
		CanMove = false
		# Here's where the amount of tiles moved get's locked in. At this point, this amount of movement has been expended
		MovementExpended = PendingMovementExpended

func ReEnableMovement():
	var movement = GetUnitMovement()
	if movement > 0:
		TurnStartTile = CurrentTile
		CanMove = true
		PendingMove = false

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
		Visual.PlayMissAnimation()
	else:
		ModifyHealth(_result.HealthDelta, _result, _instantaneous)

func ModifyHealth(_netHealthChange : int, _result : DamageStepResult, _instantaneous : bool = false):
	if _netHealthChange <= 0:
		# If this is a damage based change - armor should reduce the amount of damage taken
		# Since healthChange would be negative here, healthChange
		var armor = GetArmorAmount()
		var damageTaken = min(_netHealthChange + armor, 0)
		DamageTakenThisTurn += damageTaken

		# basically, if the unit ONLY gets ignited, it'll show the "ignite" and "no damage" right on top of each other
		# This if check is to ignore that scenario
		if !(damageTaken == 0 && _result.Ignite != 0):
			Juice.CreateDamagePopup(damageTaken, map.grid.GetTileFromGlobalPosition(global_position))

		if -_netHealthChange >= currentHealth:
			takeLethalDamageSound.play()
		else:
			takeDamageSound.play()
		Visual.PlayDamageAnimation()

	else:
		Juice.CreateHealPopup(_netHealthChange, map.grid.GetTileFromGlobalPosition(global_position))

	if !_instantaneous:
		ShowHealthBar(true)

		# NOTE:
		# If you have two back to back health bar changes - only the first one is going to go through to OnModifyHealthTweenComplete
		# You'll need to wait for one to be finished before the other one starts
		damageIndicator.ShowCombatResult(_netHealthChange, OnModifyHealthTweenComplete.bind(_netHealthChange, _result))

	else:
		OnModifyHealthTweenComplete(_netHealthChange, _result)
	pass


func OnModifyHealthTweenComplete(_delta, _result : DamageStepResult):
	var remainingDelta = _delta
	var armor = GetArmorAmount()
	if _delta < 0 && armor > 0:
		var armorDamage = clamp(_delta, -armor, 0)
		DealDamageToArmor(armorDamage)
		remainingDelta -= armorDamage

	currentHealth = clampi(currentHealth + remainingDelta, 0, maxHealth)

	if remainingDelta < 0:
		OnUnitDamaged.emit(_result)

	# For AI enemies, check if this damage would aggro them
	if _delta < 0 && AggroType is AggroOnDamage:
		IsAggrod = true

	if _result != null:
		if _result.Ignite > 0:
			Ignite(_result.Ignite, _result.Source, _result.AbilityData)


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

	if PersistDataManager.universeData.bastionData.ActiveMeal != null:
		for mealStats in PersistDataManager.universeData.bastionData.ActiveMeal.statModifiers:
			if mealStats.Template == _statTemplate:
				current += mealStats.Value

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
		if extraHealthBars > 0:
			HealthBarBreak()
		else:
			map.OnUnitDeath(self, _context)

func HealthBarBreak():
	extraHealthBars -= 1
	currentHealth = trueMaxHealth
	AddCombatEffect(GameManager.GameSettings.BossHealthBarBrokenEffect.CreateInstance(self, self, null, null))
	map.RemoveEntitiesOwnedByUnit(self)

	pass

func PlayDeathAnimation():
	IsDying = true
	damageIndicator.DeathState()
	if Visual != null && Visual.AnimationWorkComplete:
		deathSound.play()
		PlayAnimation(UnitSettingsTemplate.ANIM_TAKE_DAMAGE)
		var tween = create_tween()
		tween.tween_interval(Juice.combatSequenceCooloffTimer)
		tween.tween_property(Visual.visual.material, 'shader_parameter/tint', Color(0.0,0.0,0.0,0.0), 0.5)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_EXPO)
		tween.tween_interval(1)
		tween.tween_callback(DeathAnimComplete)
	else:
		deathSound.play()
		var tween = create_tween()
		tween.tween_interval(Juice.combatSequenceCooloffTimer)
		tween.tween_property(Visual.sprite, 'self_modulate', Color(0,0,0,0), 0.5)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_EXPO)
		tween.tween_interval(1)
		tween.tween_callback(DeathAnimComplete)


func DeathAnimComplete():
	if CurrentTile.ObscureParent != null:
		map.UpdateObscure(CurrentTile, null)

	if UnitAllegiance == GameSettingsTemplate.TeamID.ALLY:
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

func Ignite(_fireLevel : int, _source : UnitInstance, _abilityData : Ability):
	var combatEffect = GameManager.GameSettings.OnFireDebuff.CreateInstance(_source, self, _abilityData, null) as CombatEffectInstance
	combatEffect.Stacks = _fireLevel
	AddCombatEffect(combatEffect)

func ShowHealthBar(_visible : bool):
	damageIndicator.ShowHealthBar(_visible)

func QueueAttackSequence(_destination : Vector2, _log : ActionLog, _animationStyle : CombatAnimationStyleTemplate, _useRetaliation : bool = false):
	var attackAction = UnitAttackAction.new()
	attackAction.TargetPosition = _destination
	attackAction.IsRetaliation = _useRetaliation
	attackAction.AnimationStyle = _animationStyle

	# You have to pass the action index when the queue is added because the actionstack index is going to change as the action is executed.
	# This locks in which action is doing what and when
	attackAction.ActionIndex = _log.actionStackIndex
	attackAction.Log = _log

	ActionStack.append(attackAction)
	if CurrentAction == null:
		PopAction()

func QueueDefenseSequence(_damageSourcePosition : Vector2, _result : DamageStepResult):
	#var defendAction = UnitDefendAction.new()
	#defendAction.SourcePosition = _damageSourcePosition
	#defendAction.Result = _result
	#ActionStack.append(defendAction)
	#if CurrentAction == null:
		#PopAction()
	pass

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

func HideDamagePreview():
	damageIndicator.HidePreview()

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
	damageIndicator.ShowAffinityRelations(_affinity)

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
	if Visual != null:
		Visual.PlayAnimation(_animString, _smoothTransition, _animSpeed, _fromEnd)

# Should check to see if now's actually when we should return to idle.
# Is currently just a wrapping method
func TryPlayIdleAnimation():
	if Visual != null && !UsingSlowSpeedAbility:
		PlayAnimation(UnitSettingsTemplate.ANIM_IDLE)

func PlayPrepAnimation(_dst : Vector2, _animSpeed : float = 1):
	if Visual != null && Visual.AnimationWorkComplete && !UsingSlowSpeedAbility:
		var round = GameSettingsTemplate.AxisRound(_dst)
		match round:
			Vector2.UP:
				Visual.PlayAnimation(UnitSettingsTemplate.ANIM_PREP_UP, false, _animSpeed)
			Vector2.RIGHT:
				Visual.PlayAnimation(UnitSettingsTemplate.ANIM_PREP_RIGHT, false, _animSpeed)
			Vector2.DOWN:
				Visual.PlayAnimation(UnitSettingsTemplate.ANIM_PREP_DOWN, false, _animSpeed)
			Vector2.LEFT:
				Visual.PlayAnimation(UnitSettingsTemplate.ANIM_PREP_LEFT, false, _animSpeed)

func PlayAttackAnimation(_dst : Vector2, _animSpeed : float = 1):
	if Visual != null && Visual.AnimationWorkComplete:
		var round = GameSettingsTemplate.AxisRound(_dst)
		match round:
			Vector2.UP:
				Visual.PlayAnimation(UnitSettingsTemplate.ANIM_ATTACK_UP, false, _animSpeed)
			Vector2.RIGHT:
				Visual.PlayAnimation(UnitSettingsTemplate.ANIM_ATTACK_RIGHT, false, _animSpeed)
			Vector2.DOWN:
				Visual.PlayAnimation(UnitSettingsTemplate.ANIM_ATTACK_DOWN, false, _animSpeed)
			Vector2.LEFT:
				Visual.PlayAnimation(UnitSettingsTemplate.ANIM_ATTACK_LEFT, false, _animSpeed)

func PlayAlertEmote():
	Juice.CreateAlertEmote(self)

func PlayShockEmote():
	Juice.CreateShockEmote(self)

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
		"IsBoss" : IsBoss,
		"StealthedCount" : StealthedCount,
		"extraHealthBars" : extraHealthBars,
		"UsingSlowSpeedAbility" : UsingSlowSpeedAbility,
		"MovementExpended" : MovementExpended
	}

	if UsingSlowSpeedAbility && Visual.AnimationWorkComplete:
		dict["SlowSpeedAnimationString"] = Visual.AnimationCTRL.current_animation

	var itemSlotsArray : Array[String]
	for i in ItemSlots:
		if i == null:
			itemSlotsArray.append("NULL")
		else:
			itemSlotsArray.append(JSON.stringify(i.ToJSON()))
	dict["ItemSlots"] = itemSlotsArray


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
	unitInstance.UsingSlowSpeedAbility = _dict["UsingSlowSpeedAbility"]
	unitInstance.MovementExpended = _dict["MovementExpended"]

	unitInstance.ExtraEXPGranted = int(_dict["ExtraEXPGranted"])

	if unitInstance.UsingSlowSpeedAbility && _dict.has("SlowSpeedAnimationString"):
		var updateSlowSpeedAnimation = func(_internalDict : Dictionary):
			unitInstance.visual.PlayAnimation(_dict["SlowSpeedAnimationString"])
		updateSlowSpeedAnimation.call_deferred(_dict)
		pass

	if _dict.has("AI"):
		var aiBehavior = load(_dict["AI"]) as AIBehaviorBase
		var aggroType = load(_dict["AggroType"]) as AlwaysAggro
		var updateAIBehavior = func(_behavior, _aggrotype):
			unitInstance.SetAI(_behavior, _aggrotype)
		updateAIBehavior.call_deferred(aiBehavior, aggroType)



	unitInstance.GridPosition = PersistDataManager.String_To_Vector2i(_dict["GridPosition"])
	unitInstance.IsAggrod = _dict["IsAggrod"]
	unitInstance.Submerged = _dict["Submerged"]
	if _dict.has("StealthedCount"):
		unitInstance.StealthedCount = _dict["StealthedCount"]

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
		var newInstance = unitInstance.AddPackedAbility(prefab)
		if newInstance != null:
			newInstance.FromJSON(elementAsDict)

	for abl in unitInstance.Abilities:
		if abl.type == Ability.EAbilityType.Weapon:
			unitInstance.EquippedWeapon = abl
			break


	var cedata = PersistDataManager.JSONToArray(_dict["CombatEffects"], Callable.create(CombatEffectInstance, "FromJSON"))
	unitInstance.CombatEffects.assign(cedata)

	var elementIndex = 0

	for s in GameManager.GameSettings.ItemSlotsPerUnit:
		unitInstance.ItemSlots.append(null)

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

	if _dict.has("extraHealthBars"):
		unitInstance.extraHealthBars = _dict["extraHealthBars"]


	unitInstance.UpdateDerivedStats()
	unitInstance.CreateVisual()
	# Set these after derived stats, so that health can actually be equal to the correct values
	unitInstance.currentHealth = _dict["currentHealth"]

	var deferredVisualUpdate = func(_internalDict : Dictionary):
		unitInstance.Activated = _internalDict["Activated"]
		unitInstance.visual.UpdateSubmerged(unitInstance.Submerged)

	deferredVisualUpdate.call_deferred(_dict)

	unitInstance.RefreshVisuals()
	return unitInstance
