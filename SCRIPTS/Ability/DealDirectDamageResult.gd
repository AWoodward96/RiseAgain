extends DamageStepResult
class_name DealDirectDamageResult


func PreviewResult(_map : Map):
	if SourceHealthDelta != 0 && Source != null:
		# Then the source will have their hp modified - so add that to their preview
		if SourceHealthDelta < 0:
			Source.damageIndicator.normalDamage += SourceHealthDelta
		elif SourceHealthDelta > 0:
			Source.damageIndicator.healAmount += SourceHealthDelta

		if SourceHealthDelta != 0:
			Source.damageIndicator.trueHit = true

	if Target != null:
		var indicator = Target.damageIndicator

		if HealthDelta <= 0: # The = to here is to trigger the indicator for if your attack deals 0 damage
			indicator.normalDamage += HealthDelta
		elif HealthDelta > 0:
			indicator.healAmount += HealthDelta

		if HealthDelta != 0:
			Target.damageIndicator.trueHit = true

	elif TileTargetData.Tile.Health != -1:
		# Target may be a Tile we're hitting
		var heal = 0
		var damage = 0
		if HealthDelta < 0:
			damage += HealthDelta
		elif HealthDelta > 0:
			heal += HealthDelta

		TileTargetData.Tile.PreviewDamage(damage, 0, heal)

func CalculateEXPGain():
	if HealthDelta < 0: # Meaning it will deal damage
		var HealthDeltaABS = abs(HealthDelta)
		if Target != null:
			if Target.currentHealth <= HealthDeltaABS:
				ExpGain = GameManager.GameSettings.ExpFromKillCalculation(HealthDeltaABS, Source, Target, false)
			else:
				ExpGain = GameManager.GameSettings.ExpFromDamageCalculation(HealthDeltaABS, Source, Target, false)
		else:
			ExpGain = 1
	pass
