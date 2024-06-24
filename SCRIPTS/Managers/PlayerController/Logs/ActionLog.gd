class_name ActionLog

var source : UnitInstance
var availableTiles : Array[Tile] # The working tiles that are available when you select targeting. Updated via the Item or Abilities PollTargets
var actionOriginTile : Tile # The tile that this action is actually centered on. Sort of like the PlayerControllers CurrentTile
							# It's the single tile that the Player selected during targeting

var sourceTile : Tile		# Where this action is coming from. Is usually Source.CurrentTile, but might not be
var affectedTiles : Array[Tile] # This is an array in case of aoe. Here are all of the tiles that were hit by this action. Could be one, could be many

var item : Item
var damageData : DamageData

var missVals : Vector2		# The log of which numbers we rolled
var missAverage : float		# The average of missVals
var hitRate : float			# The % the average needs to be under in order for it to be a hit
var miss : bool				# Is the missAverage below the hitRate
var canRetaliate : bool = true

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
	# A 10% chance to hit is much closer to a 2% chance.
	# This encourages a subtle mentality for taking attacks above a displayed 75% chance to hit, because those are 87% or better odds
	# I like this compromise in chances, because I don't think the game should be entirely run by real rng, like a game like XCOM is
	# If you miss a high percentage play, that can still be devistating,
	# but it should only occur rarely and hopefully you haven't banked too much off of it
	missAverage = (val1 + val2) / 2.0
	print("Calculated Miss Average of: ", missAverage, " at rate:", hitRate)

	miss = missAverage > _missThreshold

static func Construct(_unitSource : UnitInstance, _item : Item):
	var new = ActionLog.new()
	new.source = _unitSource
	new.item = _item
	new.sourceTile = _unitSource.CurrentTile
	new.damageData = _item.ItemDamageData
	return new
