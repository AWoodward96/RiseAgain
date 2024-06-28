class_name ActionResult

var Source : UnitInstance
var Target : UnitInstance

var HealthDelta : int
var SourceHealthDelta : int
var FocusDelta : int
var ExpGain : int
var Kill : bool

var MissVals : Vector2		# The log of which numbers we rolled
var MissAverage : float		# The average of missVals
var HitRate : float			# The % the average needs to be under in order for it to be a hit
var Miss : bool = false

func Item_CalculateResult(_rng : RandomNumberGenerator, _item : Item):
	if _item.IsDamage():
		# Damage dealing items can miss
		var hitRate = GameManager.GameSettings.HitRateCalculation(Source, _item, Target)
		CalculateMiss(_rng, hitRate)
		HealthDelta = -Target.CalculateDamage(_item.UsableDamageData, Source)

		CalculateSourceHealthDelta(_item.UsableDamageData)

		Kill = !Miss && (Target.currentHealth + HealthDelta <= 0)
	elif _item.IsHeal(false):
		# Healing items can't miss
		HealthDelta = Target.CalculateHeal(_item.HealData, Source)

	CalculateExpGain()
	CalculateFocusDelta()
	pass

func Ability_CalculateResult(_ability : Ability, _damageData):
	if _ability.IsDamage():
		HealthDelta = -Target.CalculateDamage(_damageData, Source)

		CalculateSourceHealthDelta(_ability.UsableDamageData)

		Kill = (Target.currentHealth + HealthDelta <= 0)
	elif _ability.IsHeal(false):
		# Healing items can't miss
		HealthDelta = Target.CalculateHeal(_ability.HealData, Source)

	CalculateExpGain()
	if _ability.damageGrantsFocus:
		CalculateFocusDelta()

func CalculateSourceHealthDelta(_damageData : DamageData):
	if _damageData.DamageAffectsUsersHealth:
		SourceHealthDelta = floori(HealthDelta * _damageData.DamageToHealthRatio)

func CalculateFocusDelta():
	if !Miss:
		FocusDelta += 1

	if Kill:
		FocusDelta += 1

func CalculateExpGain():
	if Miss:
		ExpGain = 1
		return

	if HealthDelta < 0: # Meaning it will deal damage
		var HealthDeltaABS = abs(HealthDelta)
		if Target.currentHealth <= HealthDeltaABS:
			ExpGain = GameManager.GameSettings.ExpFromKillCalculation(HealthDeltaABS, Source, Target)
		else:
			ExpGain = GameManager.GameSettings.ExpFromDamageCalculation(HealthDeltaABS, Source, Target)
	else:
		# It's like a heal or something
		ExpGain = GameManager.GameSettings.ExpFromHealCalculation(HealthDelta, Source, Target)

func CalculateMiss(_rng : RandomNumberGenerator, _missThreshold : float):
	var val1 = _rng.randf()
	var val2 = _rng.randf()
	MissVals = Vector2(val1, val2)
	HitRate = _missThreshold

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
	MissAverage = (val1 + val2) / 2.0
	print("Calculated Miss Average of: ", MissAverage, " at rate:", HitRate)

	Miss = MissAverage > _missThreshold
