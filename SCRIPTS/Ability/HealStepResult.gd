extends DamageStepResult
class_name HealStepResult


func PreCalculate():
	# Healing items can't miss
	HealthDelta = GameManager.GameSettings.HealCalculation(AbilityData.HealData, Source, TileTargetData.AOEMultiplier)
	ExpGain = GameManager.GameSettings.ExpFromHealCalculation(HealthDelta, Source, Target)

func PreviewResult(_map : Map):
	PreCalculate()

	if Target != null:
		var indicator = Target.damage_indicator
		if HealthDelta > 0:
			indicator.healAmount += HealthDelta

	elif TileTargetData.Tile.Health != -1:
		# Target may be a Tile we're hitting
		var heal = 0
		if HealthDelta > 0:
			heal += HealthDelta

		TileTargetData.Tile.PreviewDamage(0, 0, heal)

func CancelPreview():
	# Clear out any damage indicators on terrain
	if TileTargetData != null:
		TileTargetData.Tile.CancelPreview()
	pass
