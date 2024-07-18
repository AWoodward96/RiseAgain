extends Resource
class_name GameSettingsTemplate


enum TeamID { ALLY = 1, ENEMY = 2, NEUTRAL = 4 }
enum Direction { Up, Right, Down, Left }

@export var CampaignManifest : Array[PackedScene]

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

@export var InitializeUnitsWithMaxFocus : bool = false
@export var NumberOfRewardsInPostMap = 3

@export var CharacterTileMovemementSpeed : float = 100

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

	var neighbors = _currentGrid.GetAdjacentTiles(_currentTile)
	for n in Grid.NEIGHBORS:
		var pos = _currentTile.Position + n
		var tile = _currentGrid.GetTile(pos)
		if tile != null:
			return GetDirectionFromVector(n)

	return 2

func DamageCalculation(_atk, _def):
	return floori(max(_atk - _def, 0))

func HitRateCalculation(_attacker : UnitInstance, _attackerWeapon : Item, _defender : UnitInstance):
	return HitChance(_attacker, _attackerWeapon) - AvoidChance(_defender)

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

func HitChance(_attacker : UnitInstance, _weapon : Item):
	if _attacker == null:
		push_error("Attacker is null when HitChance is called. How can there be a hit chance if no one is attacking? Please investigate")
		return 0

	var weaponAccuracy = 0
	if _weapon != null:
		weaponAccuracy = _weapon.GetAccuracy()

	# Equation is:
	# WeaponAcc + (Skill * 2) + (Luck / 2)
	return (weaponAccuracy + (_attacker.GetWorkingStat(SkillStat) * 2.0) + (_attacker.GetWorkingStat(LuckStat) / 2.0)) / 100.0

func AvoidChance(_defender : UnitInstance):
	if _defender == null:
		return 0

	# Equation is:
	# (Skill * 2) + (Luck)
	return ((_defender.GetWorkingStat(SkillStat) * 2) + _defender.GetWorkingStat(LuckStat)) / 100.0
