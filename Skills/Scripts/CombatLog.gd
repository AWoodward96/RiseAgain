class_name CombatLog

var map : Map
var grid : Grid
var controller : PlayerController

var source : UnitInstance
var ability : AbilityInstance
var targetTiles : Array[Tile] # Abilities target tiles, if those tiles have units on them, deal damage to those units
var originTile : Tile # The tile that the player selected
var damageContext : DamageData
var miss : bool
var missVal : float

func Construct(_map : Map, _unit : UnitInstance, _ability : AbilityInstance):
	map = _map
	grid = map.grid
	controller = _map.playercontroller
	source = _unit
	ability = _ability


func CalculateMiss(_rng : RandomNumberGenerator):
	missVal = _rng.randf()
	miss = missVal > GameManager.GameSettings.UniversalMissChance

