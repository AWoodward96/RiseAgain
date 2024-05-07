class_name AbilityContext

var map : Map
var grid : Grid
var controller : PlayerController

var source : UnitInstance
var ability : AbilityInstance
var targetTiles : Array[Tile] # Abilities target tiles, if those tiles have units on them, deal damage to those units
var originTile : Tile # The tile that the player selected
var damageContext : SkillDamageData

func Construct(_map : Map, _unit : UnitInstance, _ability : AbilityInstance):
	map = _map
	grid = map.grid
	controller = _map.playercontroller
	source = _unit
	ability = _ability
