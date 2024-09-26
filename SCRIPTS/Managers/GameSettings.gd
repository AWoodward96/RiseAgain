extends Resource
class_name GameSettingsTemplate

enum TeamID { ALLY = 1, ENEMY = 2, NEUTRAL = 4 }
enum Direction { Up, Right, Down, Left }


@export_category("Campaign Data")
@export var CampaignManifest : Array[PackedScene]
@export var NumberOfRewardsInPostMap = 3

@export_category("Unit Data")
@export var PlayerControllerPrefab : PackedScene
@export var DerivedStatDefinitions : Array[DerivedStatDef]

@export var UIDisplayedStats : Array[StatTemplate]
@export var LevelUpStats : Array[StatTemplate]

@export var MovementStat : StatTemplate
@export var HealthStat : StatTemplate
@export var AttackStat : StatTemplate
@export var DefenseStat : StatTemplate
@export var SpAttackStat : StatTemplate
@export var SpDefenseStat : StatTemplate
@export var SkillStat : StatTemplate
@export var LuckStat : StatTemplate
@export var MindStat : StatTemplate

@export var CharacterTileMovemementSpeed : float = 100

@export_category("Ability Data")
@export var InitializeUnitsWithMaxFocus : bool = false

@export var FirstAbilityBreakpoint : int
@export var SecondAbilityBreakpoint : int # NOTE: NOT CURRENTLY IMPLEMENTED


@export_category("Affinity Data")
@export var StrongAffinityMultiplier : float = 1.5
@export var OpposedAffinityMultiplier : float = 1.25
@export var WeakAffinityMultiplier : float = 0.66
@export var AffinityAccuracyModifier : int = 10
@export var AllAffinities : Array[AffinityTemplate]


static func GetVectorFromDirection(_dir : Direction):
	match(_dir):
		Direction.Up:
			return Vector2i.UP
		Direction.Left:
			return Vector2i.LEFT
		Direction.Right:
			return Vector2i.RIGHT
		Direction.Down:
			return Vector2i.DOWN

# THIS RETURNS THE OPPOSITE VECTOR -- USE THE ABOVE METHOD FOR ACTUAL DIRECTION
static func GetInverseVectorFromDirection(_dir : Direction):
	match(_dir):
		Direction.Up:
			return Vector2i.DOWN
		Direction.Left:
			return Vector2i.RIGHT
		Direction.Right:
			return Vector2i.LEFT
		Direction.Down:
			return Vector2i.UP

static func GetDirectionFromVector(_vector : Vector2i):
	# If Godot had it's shit together, I could cast this enum to an Int, but currently every enum casts to 0, which is fucking stupid as shit
	# So for now we're just gonna.... do this horrible bullshit I guess
	match(_vector):
		Vector2i.UP:
			return Direction.Up
		Vector2i.RIGHT:
			return Direction.Right
		Vector2i.DOWN:
			return Direction.Down
		Vector2i.LEFT:
			return Direction.Left

	return Direction.Down

static func CastIntToDirectionEnum(_int : int):
	# I want this to be on the record that this is fucking stupid as shit
	match(_int):
		0:
			return Direction.Up
		1:
			return Direction.Right
		2:
			return Direction.Down
		3:
			return Direction.Left

static func CastDirectionEnumToInt(_direction : Direction):
	match(_direction):
		Direction.Up:
			return 0
		Direction.Right:
			return 1
		Direction.Down:
			return 2
		Direction.Left:
			return 3

static func GetValidDirectional(_currentTile : Tile, _currentGrid : Grid, _preferredDirection : int = -1):
	if _preferredDirection != -1:
		var pos = _currentTile.Position + GetVectorFromDirection(_preferredDirection)
		var tile = _currentGrid.GetTile(pos)
		if tile != null:
			return _preferredDirection

	for n in Grid.NEIGHBORS:
		var pos = _currentTile.Position + n
		var tile = _currentGrid.GetTile(pos)
		if tile != null:
			return GetDirectionFromVector(n)

	return 2

