extends DamageStepResult
class_name PerformCombatStepResult

var SourceTile : Tile
var HitRate : float			# The % the average needs to be under in order for it to be a hit
var CritRate : float		# The % the roll needs to be under in order for it to be a crit


var MissVals : Vector2		# The log of which numbers we rolled
var MissAverage : float		# The average of missVals

var RetaliationResult : DamageStepResult

func PreCalculate():
	## Target died somewhere in the process - return null
	# NOTE: I had this commented out at some point because of an error I ran into -- not quite sure how to handle this at the moment
	# So just.... bleh
	#if Target == null:
		#return

	if AbilityData.IsDamage():
		# Damage dealing with autoattacks can miss
		HitRate = 100
		if AbilityData.type == Ability.AbilityType.Weapon || GameManager.GameSettings.AbilitiesCanMiss:
			if Target != null:
				HitRate = GameManager.GameSettings.HitRateCalculation(Source, AbilityData, Target, TileTargetData)

		# No crits in cutscenes it fucks with everything
		if CutsceneManager.active_cutscene != null:
			CritRate = 0
		else:
			CritRate = GameManager.GameSettings.CritRateCalculation(Source, AbilityData, Target, TileTargetData)

		HealthDelta = -GameManager.GameSettings.DamageCalculation(Source, Target, AbilityData.UsableDamageData, TileTargetData)
		Ignite = TileTargetData.Ignite

		# calculate if the source unit heals or is hurt by this attack
		CalculateSourceHealthDelta(AbilityData.UsableDamageData)

		Kill = false
		UpdateWillKill()

	elif AbilityData.IsHeal():
		# Healing items can't miss
		HealthDelta = GameManager.GameSettings.HealCalculation(AbilityData.HealData, Source, TileTargetData.AOEMultiplier)


func RollChance(_rng : DeterministicRNG):
	RollMiss(_rng, HitRate)
	RollCrit(_rng, CritRate)

	if Crit:
		HealthDelta = HealthDelta * GameManager.GameSettings.CritMultiplier
		Juice.CreateCritPopup(TileTargetData.Tile)

	UpdateWillKill()
	CalculateExpGain()
	if AbilityData.damageGrantsFocus:
		CalculateFocusDelta()

func UpdateWillKill():
	if Target != null:
		if Miss:
			Kill = false
		else:
			Kill = (Target.currentHealth + HealthDelta <= 0)

func CalculateSourceHealthDelta(_damageData : DamageData):
	if _damageData.DamageAffectsUsersHealth && Target != null:
		SourceHealthDelta = min(floori(HealthDelta * _damageData.DamageToHealthRatio), Target.currentHealth)

func CalculateFocusDelta():
	#if !Miss && Target != null:
		#FocusDelta += 1

	if Kill:
		FocusDelta += 1

func CalculateExpGain():
	if Miss:
		ExpGain = 1
		return

	var isAOE = false
	if AbilityData != null && AbilityData.TargetingData != null:
		isAOE = !(AbilityData.TargetingData.Type == SkillTargetingData.TargetingType.Simple || AbilityData.TargetingData.Type == SkillTargetingData.TargetingType.SelfOnly)

	if HealthDelta < 0: # Meaning it will deal damage
		var HealthDeltaABS = abs(HealthDelta)
		if Target != null:
			if Target.currentHealth <= HealthDeltaABS:
				ExpGain = GameManager.GameSettings.ExpFromKillCalculation(HealthDeltaABS, Source, Target, isAOE)
			else:
				ExpGain = GameManager.GameSettings.ExpFromDamageCalculation(HealthDeltaABS, Source, Target, isAOE)
		else:
			ExpGain = 1
	else:
		# It's like a heal or something
		ExpGain = GameManager.GameSettings.ExpFromHealCalculation(HealthDelta, Source, Target)

func RollMiss(_rng : DeterministicRNG, _missThreshold : float):
	var val1 = _rng.NextFloat(0, 1)
	var val2 = _rng.NextFloat(0, 1)
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
	print("HitVals: ", MissVals)

	Miss = MissAverage > _missThreshold

func RollCrit(_rng : DeterministicRNG, _critThreshold : float):
	var val = _rng.NextFloat(0, 1)
	Crit = val < _critThreshold

func RollIgnite(_rng : DeterministicRNG):
	var val = _rng.NextFloat(0, 1)
	Ignite = val < TileTargetData.IgniteChance


func PreviewResult(_map : Map):
	PreCalculate()

	if SourceHealthDelta != 0 && Source != null:
		# Then the source will have their hp modified - so add that to their preview
		if SourceHealthDelta < 0:
			Source.damage_indicator.normalDamage += SourceHealthDelta
		elif SourceHealthDelta > 0:
			Source.damage_indicator.healAmount += SourceHealthDelta
		Source.damage_indicator.SetHealthLevels(Source.currentHealth, Source.maxHealth)

	if Target != null:
		var indicator = Target.damage_indicator

		if HealthDelta <= 0: # The = to here is to trigger the indicator for if your attack deals 0 damage
			indicator.normalDamage += HealthDelta
		elif HealthDelta > 0:
			indicator.healAmount += HealthDelta

		indicator.SetHealthLevels(Target.currentHealth, Target.maxHealth)
		indicator.critChance = CritRate

		Target.ShowAffinityRelation(Source.Template.Affinity)
	elif TileTargetData.Tile.Health != -1:
		# Target may be a Tile we're hitting
		var heal = 0
		var damage = 0
		if HealthDelta < 0:
			damage += HealthDelta
		elif HealthDelta > 0:
			heal += HealthDelta

		TileTargetData.Tile.PreviewDamage(damage, 0, heal)

	PreviewRetaliation(_map)

func ToString():
	var sourceString = "NULL"
	if Source != null:
		sourceString = Source.Template.DebugName

	var targetString = "NULL"
	if Target != null:
		targetString = Target.Template.DebugName
	return "{0} attacked {1} with {2} dealing {3} damage. Crit: {4}. Tile {5}".format([sourceString, targetString, AbilityData.internalName, str(HealthDelta), str(Crit), str(TileTargetData.Tile.Position)])

func PreviewRetaliation(_map : Map):
	# Wait I love this
	if RetaliationResult != null:
		RetaliationResult.PreviewResult(_map)

func CancelPreview():
	if TileTargetData != null:
		TileTargetData.Tile.CancelPreview()
	pass
