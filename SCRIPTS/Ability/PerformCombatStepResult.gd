extends DamageStepResult
class_name PerformCombatStepResult

var SourceTile : Tile
var CritRate : float		# The % the roll needs to be under in order for it to be a crit

var MissVals : Vector2		# The log of which numbers we rolled
var MissAverage : float		# The average of missVals

var AffectedTiles : Array[TileTargetedData]
var RetaliationResult : DamageStepResult

func PreCalculate():
	if AbilityData.IsDamage():
		# No crits in cutscenes it fucks with everything
		if CutsceneManager.active_cutscene != null:
			CritRate = 0
		else:
			CritRate = GameManager.GameSettings.CritRateCalculation(Source, AbilityData, Target, TileTargetData)

		HealthDelta = -GameManager.GameSettings.DamageCalculation(Source, Target, AbilityData.UsableDamageData, TileTargetData, AbilityData)
		Ignite = TileTargetData.Ignite

		# calculate if the source unit heals or is hurt by this attack
		CalculateSourceHealthDelta(AbilityData.UsableDamageData)

		Kill = false
		UpdateWillKill()

	elif AbilityData.IsHeal():
		# Healing items can't miss
		HealthDelta = GameManager.GameSettings.HealCalculation(AbilityData.HealData, Source, TileTargetData.AOEMultiplier)


func RollChance(_rng : DeterministicRNG):
	RollCrit(_rng, CritRate)

	if Crit:
		HealthDelta = HealthDelta * GameManager.GameSettings.CritMultiplier
		Juice.CreateCritPopup(TileTargetData.Tile)

	UpdateWillKill()
	CalculateExpGain()

func UpdateWillKill():
	if Target != null:
		if Miss:
			Kill = false
		else:
			Kill = (Target.currentHealth + HealthDelta <= 0)

func CalculateSourceHealthDelta(_damageData : DamageData):
	if _damageData.DamageAffectsUsersHealth && Target != null:
		SourceHealthDelta = min(floori(HealthDelta * _damageData.DamageToHealthRatio), Target.currentHealth)

func CalculateExpGain():
	if Miss:
		ExpGain = 1
		return

	var isAOE = false
	if AbilityData != null && AbilityData.TargetingData != null:
		var targetsHit = 0
		for tileData in AffectedTiles:
			if tileData.Tile.Occupant != null && AbilityData.TargetingData.OnCorrectTeam(Source, tileData.Tile.Occupant):
				targetsHit += 1

		isAOE = targetsHit > 1

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

func RollCrit(_rng : DeterministicRNG, _critThreshold : float):
	var val = _rng.NextFloat(0, 1)
	Crit = val < _critThreshold

func PreviewResult(_map : Map):
	PreCalculate()

	if SourceHealthDelta != 0 && Source != null:
		# Then the source will have their hp modified - so add that to their preview
		if SourceHealthDelta < 0:
			Source.damage_indicator.normalDamage += SourceHealthDelta
		elif SourceHealthDelta > 0:
			Source.damage_indicator.healAmount += SourceHealthDelta

	if Target != null:
		var indicator = Target.damage_indicator

		if HealthDelta <= 0: # The = to here is to trigger the indicator for if your attack deals 0 damage
			indicator.normalDamage += HealthDelta
		elif HealthDelta > 0:
			indicator.healAmount += HealthDelta

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