func DamageCalculation(_attackingUnit : UnitInstance, _defendingUnit : UnitInstance, _damageData : DamageData, _aoeMultiplier : float = 1):
	var flatValue = _damageData.FlatValue
	var aggressiveStat = _damageData.AgressiveStat
	var agressiveVal = _attackingUnit.GetWorkingStat(aggressiveStat)
	agressiveVal = flatValue + _damageData.DoMod(agressiveVal, _damageData.AgressiveMod, _damageData.AgressiveModType)

	var defensiveStat = _damageData.DefensiveStat

	var defensiveVal = 0
	if _defendingUnit != null:
		defensiveVal = _defendingUnit.GetWorkingStat(defensiveStat)
	defensiveVal = _damageData.DoMod(defensiveVal, _damageData.DefensiveMod, _damageData.DefensiveModType)

	var affinityMultiplier = 1
	if _defendingUnit != null:
		affinityMultiplier = _attackingUnit.Template.Affinity.GetAffinityDamageMultiplier(_defendingUnit.Template.Affinity)

	var vulnerabilityMultiplier = 1
	if _defendingUnit != null:
		for descriptor in _damageData.VulerableDescriptors:
			if _defendingUnit.Template.Descriptors.count(descriptor.Descriptor) > 0:
				# For now, these things wont stack
				vulnerabilityMultiplier *= descriptor.Multiplier

	return floori(max(agressiveVal - defensiveVal, 0) * affinityMultiplier * _aoeMultiplier * vulnerabilityMultiplier)

func HealCalculation(_healData : HealComponent, _source, _aoeMultiplier : float = 1):
	var healAmount = _healData.FlatValue
	if _healData.ScalingStat != null && _source != null:
		healAmount += _healData.DoMod(_source.GetWorkingStat(_healData.ScalingStat))
	healAmount = floori(healAmount * _aoeMultiplier)
	return healAmount

func HitRateCalculation(_attacker : UnitInstance, _attackerWeapon : UnitUsable, _defender : UnitInstance):
	return HitChance(_attacker, _defender, _attackerWeapon) - AvoidChance(_attacker, _defender)

func ExpFromHealCalculation(_healAmount : int, _source : UnitInstance, _target : UnitInstance):
	# TODO: Increase or decrease the exp gained from damaging a foe based on some metric
	return 10 + _healAmount

func ExpFromDamageCalculation(_damageDealt : int, _source : UnitInstance, _target : UnitInstance):
	# TODO: Increase or decrease the exp gained from damaging a foe based on some metric
	return 10 + _damageDealt

func ExpFromKillCalculation(_damageDealt : int, _source : UnitInstance, _target : UnitInstance):
	# TODO: Increase or decrease the exp gained from killing a foe based on some metric
	var X = 0
	if _target != null && _source != null:
		X = _target.Level - _source.Level

	# Define variables A B and C
	var A = 0.9 # Gradual growth
	var B = 1.4	# Exponential slope, higher number = more exp based on level diff
	var C = 0.1 # The floor of the curve. Negative level-difs gradually approach this number
	return (A * (pow(B, X)) + C) * 20 + _damageDealt

func HitChance(_attacker : UnitInstance, _defender : UnitInstance, _weapon : UnitUsable):
	if _attacker == null:
		push_error("Attacker is null when HitChance is called. How can there be a hit chance if no one is attacking? Please investigate")
		return 0

	var weaponAccuracy = 0
	if _weapon != null:
		weaponAccuracy = _weapon.GetAccuracy()

	var affinityModifier = _attacker.Template.Affinity.GetAffinityAccuracyModifier(_defender.Template.Affinity)

	# Equation is:
	# WeaponAcc + (Skill * 2) + (Luck / 2)
	return (weaponAccuracy + (_attacker.GetWorkingStat(SkillStat) * 2.0) + (_attacker.GetWorkingStat(LuckStat) / 2.0) + affinityModifier) / 100.0

func AvoidChance(_attacker : UnitInstance, _defender : UnitInstance):
	if _defender == null:
		return 0

	var affinityModifier = _defender.Template.Affinity.GetAffinityAccuracyModifier(_attacker.Template.Affinity)

	# Equation is:
	# (Skill * 2) + (Luck)
	return ((_defender.GetWorkingStat(SkillStat) * 2) + _defender.GetWorkingStat(LuckStat) + affinityModifier) / 100.0
