extends Resource
class_name GameSettings


enum TeamID { ALLY = 1, ENEMY = 2, NEUTRAL = 4 }

@export var CampaignManifest : Array[PackedScene]

@export var PlayerControllerPrefab : PackedScene
@export var DerivedStatDefinitions : Array[DerivedStatDef]

@export var MovementStat : StatTemplate
@export var HealthStat : StatTemplate
@export var SkillStat : StatTemplate
@export var LuckStat : StatTemplate

@export var NumberOfRewardsInPostMap = 3

@export var CharacterTileMovemementSpeed : float = 100


func DamageCalculation(_atk, _def):
	return floori(max(_atk - _def, 0))

func HitRateCalculation(_attacker : UnitInstance, _attackerWeapon : Item, _defender : UnitInstance):
	return HitChance(_attacker, _attackerWeapon) - AvoidChance(_defender)

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
