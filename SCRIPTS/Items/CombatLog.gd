class_name CombatLog

var map : Map
var grid : Grid
var controller : PlayerController

var source : UnitInstance
var sourceCombatTile : Tile # Where the unit is, or will be, when this combat is kicked off. This may be different than source.CurrentTile
var item : Item
var targetTiles : Array[Tile] # Abilities target tiles, if those tiles have units on them, deal damage to those units
var executionTile : Tile # The tile that the player selected
var damageContext : DamageData
var miss : bool

# TODO: This may be false at some point. Figure out how that makes sense
var canRetaliate = true

var missVals : Vector2
var missAverage : float
var hitRate : float

func Construct(_map : Map, _unit : UnitInstance, _item : Item, _sourceTile : Tile, _executionTile : Tile):
	map = _map
	grid = map.grid
	controller = _map.playercontroller
	source = _unit
	item = _item
	sourceCombatTile = _sourceTile
	executionTile = _executionTile

	if item.ItemDamageData != null:
		damageContext = item.ItemDamageData


func CalculateMiss(_rng : RandomNumberGenerator, _missThreshold : float):
	var val1 = _rng.randf()
	var val2 = _rng.randf()
	missVals = Vector2(val1, val2)
	hitRate = _missThreshold

	# -----------------------------------
	# This is a calculation done in fire emblem, the game I'm trying to emulate closely
	# Essentially, by averaging these two random variables we create a chance table where attacks with over 50% chance to hit
	# are more likely to hit, and attacks with less than a 50% chance to hit are less likely to hit.
	# ------------------------------------
	# So if you have a 90% chance to hit, the real % chance is actually closer to 98% chance to hit.
	# If you have a 65% chance to hit, you actually have a 75% chance to hit
	# And vice versa, if you have a 30% chance to hit, your actual chance is closer to 18%
	# A 10% chance is much closer to a 2% chance.
	# This encourages a subtle mentality for taking attacks above a displayed 75% chance to hit, because those are 87% or better odds
	# I like this compromise in chances, because I don't think the game should be entirely run by chance, like a game like XCOM is
	# If you miss a high percentage play, that can still be devistating,
	# but it should only occur rarely and hopefully you haven't banked too much off of it
	missAverage = (val1 + val2) / 2.0
	print("Calculated Miss Average of: ", missAverage, " at rate:", hitRate)

	miss = missAverage > _missThreshold

