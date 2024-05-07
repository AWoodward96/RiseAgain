class_name AbilityContext

var map : Map
var grid : Grid
var controller : PlayerController

var context_dictionary = {}
var source : UnitInstance
var ability : AbilityInstance
var target # Can be a single Unit, can be an array of units. Leave undefined for now
var damageContext : DamageContext

# pass in from Ability Instance
var persisted_dictionary = {}

func Construct(_map : Map, _unit : UnitInstance, _ability : AbilityInstance):
	map = _map
	grid = map.grid
	controller = _map.playercontroller
	source = _unit
	ability = _ability
	persisted_dictionary = _ability.persisted_dictionary
